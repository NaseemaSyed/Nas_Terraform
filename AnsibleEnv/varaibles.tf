variable "address_space" {
  default = "10.0.0.0/16"
}
variable "location" {
  default = "Australia East "

}

variable "subscription_id" {
  default   = "0c899537-ebe1-48f0-941c-b25bfce1103c"
  sensitive = true
}

variable "admin_username" {
  default   = "naseema"
  type      = string
  sensitive = true
}

variable "password" {
  default     = "Samjam11"
  type        = string
  sensitive   = true
}