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
  description = "Host port exposed on the Jenkins host"
  type        = number
  default     = 8082
}

variable "container_port" {
  description = "Port the app listens on inside the container"
  type        = number
  default     = 8080
}
