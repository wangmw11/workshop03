
data digitalocean_ssh_key markey23 {
  name = "markey23"
}

data digitalocean_image  code_server_image{
  name = "codeserver_ver2"
}

resource local_file code_server_service {
    filename = "code-server.service"
    content = templatefile("code-server.service.tpl", {
        code_server_password = var.code_server_password
        //code_server_ip = digitalocean_droplet.code-server.ipv4_address
        //private_key = var.private_key
    })
    file_permission = "0644"
}

resource local_file code_server_conf {
    filename = "code-server.conf"
    content = templatefile("code-server.conf.tpl", {
        code_server_ip =  digitalocean_droplet.code-server.ipv4_address
        //private_key = var.private_key
    })
    file_permission = "0644"
}

resource digitalocean_droplet code-server {
  name = "code-server"
  //image = var.droplet_image
  image = data.digitalocean_image.code_server_image.id
  region = var.droplet_region
  size = var.droplet_size
  ssh_keys = [ data.digitalocean_ssh_key.markey23.fingerprint ]
   //ssh_keys = [ digitalocean_ssh_key.markey23.id ]


  connection {
    type = "ssh"
    user = "root"
    private_key = file(var.private_key)
    host = self.ipv4_address
  }

   // Copy config file over
    provisioner file {
        source = "./code-server.service"
        destination = "/lib/systemd/system/code-server.service"
    }

     // Copy config file over
    provisioner file {
        source = "./code-server.conf"
        destination = "/etc/nginx/sites-available/code-server.conf"
    }

    // Restart nginx cause we have updated the configuration
    provisioner remote-exec {
        inline = [
            "systemctl daemon-reload",
            "systemctl restart nginx",
            "systemctl restart code-server"
        ]
    }
}


output nginx_ip {
    value = digitalocean_droplet.code-server.ipv4_address
}

