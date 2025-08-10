variable "image" {
  description = "Fully qualified image tag"
  type        = string
}

variable "container_name" {
  description = "Container name"
  type        = string
  default     = "jenkinslab-app"
}

variable "host_port" {
  description = "Host port to expose"
  type        = number
  default     = 8082
}

variable "container_port" {
  description = "Container internal port"
  type        = number
  default     = 8080
}
