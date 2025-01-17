
# OpenShift Variables
##############################################################################

variable "openshift_cluster_name" {
  description = "Name of the cluster"
  type        = string
  default     = "roks"
}

variable "openshift_version" {
  description = "The OpenShift version that you want to set up in your cluster."
  type        = string
  default     = "4.12.7_openshift"
}

variable "openshift_machine_flavor" {
  description = " The default flavor of the OpenShift worker node."
  type        = string
  default     = "bx2.4x16"
}

variable "openshift_worker_nodes_per_zone" {
  description = "The number of worker nodes per zone in the default worker pool."
  type        = number
  default     = 1
}

variable "worker_labels" {
  description = "Labels on all the workers in the default worker pool."
  type        = map(any)
  default     = null
}

variable "openshift_wait_till" {
  description = "specify the stage when Terraform to mark the cluster creation as completed."
  type        = string
  default     = "OneWorkerNodeReady"

  validation {
    error_message = "`openshift_wait_till` value must be one of `MasterNodeReady`, `OneWorkerNodeReady`, or `IngressReady`."
    condition = contains([
      "MasterNodeReady",
      "OneWorkerNodeReady",
      "IngressReady"
    ], var.openshift_wait_till)
  }
}

variable "disable_public_service_endpoint" {
  description = "Boolean value true if Public service endpoint to be disabled."
  type        = bool
  default     = false
}

variable "openshift_force_delete_storage" {
  description = "force the removal of persistent storage associated with the cluster during cluster deletion."
  type        = bool
  default     = true
}

variable "kms_config" {
  type    = list(map(string))
  default = []
}

variable "entitlement" {
  description = "Enable openshift entitlement during cluster creation ."
  type        = string
  default     = "cloud_pak"
}

variable "openshift_update_all_workers" {
  description = "OpenShift version of the worker nodes is updated."
  type        = bool
  default     = true
}

variable "is_openshift_cluster" {
  type    = bool
  default = true
}

variable "worker_pools" {
  description = "List of maps describing worker pools"

  type = list(object({
    pool_name        = string
    machine_type     = string
    workers_per_zone = number
  }))

  default = [
    {
      pool_name        = "dev"
      machine_type     = "bx2.4x16"
      workers_per_zone = 1
      # },
      # {
      #     pool_name        = "odf"
      #     machine_type     = "bx2.16x64"
      #     workers_per_zone = 1
    }
  ]

  validation {
    error_message = "Worker pool names must match the regex `^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$`."
    condition = length([
      for pool in var.worker_pools :
      false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", pool.pool_name))
    ]) == 0
  }

  validation {
    error_message = "Worker pools cannot have duplicate names."
    condition = length(distinct([
      for pool in var.worker_pools :
      pool.pool_name
    ])) == length(var.worker_pools)
  }
}

## Resources
##############################################################################
resource "ibm_container_vpc_cluster" "roks_cluster" {
  name                            = format("%s-%s", var.prefix, var.openshift_cluster_name)
  vpc_id                          = ibm_is_vpc.vpc.id
  resource_group_id               = local.resource_group_id
  kube_version                    = var.openshift_version
  cos_instance_crn                = var.is_openshift_cluster ? ibm_resource_instance.cos_openshift_registry[0].id : null
  entitlement                     = var.entitlement
  tags                            = var.tags
  disable_public_service_endpoint = var.disable_public_service_endpoint
  update_all_workers              = var.openshift_update_all_workers

  flavor       = var.openshift_machine_flavor
  worker_count = var.openshift_worker_nodes_per_zone
  wait_till    = var.openshift_wait_till

  dynamic "zones" {
    for_each = { for subnet in ibm_is_subnet.subnet : subnet.id => subnet }
    content {
      name      = zones.value.zone
      subnet_id = zones.value.id
    }
  }

  kms_config {
    instance_id      = ibm_resource_instance.key-protect.guid # GUID of Key Protect instance
    crk_id           = ibm_kms_key.key.key_id                 # ID of customer root key
    private_endpoint = true
  }
}

# Additional Worker Pool
##############################################################################
# resource "ibm_container_vpc_worker_pool" "roks_worker_pools" {
#   for_each          = { for pool in var.worker_pools : pool.pool_name => pool }
#   cluster           = ibm_container_vpc_cluster.roks_cluster.id
#   resource_group_id = local.resource_group_id
#   worker_pool_name  = each.key
#   flavor            = lookup(each.value, "machine_type", null)
#   vpc_id            = ibm_is_vpc.vpc.id
#   worker_count      = each.value.workers_per_zone

#   dynamic "zones" {
#     for_each = { for subnet in ibm_is_subnet.subnet : subnet.id => subnet }
#     content {
#       name      = zones.value.zone
#       subnet_id = zones.value.id
#     }
#   }
# }

# Retrieve VPC LB attached to the cluster
##############################################################################
# data "ibm_container_vpc_cluster" "roks_cluster" {
#   name = ibm_container_vpc_cluster.roks_cluster.id
# }

# data "ibm_container_vpc_alb" "roks_cluster_alb" {
#   alb_id = data.ibm_container_vpc_cluster.roks_cluster.albs[0].id
# }

# output "roks_cluster_alb" {
#   value = data.ibm_container_vpc_alb.roks_cluster_alb
# }


# Object Storage to backup the OpenShift Internal Registry
##############################################################################
resource "ibm_resource_instance" "cos_openshift_registry" {
  count             = var.is_openshift_cluster ? 1 : 0
  name              = join("-", [var.prefix, "cos-registry"])
  resource_group_id = local.resource_group_id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  tags              = var.tags
}


##############################################################################
# Connect Log Analysis Service to cluster
# 
# Integrating Logging requires the master node to be 'Ready'
# If not, you will face a timeout error after 45mins
##############################################################################
resource "ibm_ob_logging" "openshift_log_connect" {
  depends_on       = [module.logging_instance.key_guid]
  cluster          = ibm_container_vpc_cluster.roks_cluster.id
  instance_id      = module.logging_instance.guid
  private_endpoint = var.log_private_endpoint
}

##############################################################################
# Connect Monitoring Service to cluster
# 
# Integrating Monitoring requires the master node to be 'Ready'
# If not, you will face a timeout error after 45mins
##############################################################################
resource "ibm_ob_monitoring" "openshift_connect_monitoring" {
  depends_on       = [module.monitoring_instance.key_guid]
  cluster          = ibm_container_vpc_cluster.roks_cluster.id
  instance_id      = module.monitoring_instance.guid
  private_endpoint = var.sysdig_private_endpoint
}


##############################################################################
# Connect Secrets Manager to cluster
##############################################################################
# resource "null_resource" "openshift_connect_secrets" {
#   To be added when available
# }