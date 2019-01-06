
resource "libvirt_cloudinit_disk" "cloudinit" {
    name = "cloudinit.iso"
    pool = "default"
    user_data = <<EOF
    #cloud-config
    ssh_authorized_keys:
      - "${file(var.public_key_path)}"
    EOF
}

resource "libvirt_domain" "master" {
    count = "${var.master_count}"
    name   = "${var.cluster_name}-master-${count.index + 1}"
    memory = "2048"
    vcpu   = 2

    network_interface {
	network_name = "default"
	wait_for_lease = true
    }

    cloudinit = "${libvirt_cloudinit_disk.cloudinit.id}"

    # IMPORTANT: this is a known bug on cloud images, since they expect a console
    # we need to pass it
    # https://bugs.launchpad.net/cloud-images/+bug/1573095
#    console {
#	type        = "pty"
#	target_port = "0"
#	target_type = "serial"
#    }

#    console {
#	type        = "pty"
#	target_type = "virtio"
#	target_port = "1"
#    }

    disk {
	volume_id = "${element(libvirt_volume.master.*.id,count.index)}"
    }

    graphics {
	type        = "vnc"
	listen_type = "address"
	autoport    = true
    }
}

resource "libvirt_domain" "worker" {
    count = "${var.worker_count}"
    name   = "${var.cluster_name}-worker-${count.index + 1}"
    memory = "2048"
    vcpu   = 2

    network_interface {
	network_name = "default"
	wait_for_lease = true
    }

    cloudinit = "${libvirt_cloudinit_disk.cloudinit.id}"

    # IMPORTANT: this is a known bug on cloud images, since they expect a console
    # we need to pass it
    # https://bugs.launchpad.net/cloud-images/+bug/1573095
#    console {
#	type        = "pty"
#	target_port = "0"
#	target_type = "serial"
#    }

#    console {
#	type        = "pty"
#	target_type = "virtio"
#	target_port = "1"
#    }

    disk {
	volume_id = "${element(libvirt_volume.worker.*.id,count.index)}"
    }

    graphics {
	type        = "vnc"
	listen_type = "address"
	autoport    = true
    }
}

