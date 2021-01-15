terraform {
  backend "local" {
    path = "/root/tfstate/script-openstack-servers.tfstate"
  }
}

module "digitalocean" {
    source              = "./droplet"
    servers             = [
        {
            name = "script-openstack-test",
            type = "s-4vcpu-8gb"
        }
    ]
    digital_ocean_key   = var.digital_ocean_key
}
