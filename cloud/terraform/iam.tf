resource "ibm_iam_access_group" "accgrp" {
  name = "${var.prefix}-ag"
  tags = var.tags
}

resource "ibm_iam_access_group_policy" "policy-cos" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles           = ["Viewer"]

  resources {
    service           = "cloud-object-storage"
    resource_group_id = ibm_resource_group.resource_group.id
  }
}


# Create a policy to all Kubernetes instances within the Resource Group
resource "ibm_iam_access_group_policy" "policy-k8s" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles           = ["Manager", "Writer", "Editor", "Operator", "Viewer"]

  resources {
    service           = "containers-kubernetes"
    resource_group_id = ibm_resource_group.resource_group.id
  }
}

# DevOps - Continuous Delivery
resource "ibm_iam_access_group_policy" "iam-continuous-delivery" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles           = ["Manager", "Writer", "Editor", "Operator", "Viewer"]

  resources {
    service           = "continuous-delivery"
    resource_group_id = ibm_resource_group.resource_group.id
  }
}

# DevOps - Toolchain
resource "ibm_iam_access_group_policy" "iam-toolchain" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles           = ["Editor", "Operator", "Viewer"]

  resources {
    service           = "toolchain"
    resource_group_id = ibm_resource_group.resource_group.id
  }
}

resource "ibm_iam_access_group_policy" "iam-logdna" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles           = ["Manager", "Viewer", "Standard Member"]

  resources {
    service           = "logdna"
    resource_group_id = ibm_resource_group.resource_group.id
  }
}

resource "ibm_iam_access_group_policy" "iam-sysdig" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles           = ["Writer", "Editor"]

  resources {
    service           = "sysdig-monitor"
    resource_group_id = ibm_resource_group.resource_group.id
  }
}

# SERVICE ID
# Equivalent to CLI commands in this tutorial
# https://cloud.ibm.com/docs/secrets-manager?topic=secrets-manager-tutorial-kubernetes-secrets#tutorial-external-kubernetes-secrets-access
resource "ibm_iam_service_id" "kubernetes-secrets" {
  name        = "kubernetes-secrets"
  description = "A service ID for testing Secrets Manager and Kubernetes Service."
  tags        = var.tags
}

resource "ibm_iam_service_policy" "secrets-policy" {
  iam_service_id = ibm_iam_service_id.kubernetes-secrets.id
  roles          = ["SecretsReader"]

  resources {
    service            = "secrets-manager"
    resource_instance_id = ibm_iam_service_id.kubernetes-secrets.id
  }
}

resource "ibm_iam_service_api_key" "secrets_apikey" {
  name           = "secrets_apikey"
  description    = "An API key for testing Secrets Manager."
  iam_service_id = ibm_iam_service_id.kubernetes-secrets.iam_id
}


# AUTHORIZATIONS

# Authorization policy between Mongo and Key Protect
# Require to encrypt Mongo DB with Key in Key Protect
# https://github.com/IBM-Cloud/vpc-scaling-dedicated-host/blob/master/modules/create_services/main.tf
resource "ibm_iam_authorization_policy" "mongo-kms" {
  source_service_name         = "databases-for-mongodb"
  target_service_name         = "kms"
  target_resource_instance_id = ibm_resource_instance.key-protect.guid
  roles                       = ["Reader", "Authorization Delegator"]
}

# Authorization policy between IKS and Secrets Manager
resource "ibm_iam_authorization_policy" "iks-sm" {
  source_service_name         = "containers-kubernetes"
  source_resource_instance_id = module.vpc_kubernetes_cluster.kubernetes_vpc_cluster_id
  target_service_name         = "secrets-manager"
  target_resource_instance_id = ibm_resource_instance.secrets-manager.guid
  roles                       = ["Manager"]
}

# Authorization policy between OpenShift and Secrets Manager
resource "ibm_iam_authorization_policy" "roks-sm" {
  source_service_name         = "containers-kubernetes"
  source_resource_instance_id = module.vpc_openshift_cluster.vpc_openshift_cluster_id
  target_service_name         = "secrets-manager"
  target_resource_instance_id = ibm_resource_instance.secrets-manager.guid
  roles                       = ["Manager"]
}
