# /24 is the only supported subnet range
cidr_ip="10.0.0.0"

nodes = {
    "master": {
        "cpus": 2,
        "memory": "2048"
    }
}

root_path = File.dirname(__FILE__)
ssh_private_key = File.join(root_path, ".ssh/id_rsa")
seed = File.join(root_path, "output-vagrant/seed.img")

Vagrant.configure("2") do |config|
    config.vm.synced_folder ".", "/vagrant", disabled: true

    config.vm.box = "ck8s/baseos"
    config.vm.provider "libvirt"

    config.ssh.username = "ubuntu"
    config.ssh.private_key_path = ssh_private_key

    config.vm.provider :libvirt do |libvirt|
        # TODO: Would be nice to run unprivileged but it's tricky.
        # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/272
        # libvirt.qemu_use_session = true
        libvirt.storage :file, :device => :cdrom, :path => seed
    end

    nodes.each do |node_name, node_cfg|
        config.vm.define node_name do |node|
            node.vm.hostname = node_name

            node.vm.provider :libvirt do |libvirt|
                libvirt.memory = node_cfg[:memory]
                libvirt.cpus = node_cfg[:cpus]
            end

            node.vm.network :private_network,
              :type => "dhcp",
              :libvirt__domain_name => "ck8s",
              :libvirt__network_address => cidr_ip
        end
    end
end
