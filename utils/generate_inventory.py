#!/usr/bin/env python3


import json
import argparse


import ansinv


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("tfstate_file", help="Path to Terraform's tfstate file")
    parser.add_argument("inventory_file", help="Path of the new inventory file")
    args = parser.parse_args()

    # Initialize empty inventory
    inventory = ansinv.AnsibleInventory()

    # load terraform state file
    with open(args.tfstate_file) as file:
        state = json.load(file)

    grp_master = ansinv.AnsibleGroup("master")
    grp_worker = ansinv.AnsibleGroup("worker")

    # Add hosts to groups
    for resource, res_info in state["modules"][0]["resources"].items():
        if res_info["type"] == "libvirt_domain":
            name = res_info["primary"]["attributes"]['name']
            host_ip = res_info["primary"]["attributes"]['network_interface.0.addresses.0']

            # "libvirt_domain.worker.0" -> "libvirt_domain", "worker", ("0",)
            _, group, *_ = resource.split(".")
            if group == grp_master.name:
                grp_master.add_hosts(ansinv.AnsibleHost(host_ip, host_name=name))
            elif group == grp_worker.name:
                grp_worker.add_hosts(ansinv.AnsibleHost(host_ip, host_name=name))

    # Add groups to inventory
    grp_cluster = ansinv.AnsibleGroup("k8s-cluster")
    grp_cluster.add_children(grp_master, grp_worker)

    inventory.add_groups(grp_worker,grp_master,grp_cluster)

    # Add groupvars if any to groups
    inventory.group("all").groupvars["ansible_user"] = "centos"
    inventory.group("all").groupvars["ansible_ssh_private_key_file"] = "../cloud.pem"

    # Write inventory data to a file in ini format.
    with open(args.inventory_file, "w") as file:
        file.write(str(inventory))


if __name__ == "__main__":
    main()
