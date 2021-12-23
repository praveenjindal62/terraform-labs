//Hub - Variables
variable "hub_location" {
  type = string
  default = "eastus"
}
variable "hub_prefix" {
  type = string
  default = "HUB"
}

// OnPrem - Variables
variable "onprem_location" {
  type = string
  default = "centralus"
}
variable "onprem_prefix" {
  type = string
  default = "ONPREM"
}

//Spoke01 - Variables
variable "spoke01_location" {
  type = string
  default = "westus"
}
variable "spoke01_prefix" {
  type = string
  default = "SPOKE01"
}

//
variable "pre_shared_key"{
    type = string
}