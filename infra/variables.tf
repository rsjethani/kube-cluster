
variable "public_key_path" {
    description = "Filesystem path to public key(to be inserted in instances)"
}

variable "master_count" {
    description = "No. of masters"
    default = 1
}

variable "worker_count" {
    description = "No. of workers"
    default = 2
}

variable "cluster_name" {
    description = "Name of the cluster"
    default = "k8s"
}

variable "k8s_base_image" {
    description = "Source image for cluster volumes"
}
