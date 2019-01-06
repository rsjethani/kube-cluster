#!/bin/bash

CLSTR_ROOT_DIR=$(pwd)
PROV=$CLSTR_ROOT_DIR/prov
INFRA=$CLSTR_ROOT_DIR/infra
UTILS=$CLSTR_ROOT_DIR/utils


operations=(create destroy reset powerdown powerup initialize)


perform_reset(){
    cd $PROV
    ansible-playbook -v -i inventory reset.yml
    cd -
}

perform_powerdown(){
    cd $PROV
    ansible-playbook -v -i inventory powerdown.yml
    cd -
}

perform_powerup(){
    cd $PROV
    ansible-playbook -v -i inventory powerup.yml
    cd -
}

perform_destroy() {
	set -e
	cd $INFRA
	terraform init
	terraform destroy -auto-approve -var-file infra.tfvars
	cd -

	rm -vf $PROV/inventory
	set +e
}

perform_initialize() {
	set -e
	cd $PROV
	ansible-playbook -v -i inventory initialize.yml
	mv -v $PROV/admin.conf $CLSTR_ROOT_DIR
	ansible-playbook -v -i inventory add-workers.yml
	cd -
	set +e
}

perform_create() {
	set -e
	cd $INFRA
	terraform init
	terraform plan -out theplan -var-file infra.tfvars
	terraform apply theplan
	rm theplan
	cd -

	$UTILS/generate_inventory.py $INFRA/terraform.tfstate $PROV/inventory

	cd $PROV
	set +e
	while true; do
		ansible -i inventory -m ping all
		[ "$?" -eq 0 ] && break
		echo retrying connection to nodes...
		sleep 2
	done
	cd -

	perform_initialize
}

main() {
    while getopts 'ho:' OPTION; do
	case "$OPTION" in
	    o)
		op="$OPTARG"
		valid_ops="${operations[@]}"
		if [ "$valid_ops" == "${valid_ops/$op/}" ]; then
		    echo "Invalid operation $ops. Check help" >&2
		    exit 1
		fi
		perform_$op
		;;

	    h|?)
		echo "script usage: $(basename $0) [-h] [-o $(echo ${operations[@]}|tr ' ' '|')]" >&2
		exit 1
		;;
	esac
    done
    shift "$(($OPTIND -1))"
}

main "$@"
