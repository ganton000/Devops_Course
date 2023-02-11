terraform {
  cloud {
    organization = "anton-terransible"

    workspaces {
      name = "terransible"
    }
  }
}