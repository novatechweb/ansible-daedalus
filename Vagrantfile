$bbworker = <<-SCRIPT
yum install -y \
    epel-release

yum install -y \
    device-mapper-persistent-data \
    git \
    lvm2 \
    python-pip \
    yum-utils

yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

yum remove -y \
    docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate

yum install -y \
    docker-ce

pip install \
    docker

systemctl start docker
docker run --rm hello-world
SCRIPT

Vagrant.configure("2") do |config|

    config.vm.define "vmdaedalus", primary: true do |main|
        main.vm.box = "daedalus"
        main.vm.box_url = "vmdaedalus/vmdaedalus-virtualbox.box"
        main.vm.hostname = "vmdaedalus.novatech-llc.com"
        main.vm.provider "virtualbox" do |vb|
            vb.name = "vmdaedalus"
            vb.memory = 6000
            vb.cpus = 4
        end
    #    config.vm.network "public_network", ip: "192.168.0.100", netmask:"255.255.0.0", bridge: "enp0s31f6"
        main.vm.network "private_network", 
            ip: "192.168.0.100", 
            netmask:"255.255.0.0"

        main.vm.network "forwarded_port",
            guest: 2375,
            host: 12375,
            protocol: "tcp",
            id: "docker"

        main.vm.synced_folder "/mnt/vm/bacula-restores",
            "/mnt/bacula-restores",
            id: "bacula-restores",
            owner: "root",
            group: "root",
            mount_options: ["ro"]
    end

    config.vm.define "bbworker" do |worker|
        worker.vm.box = "centos/7"
        worker.vm.hostname = "bbworker.novatech-llc.com"
        worker.vm.provider "virtualbox" do |vb|
            vb.name = "bbworker"
            vb.cpus = 1
        end

        worker.vm.network "private_network", 
            ip: "192.168.0.150", 
            netmask:"255.255.0.0"

        worker.vm.provision "shell", inline: $bbworker

    end
end
