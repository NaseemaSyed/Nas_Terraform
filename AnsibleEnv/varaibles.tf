variable "prefix" {
  default = "nas" # Project prefix, or client id for resource identification
}

variable "address_space" {
  default = "10.0.0.0/16"
}
variable "location" {
  default = "Australia East "

}

variable "subscription_id" {
  default   = 
  sensitive = true
}

variable "admin_username" {
  default   = "naseema"
  type      = string
  sensitive = true
}

