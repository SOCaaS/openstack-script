data "digitalocean_ssh_key" "ssh_key_id" {
  name = var.public_key_name
}

data "template_file" "user_data" {
  template = file("user_data.yml")
}

resource "digitalocean_droplet" "server" {
  count             = length(var.servers)
  image             = "ubuntu-20-04-x64"
  name              = var.servers[count.index]["name"]
  region            = "sgp1"
  size              = var.servers[count.index]["type"]
  ssh_keys          = [data.digitalocean_ssh_key.ssh_key_id.id] # ssh key id
  user_data         = data.template_file.user_data.rendered
  private_networking = true
}