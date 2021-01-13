terraform {
  backend "local" {
    path = "/root/tfstate/script-openstack-servers.tfstate"
  }
}

module "digitalocean" {
    source              = "./droplet"
    servers             = [
        # {
        #     name = "server-test",
        #     type = "s-1vcpu-1gb"
        # }
    ]
    digital_ocean_key   = var.digital_ocean_key
}
