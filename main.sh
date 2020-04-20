#!/bin/bash

set -u

here="$(dirname "$(readlink -f "$0")")"

var_file="${here}/variables.json"

build_config="${here}/baseos.json"
build_log="${here}/baseos.log"

test_config="${here}/baseos-test.json"
test_log="${here}/baseos-test.log"

vagrant_box_name="ck8s/baseos"
vagrant_libvirt_volume_name="ck8s-VAGRANTSLASH-baseos_vagrant_box_image_0.img"
vagrant_output="${here}/output-vagrant"
vagrant_box_path="${vagrant_output}/baseos.box"
vagrant_cloud_init="${here}/cloud-init/vagrant"
vagrant_seed="${vagrant_output}/seed.img"
vagrant_log="${here}/vagrant.log"

usage() {
    echo "Usage: ${0} <build|test>" >&2
    exit 1
}

[ ${#} -eq 1 ] || usage

case "${1}" in
    build)
        packer build -var-file "${var_file}" "${build_config}" > "${build_log}"

        case "${?}" in
            0)
                echo -e "\e[32mBaseOS image created.\e[0m" >&2
            ;;
            *)
                echo -e "\e[31mError building baseOS image.\e[0m" >&2
                echo "Check: ${build_log}" >&2
                exit 1
            ;;
        esac
    ;;
    test)
        packer build -var-file "${var_file}" "${test_config}" > "${test_log}"

        case "${?}" in
            0)
                echo -e "\e[32mTest finished successfully.\e[0m" >&2
            ;;
            *)
                echo -e "\e[31mError while testing baseOS image.\e[0m" >&2
                echo "Check: ${baseos_test_log}" >&2
                exit 1
            ;;
        esac
    ;;
    vagrant-up)
        set -e

        echo -e "\e[32mAdding Vagrant box ${vagrant_box_name}.\e[0m" >&2
        if vagrant box list | grep ${vagrant_box_name} > /dev/null; then
            echo -e "\e[32mVagrant box already added.\e[0m" >&2
        else
            vagrant box add --provider libvirt --name ${vagrant_box_name} \
            "${vagrant_box_path}"
        fi

        echo -e "\e[32mCreating cloud-init seed.\e[0m" >&2
        sudo rm -f "${vagrant_seed}"
        cloud-localds \
            --network-config="${vagrant_cloud_init}/network-config" \
            "${vagrant_seed}" \
            "${vagrant_cloud_init}/user-data" \
            "${vagrant_cloud_init}/meta-data"

        echo -e "\e[32mBringing up Vagrant machine(s).\e[0m" >&2
        vagrant up --debug 2> "${vagrant_log}"
    ;;
    vagrant-down)
        echo -e "\e[32mTearing down Vagrant machine(s).\e[0m" >&2
        vagrant destroy --debug 2>> "${vagrant_log}"

        echo -e "\e[32mDeleting Vagrant box.\e[0m" >&2
        if vagrant box list | grep ${vagrant_box_name} > /dev/null; then
            vagrant box remove ${vagrant_box_name}

            echo -e "\e[32mDeleting libvirt volume.\e[0m" >&2
            sudo virsh vol-delete --pool default \
                ${vagrant_libvirt_volume_name}

            echo -e "\e[32mVagrant box deleted.\e[0m" >&2
        else
            echo -e "\e[32mVagrant box not found.\e[0m" >&2
        fi
    ;;
    *) usage ;;
esac
