terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Uses the Docker socket mounted by Jenkins in the Terraform container
provider "docker" {
  host = "unix:///var/run/docker.sock"
}
