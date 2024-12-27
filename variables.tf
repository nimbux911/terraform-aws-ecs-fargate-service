variable "environment" {
  type        = string
  default     = ""
  description = "Environment, e.g. 'prd', 'stg', 'dev'"
}

variable "cluster_id" {
  type        = string
  description = "Cluster id where you need to create services"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name where you need to create services"
}

variable "fargate_services" {
  description = "Define fargate service information"
  default     = {}
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security groups ids we need to add this cluster service"
  default     = []
}

variable "subnet_ids" {
  type        = list(string)
  description = "The subnets associated with the task or service."
}

variable "tags" {
  description = "Tags for fargate"
  type        = map(string)
}

variable "enable_autoscaling" {
  type        = bool
  description = "Enable or disable autoscaling config"
}

variable "max_cpu_threshold" {
  description = "Threshold for max CPU usage"
  default     = "75"
  type        = string
}

variable "min_cpu_threshold" {
  description = "Threshold for min CPU usage"
  default     = "10"
  type        = string
}

variable "scale_target_max_capacity" {
  description = "The max capacity of the scalable target"
  default     = 10
  type        = number
}

variable "scale_target_min_capacity" {
  description = "The min capacity of the scalable target"
  default     = 3
  type        = number
}


variable "assign_public_ip" {
  type        = bool
  description = "ssign a public IP address to the ENI (Fargate launch type only)"
  default     = true
}

variable "force_new_deployment" {
  type        = bool
  description = "Enable to force a new task deployment of the service. "
  default     = true
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "Minimum healthy percent of containers at deploy time."
  default     = 100
}

variable "deployment_maximum_percent" {
  type        = number
  description = "Maximum percent of containers at deploy time."
  default     = 200
}

variable "ignored_lifecycle_changes" {
  type        = list(string)
  description = "List of resource attributes to ignore changes for lifecycle management."
  default     = []
}