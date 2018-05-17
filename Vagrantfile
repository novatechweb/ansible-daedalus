Vagrant.configure("2") do |config|

    config.vm.define "vmdaedalus.novatech-llc.com", primary: true do |main|
        main.vm.box = "daedalus"
        main.vm.box_url = "vmdaedalus/vmdaedalus-virtualbox.box"
        main.vm.hostname = "vmdaedalus.novatech-llc.com"
        main.vm.provider "virtualbox" do |vb|
            vb.name = "vmdaedalus"
            vb.memory = 4096
            vb.cpus = 4
        end
    #    config.vm.network "public_network", ip: "192.168.0.100", netmask:"255.255.0.0", bridge: "enp0s31f6"
        main.vm.network "private_network", ip: "192.168.0.100", netmask:"255.255.0.0"
        main.vm.synced_folder "/mnt/vm/bacula-restores",
            "/mnt/bacula-restores",
            id: "bacula-restores",
            owner: "root",
            group: "root",
            mount_options: ["ro"]
    end

    config.vm.define "buildbot-worker.novatech-llc.com" do |worker|
        worker.vm.box = "centos/atomic-host"
        worker.vm.hostname = "buildbot-worker.novatech-llc.com"
        worker.vm.provider "virtualbox" do |vb|
            vb.name = "bbworker"
        end
    end
end
