terraform {
  required_providers {
    docker = { source = "kreuzwerker/docker", version = "~> 3.0" }
  }
}
provider "docker" {}
variable "image" { type = string }
resource "docker_image" "app" { name = var.image  keep_locally = true }
resource "docker_container" "app" {
  name  = "prod-app"
  image = docker_image.app.image_id
  ports { internal = 8080  external = 8081 }
  restart   = "always"
  read_only = true
  shm_size  = 64
  capabilities { drop = ["ALL"] }
  log_driver = "json-file"
  log_opts   = { "max-size" = "10m", "max-file" = "3" }
}
