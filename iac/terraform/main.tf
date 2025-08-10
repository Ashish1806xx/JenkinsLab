resource "docker_image" "app" {
  name         = var.image
  keep_locally = true
}

resource "docker_container" "app" {
  name  = "jenkinslab-app"
  image = docker_image.app.image_id

  ports {
    internal = 8080
    external = 8082
  }
}
