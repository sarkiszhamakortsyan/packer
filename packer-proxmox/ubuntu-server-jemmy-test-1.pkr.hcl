# The code bellow will install Ubuntu Server Jemmy with Packer

# Variable for api url
variable "proxmox_api_url" {
    type = string
}

# Variable for api token id
variable "proxmox_api_token_id" {
    type = string
}

# Variable for api token secret
variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

# Resource for VM template
source "proxmox" "ubuntu-server-jemmy" {
    # Connection settings for Proxmox
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # Escape TLS check
    insecure_skip_tls_verify = true

    # VM settings
    node = "pve"
    vm_id = "503"
    vm_name = "ubuntu-server-jemmy-test-1"
    template_description = "Ubuntu Server Jemmy Test Image with packages installed"

    # VM OS Settings
    # The line below will install Ubuntu Server 22.04 from ISO file
    #iso_file = "local:iso/ubuntu-22.04.1-live-server-amd64.iso"

    # The lines below will install Ubuntu Server from URL over internet
    iso_url = "https://releases.ubuntu.com/focal/ubuntu-20.04.5-live-server-amd64.iso"
    iso_checksum = "5035be37a7e9abbdc09f0d257f3e33416c1a0fb322ba860d42d74aa75c3468d4"
    iso_storage_pool = "local"
    unmount_iso = true

    # Enable VM QEMU agent
    qemu_agent = true
    
    # VM HDD Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "40G"
        format = "raw"
        storage_pool = "local-lvm"
        storage_pool_type = "lvm"
        type = "virtio"
    }
    # VM CPU Settings
    cores = "1"

    # VM RAM Settings
    memory = "2048"

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    }

    # VM Cloud-init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    # Packer startup commands. The commands below are the ones used during the installation
    # In latest Ubuntu installation there is an option to pick up HTTP server from where
    # the Ubuntu will be installed. In the example below will be taken automatically.
    # If you want, you can use your own HTTP server by uncommenting the lines under.
    boot_command = [
        "<esc><wait><esc><wait>",
        "<f6><wait><esc><wait>",
        "<bs><bs><bs><bs><bs>",
        "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
        "--- <enter>"
    ]
    boot = "c"
    boot_wait = "10s"

    # Packer Autoinstallation Settings
    http_directory = "http"
    # (Optional) Bind IP Address and Port
    # http_bind_address = "0.0.0.0"
    # http_port_min = 8802
    # http_port_max = 8802

    ssh_username = "sako"
    # You can use password authentication
    ssh_password = "sako"

    # You can add and use SSH private key file in the line below
    # ssh_private_key_file = "~/.ssh/id_rsa"

    # Increase the time in case the installation takes more time
    ssh_timeout = "20m"
}

build {

    # VM template name
    name = "ubuntu-server-jemmy"
    sources = ["source.proxmox.ubuntu-server-jemmy"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox. Copy from srs/dest
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }

    # Add additional provisioning scripts here
    # ...
}