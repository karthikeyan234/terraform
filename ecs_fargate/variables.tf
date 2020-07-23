variable "region" {
  default     = "ap-south-1"
  description = "AWS Region"
}

variable "remote_state_bucket" {}
variable "remote_state_key" {}

variable "ecs_cluster_name" {}

variable "internet_cidr_blocks" {}


#application variables for task
variable "ecs_service_name" {
}

variable "docker_image_url" {
}

variable "memory" {
}

variable "docker_container_port" {
}

variable "spring_profile" {
}

variable "desired_task_number" {
}
