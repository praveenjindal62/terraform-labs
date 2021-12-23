variable "rgname" {
  type = string 
}
variable "location" {
  type = string 
}
variable "name" {
  type = string 
}
variable "sku" {
  type = string
  default = "Standard_DS1_v2"
}
variable "prefix" {
  type = string
}
variable "subnet_id" {
  type = string 
}