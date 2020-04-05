# My Cloud Infrastructure

## Introduction

This repository hosts the code that run my personal cloud infrastructure, composed by:

* A highly-available load balancer, which also will provide DNS service
* A public web server serving static content
* A public e-mail server that runs my domain's e-mail service
* A private authentication framework
* A private monitoring and telemetry system

## Design Goals

### Cloud infrastructure orchestration

* I will code my infrastructure using [Terraform CLI](https://www.terraform.io/docs/cli-index.html) and call it directly.
* The Terraform code will be provider-agnostic and will allow me to quickly destroy my infrastructure in one provider and deploy it on another. For testing purposes, I will also use [Docker](https://docs.docker.com/reference/) [provider](https://www.terraform.io/docs/providers/docker/) to orchestrate infrastructure in my own workstation.
* Terraform will invoke [Ansible](https://docs.ansible.com/ansible/latest/) inside virtual machines to perform post-installation tasks and [DejaGnu](https://www.gnu.org/software/dejagnu/manual/) to perform infrastructure tests.

### Softwares to be used

* Virtual machines will initially run [Debian 10 (buster)](https://www.debian.org/releases/buster/). I firstly considered using [Arch Linux](https://www.archlinux.org/) and changed my mind because:
    * Official cloud images are not available on main cloud providers [(reference)](https://wiki.archlinux.org/index.php/Arch_Linux_AMIs_for_Amazon_Web_Services).
    * Package metadata is not cryptographically signed yet [(reference)](https://wiki.archlinux.org/index.php/Pacman/Package_signing).
    * Packages I may need will possibly be available in [AUR](https://wiki.archlinux.org/index.php/AUR) only.
* I will use [nginx](http://nginx.org/en/docs/) as HTTP server.
* Mail service will run on [Postfix](http://www.postfix.org/documentation.html) (MTA) and [Dovecot](https://doc.dovecot.org/) (MUA). Additionally, the following tools/components/techniques will be used to protect the e-mail component:
    * [Amavis](https://www.ijs.si/software/amavisd/#doc), integrating with [ClamAV](http://www.clamav.net/documents/clam-antivirus-user-manual)
    * [RSPAMD](https://www.rspamd.com/doc/index.html) and the following plugins (others may be enable once I learn about them):
        * [DKIM](https://www.rspamd.com/doc/modules/dkim.html)
        * [DMARC](https://www.rspamd.com/doc/modules/dmarc.html)
        * [Greylisting](https://www.rspamd.com/doc/modules/greylisting.html)
        * [MX Check](https://www.rspamd.com/doc/modules/mx_check.html)
        * [SPF](https://www.rspamd.com/doc/modules/spf.html)
    * [Spamhaus ZEN](https://www.spamhaus.org/zen/)
    * [Nolisting](https://en.wikipedia.org/wiki/Nolisting)
* [DNSMasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) will be installed on all virtual machines to provide local DNS cache.
* The load balancer will run [Keepalived](https://keepalived.org/manpage.html), [HAproxy](https://www.haproxy.org/#docs) and [ISC Bind](https://bind9.readthedocs.io/en/latest/).
* Firewall will be provided by [NFTables](https://wiki.nftables.org/).
* Authentication framework will be based on [389-ds](https://www.port389.org/docs/389ds/documentation.html) and [MIT Kerberos](https://web.mit.edu/Kerberos/krb5-latest/doc/).
* Monitoring and telemetry will use [Zabbix](https://www.zabbix.com/documentation/current/manual).
* Persistent data such as web content and e-mail messages will be stored on provider's NFS system.
    * NFS seems not to be [widely available on Azure](https://www.hametbenoit.info/2020/01/04/azure-nfs-v3-and-v4-are-now-available-for-storage-account-preview/). I will experiment CIFS there.
* [Fail2Ban](https://github.com/fail2ban/fail2ban/wiki) will be used to manage SSH brute-force attacks coming from public network (internet).

### Assumptions

#### General
* Each component should be highly available and at least two instances of each component should be deployed.
* If the underlying protocol does not allow load balancing naturally, connections should be diverted to the load balancer.

#### Network
* The machines will be instantiated with a dynamic public IP address. That is caracteristic to cloud environmnent, unless I create a private network and connect to it via VPN in advance.
    * Because I don't want to setup a VPN connection, I will deploy all machines with two network interfaces: a public one and another connected to a private and isolated network.

#### DNS service
* Initially, I will keep the administration of my DNS zone in my current domain registrar and delegate subdomains to my DNS servers.
* I will split DNS service in two views. They will support dynamic update and DNSSEC3 with automatic zone signature.
