##############################################################################
## Global Variables
##############################################################################
#ibmcloud_api_key = ""      # Set the variable export TF_VAR_ibmcloud_api_key=
# Account ID is only used for CBR Rule and Zone
account_id            = "0b5a00334eaf9eb9339d2ab48f7326b4"
prefix                = "ezy1"
region                = "eu-de" # eu-de for Frankfurt MZR
resource_group_name   = "test-ezy1"
tags                  = ["tf", "ezy1"]
# activity_tracker_name = "platform-activities"


##############################################################################
## VPC
##############################################################################
vpc_classic_access            = false
vpc_address_prefix_management = "manual"
vpc_enable_public_gateway     = true


##############################################################################
## Cluster IKS
##############################################################################
iks_cluster_name          = "iks"
iks_version               = "1.26.3"
iks_worker_nodes_per_zone = 1
iks_machine_flavor        = "bx2.4x16"
# iks_machine_flavor    = "bx2.16x64" # ODF or Portworx flavor

# Possible values: MasterNodeReady, OneWorkerNodeReady, or IngressReady
iks_wait_till          = "IngressReady"
iks_update_all_workers = true


##############################################################################
## Cluster ROKS
##############################################################################
openshift_cluster_name   = "roks"
openshift_version        = "4.12.7_openshift"
openshift_machine_flavor = "bx2.4x16"
# openshift_machine_flavor = "bx2.16x64" # ODF Flavors

# Available values: MasterNodeReady, OneWorkerNodeReady, or IngressReady
openshift_wait_till          = "OneWorkerNodeReady"
openshift_update_all_workers = false


##############################################################################
## COS
##############################################################################
cos_plan   = "standard"
cos_region = "global"


##############################################################################
## Observability: Log Analysis (Mezmo) & Monitoring (Sysdig)
##############################################################################
# Available Plans: lite, 7-day, 14-day, 30-day
log_plan                 = "7-day"
log_enable_platform_logs = false

sysdig_plan                    = "graduated-tier"
sysdig_enable_platform_metrics = false


##############################################################################
## ICD Mongo
##############################################################################
# Available Plans: standard, enterprise
icd_mongo_plan = "standard"
# expected length in the range (10 - 32) - must not contain special characters
icd_mongo_adminpassword     = "Passw0rd01"
icd_mongo_db_version        = "4.4"
icd_mongo_service_endpoints = "public"

# Minimum parameter for Enterprise Edition
# icd_mongo_ram_allocation = 14336
# icd_mongo_disk_allocation = 20480
# icd_mongo_core_allocation = 6

# Minimum parameter for Standard Edition
icd_mongo_ram_allocation  = 1024
icd_mongo_disk_allocation = 20480
icd_mongo_core_allocation = 0

icd_mongo_users = [{
  name     = "user123"
  password = "password12"
}]



##############################################################################
## ICD Postgres
##############################################################################
# # Available Plans: standard, enterprise
# icd_postgres_plan = "standard"
# # expected length in the range (10 - 32) - must not contain special characters
# icd_postgres_adminpassword     = "Passw0rd01"
# icd_postgres_db_version        = "12"
# icd_postgres_service_endpoints = "public"

# # Minimum parameter for Standard Edition
# icd_postgres_ram_allocation  = 1024
# icd_postgres_disk_allocation = 20480
# icd_postgres_core_allocation = 0

# icd_postgres_users = [{
#   name     = "user123"
#   password = "password12"
# }]
