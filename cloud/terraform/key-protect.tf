##############################################################################
## Key Protect
##############################################################################
resource "ibm_resource_instance" "key-protect" {
  resource_group_id = ibm_resource_group.resource_group.id
  name              = format("%s-%s", var.prefix, "key-protect")
  service           = "kms"
  plan              = "tiered-pricing"
  location          = var.region
  tags              = var.tags
  service_endpoints = "private"
}

resource "ibm_kms_instance_policies" "instance_policy" {
  instance_id = ibm_resource_instance.key-protect.guid
  rotation {
      enabled = true
      interval_month = 3
    }
    dual_auth_delete {
      enabled = true
    }
    metrics {
      enabled = true
    }
    key_create_import_access {
      enable = true
    }
}

resource "ibm_kms_key" "key" {
  instance_id = ibm_resource_instance.key-protect.guid
  key_name       = "${var.prefix}-root-key"
  standard_key   = false
  force_delete   = true
}

# resource "ibm_kms_key_policies" "key_policy" {
#   instance_id = ibm_resource_instance.key-protect.guid
#   key_id = ibm_kms_key.key.key_id
#   rotation {
#        interval_month = 3
#     }
#     dual_auth_delete {
#        enabled = false
#     }
# }

## IAM
##############################################################################

resource "ibm_iam_access_group_policy" "iam-kms" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles           = ["Reader", "Viewer"]

  resources {
    service           = "kms"
    resource_group_id = ibm_resource_group.resource_group.id
  }
}
