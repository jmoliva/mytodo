##############################################################################
# Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string
}

variable "account_id" {
  description = "A unique identifier of the account"
  type        = string
  default     = ""
}

variable "prefix" {
  description = "A unique identifier need to provision resources. Must begin with a letter"
  type        = string
  default     = "ezy2"
}

variable "region" {
  description = "IBM Cloud region where all resources will be provisioned"
  default     = "eu-de"
}

variable "tags" {
  description = "List of Tags"
  type        = list(string)
  default     = ["tf", "ezy2"]
}