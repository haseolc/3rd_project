variable "shared_vpc_id" {
  description = "Persistent shared VPC used by Kubernetes nodes"
  type        = string
  default     = "vpc-09b2f47da0466ba08"
}

variable "public_subnet_id" {
  description = "Persistent public subnet in ap-northeast-2a"
  type        = string
  default     = "subnet-0e79d7a2dee8ec9f3"
}

variable "k8s_security_group_id" {
  description = "Persistent shared Kubernetes security group"
  type        = string
  default     = "sg-02cfb946649a50d91"
}
