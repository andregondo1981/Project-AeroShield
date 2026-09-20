variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "my_ip" {
  type        = string
  description = "Your IP address for Bastion SSH access (CIDR block)"
  default     = "0.0.0.0/0" # Update this to your specific IP for security
}