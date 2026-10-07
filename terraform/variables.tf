variable "admin_username" {
  description = "Local Admin Username for DC01"
  type        = string
  default     = "sysadmin"
}

variable "admin_password" {
  description = "Local Admin Password for DC01"
  type        = string
  default     = "HybridIdentityLab2026!" 
}

variable "location" {
  type    = string
  default = "East US"
}