# Build reference to the already-built image
resource "docker_image" "app" {
  name         = var.image
  keep_locally = true
}

# Run the container
resource "docker_container" "app" {
  name  = var.container_name
  image = docker_image.app.image_id

  restart = "unless-stopped"

  ports {
    internal = var.container_port
    external = var.host_port
    protocol = "tcp"
  }
}
