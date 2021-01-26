terraform {
  backend "local" {
    path = "/root/tfstate/script-openstack-do.tfstate"
  }
}

module "digitalocean" {
    source              = "./droplet"
    servers             = [
        {
            name = "controller",
            type = "s-4vcpu-8gb"
        }
    ]
    public_key_name     = var.public_key_name
    digital_ocean_key   = var.digital_ocean_key
}
