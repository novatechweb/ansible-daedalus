Vagrant.configure("2") do |config|
    config.vm.box = "daedalus"
    config.vm.box_url = "vmdaedalus/vmdaedalus-virtualbox.box"
    config.vm.define "vmdaedalus.novatech-llc.com"
    config.vm.hostname = "vmdaedalus.novatech-llc.com"
    config.vm.provider "virtualbox" do |vb|
        vb.name = "vmdaedalus"
    end
#    config.vm.network "public_network", ip: "192.168.0.100", netmask:"255.255.0.0", bridge: "enp0s31f6"
    config.vm.network "private_network", ip: "192.168.0.100", netmask:"255.255.0.0"
    config.vm.synced_folder "vmdaedalus/bacula-restores", "/tmp/bacula-restores", type: "rsync"

    config.vm.provision "ansible" do |ansible|
        ansible.verbose = "v"
        ansible.playbook = "ansible-playbook/site.yml"
        ansible.groups = {
            "bacula" => ["vmdaedalus.novatech-llc.com"],
            "docker-hosts" => ["vmdaedalus.novatech-llc.com"]
        }
        # ansible.tags = []
        # ansible.skip_tags = ["restore"]
        ansible.host_vars = {
            "vmdaedalus.novatech-llc.com" => {
                "network_connection" => "System enp0s8"
            }
        }
    end
    
end
