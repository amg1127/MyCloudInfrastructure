# https://www.terraform.io/docs/providers/docker/d/registry_image.html

data "docker_registry_image" "distribution" {
    name = "debian:stable"
}

resource "docker_image" "distribution" {
    name = data.docker_registry_image.distribution.name
    keep_locally = true
    pull_triggers = [data.docker_registry_image.distribution.sha256_digest]
}

resource "random_uuid" "provisionerTriggerUUID" { }

# https://www.terraform.io/docs/providers/docker/r/container.html
# Note: 'fixedIPv4' is ignored intentionally within this module

resource "docker_container" "dockerContainer" {
    name = var.hostName
    image = docker_image.distribution.latest
    hostname = var.hostName
    start = true
    must_run = true
    command = [ "/bin/bash", "-c", "[ -x \"$${1}\" ] && { \"$${1}\" || exit 1; }; unset HOSTNAME HOME PWD TERM SHLVL PATH; export container=docker; exec -a /sbin/init /lib/systemd/systemd --system", "/sbin/init", local.provisionerScript ]
    memory = 1024
    memory_swap = 2048
    capabilities {
        add = [
            # Required for Netfilter
            "CAP_NET_ADMIN",
        ]
        drop = [
            # Just in case...
            "SYS_ADMIN"
        ]
    }
    # Private network
    networks_advanced {
        name = var.privateLanID
        ipv4_address = var.virtualMachinePrivIPv4
    }
    # Public network - it will be connected to the default Docker 'bridge' network
    networks_advanced {
        name = local.dockerDefaultNetwork
    }
    mounts {
        source = "/sys/fs/cgroup"
        target = "/sys/fs/cgroup"
        type = "bind"
        read_only = true
    }
    tmpfs = {
        "/tmp": "exec",
        "/run": "exec",
        "/run/lock": "noexec"
    }
    dynamic "volumes" {
        for_each = var.sharedFileSystems
        content {
            volume_name = volumes.value.fileSystemID
            container_path = volumes.value.mountPoint
            read_only = false
        }
    }
    upload {
        content = file(var.SSHPublicKeyPath)
        file = local.administrativeSSHAuthorizedKeyFile
    }
    # Because the official Docker image doesn't provide a installation of "systemd" nor "ssh", I am installing them manually via a first-run script.
    upload {
        content = <<-REMOTEPROVISIONER
        #!/bin/bash
        set -e
        set -o pipefail
        set -x
        /bin/cat > /etc/resolv.conf <<'DNSCONFIG'
        nameserver 8.8.8.8
        nameserver 8.8.4.4
        DNSCONFIG
        /bin/chmod -Rv go-rwx "${local.administrativeSSHFolder}"
        /usr/bin/apt-get update && /usr/bin/apt-get -y install ansible procps psmisc ssh systemd
        /bin/systemctl enable ssh
        /bin/systemctl set-default multi-user.target
        /bin/chmod -v -x "${local.provisionerScript}"
        /bin/rm -fv "${local.provisionerScript}"
        echo ' **** First-boot configuration has been completed successfully. ****'
        exit 0
        REMOTEPROVISIONER

        file = local.provisionerScript
        executable = true
    }
    working_dir = "/"
}

# This null resource waits for the SSH service of the new container to be accessible and preconfigures Ansible (and its dependencies)
resource "null_resource" "dockerContainerPoller" {
    triggers = {
        containerName = docker_container.dockerContainer.name
        containerIPs = join(",", sort(docker_container.dockerContainer.network_data[*].ip_address))
    }

    provisioner "local-exec" {
        command = "docker logs --follow \"${docker_container.dockerContainer.name}\" & logPid=\"$${!}\"; sleep 5; while ! ssh-keyscan \"${local.virtualMachinePubIPv4}\" < /dev/null; do sleep 15; [ -d \"/proc/$${logPid}/fd\" ] || exit 0; done; kill -TERM \"$${logPid}\""
        interpreter = [ "/bin/bash", "-c" ]
    }
}

locals {
    administrativeSSHUser = "root"
    administrativeSSHUserHome = "/${local.administrativeSSHUser}"
    administrativeSSHFolder = "${local.administrativeSSHUserHome}/.ssh"
    administrativeSSHAuthorizedKeyFile = "${local.administrativeSSHFolder}/authorized_keys"
    provisionerScript = "${local.administrativeSSHUserHome}/.first_boot_provisioner_${random_uuid.provisionerTriggerUUID.result}.sh"

    dockerDefaultNetwork = "bridge"
    virtualMachineID = var.hostName
    virtualMachinePubIPv4 = [for network in docker_container.dockerContainer.network_data : network.ip_address if network.network_name == local.dockerDefaultNetwork][0]
}

