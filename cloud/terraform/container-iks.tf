##############################################################################
# Kubernetes cluster
##############################################################################


# Kubernetes Variables
##############################################################################

variable "iks_cluster_name" {
  description = "name for the iks cluster"
  default     = "iks"
}

variable "iks_version" {
  description = "Specify the Kubernetes version, including the major.minor version. To see available versions, run `ibmcloud ks versions`."
  type        = string
  default     = "1.26.3"
}

variable "iks_machine_flavor" {
  description = "The flavor of VPC worker node to use for your cluster. Use `ibmcloud ks flavors` to find flavors for a region."
  type        = string
  default     = "bx2.4x16"
}

variable "iks_worker_nodes_per_zone" {
  description = "Number of workers to provision in each subnet"
  type        = number
  default     = 1
}

variable "iks_wait_till" {
  description = "To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, and `IngressReady`"
  type        = string
  default     = "OneWorkerNodeReady"

  validation {
    error_message = "`iks_wait_till` value must be one of `MasterNodeReady`, `OneWorkerNodeReady`, or `IngressReady`."
    condition = contains([
      "MasterNodeReady",
      "OneWorkerNodeReady",
      "IngressReady"
    ], var.iks_wait_till)
  }
}

variable "iks_force_delete_storage" {
  description = "force the removal of persistent storage associated with the cluster during cluster deletion."
  type        = bool
  default     = true
}

variable "iks_update_all_workers" {
  description = "Kubernetes version of the worker nodes is updated."
  type        = bool
  default     = true
}


## Resources
##############################################################################
resource "ibm_container_vpc_cluster" "iks_cluster" {
  name              = format("%s-%s", var.prefix, var.iks_cluster_name)
  vpc_id            = ibm_is_vpc.vpc.id
  resource_group_id = local.resource_group_id
  kube_version      = var.iks_version
  cos_instance_crn  = var.is_openshift_cluster ? ibm_resource_instance.cos_openshift_registry[0].id : null
  # entitlement                     = var.entitlement
  tags                            = var.tags
  disable_public_service_endpoint = var.disable_public_service_endpoint
  update_all_workers              = var.openshift_update_all_workers

  flavor       = var.iks_machine_flavor
  worker_count = var.iks_worker_nodes_per_zone
  wait_till    = var.iks_wait_till

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
# resource "ibm_container_vpc_worker_pool" "iks_worker_pools" {
#   for_each          = { for pool in var.worker_pools : pool.pool_name => pool }
#   cluster           = ibm_container_vpc_cluster.iks_cluster.id
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

# data "ibm_container_vpc_alb" "iks_cluster_alb" {
#   alb_id = ibm_container_vpc_cluster.iks_cluster.albs[0].id
# }

# output "iks_cluster_alb" {
#   value = data.ibm_container_vpc_alb.iks_cluster_alb
# }

##############################################################################
# Connect Log Analysis Service to cluster
# 
# Integrating Logging requires the master node to be 'Ready'
# If not, you will face a timeout error after 45mins
##############################################################################
resource "ibm_ob_logging" "iks_connect_log" {
  depends_on       = [module.logging_instance.key_guid]
  cluster          = ibm_container_vpc_cluster.iks_cluster.id
  instance_id      = module.logging_instance.guid
  private_endpoint = var.log_private_endpoint
}

##############################################################################
# Connect Monitoring Service to cluster
# 
# Integrating Monitoring requires the master node to be 'Ready'
# If not, you will face a timeout error after 45mins
##############################################################################
resource "ibm_ob_monitoring" "iks_connect_monitoring" {
  depends_on       = [module.monitoring_instance.key_guid]
  cluster          = ibm_container_vpc_cluster.iks_cluster.id
  instance_id      = module.monitoring_instance.guid
  private_endpoint = var.sysdig_private_endpoint
}

# Authorization policy between IKS and Secrets Manager
# resource "ibm_iam_authorization_policy" "iks-sm" {
#   source_service_name         = "containers-kubernetes"
#   source_resource_instance_id = ibm_container_vpc_cluster.vpc_iks_cluster.id
#   target_service_name         = "secrets-manager"
#   target_resource_instance_id = ibm_resource_instance.secrets-manager.guid
#   roles                       = ["Manager"]
# }

