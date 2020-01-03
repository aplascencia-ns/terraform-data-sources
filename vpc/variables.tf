
variable "cluster_name" {
  description = "The name to use to namespace all the resources in the cluster"
  type        = string
  default     = "main"
}

variable network_cidr {
  default = "10.0.0.0/16"
}

variable zones {
  default = ["us-east-1a", "us-east-1b"]
}
