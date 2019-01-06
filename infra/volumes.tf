locals {
    # one gigabyte value
    one_gb = 1000000000
}

resource "libvirt_volume" "master" {
    count = "${var.master_count}"
    name   = "${var.cluster_name}-master-${count.index + 1}"
    base_volume_name = "${var.k8s_base_image}"
}

resource "libvirt_volume" "worker" {
    count = "${var.worker_count}"
    name   = "${var.cluster_name}-worker-${count.index + 1}"
    base_volume_name = "${var.k8s_base_image}"
}

