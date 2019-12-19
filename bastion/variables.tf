variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "cluster_name" {
  description = "The name to use to namespace all the resources in the cluster"
  type        = string
  default     = "BASTION"
}

variable network_cidr {
  default = "10.0.0.0/16"
}

variable availability_zones {
  default = ["us-east-1a", "us-east-1b"]
}

variable "key_pair" {
  description = "Enter your pub key"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+dLoPFnEQmTfYv0SUaBTpo87pIveemtmOLMgceawZzHCSM7XDr27zaWZrjpnpaG3Gr0pInCCxzRlmC41awQtrhoW1oq6o60d0TF6ZzCDYetSV4509YogEzoiauaTe+uueYtdv126VMikyZofArbtF0m7KeRdzX4rQ7CbbPFCoqK9KSqr6XoV4BSiSfmNCE3DtKeyIKkcA3lyBohTw+XWva0bZhKiBFRoNc38hXCGktZ6Y5/h0ovONAkrBGJnrD7nrFVqlcD79eghxWkPBq9NqAwkYpwswJuFN0H7Ad3JN6w7/SSgIXH4jwmsbbsU1ZQY9G2dSLRX7bAGO0gXa3pJd aplascencia@nearsoft.com"
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
  default     = "t2.micro"
}

# variable "alb_name" {
#   description = "The name of the ALB"
#   type        = string
#   default     = "webservers-lb"
# }

# variable "instance_security_group_name" {
#   description = "The name of the security group for the EC2 Instances"
#   type        = string
#   default     = "webservers-instance"
# }

# variable "alb_security_group_name" {
#   description = "The name of the security group for the ALB"
#   type        = string
#   default     = "webservers-alb"
# }
