$domain = "example.com"
$domain_ip_address = "192.168.56.2"
$username = "vagrant"
$password = "HeyH0Password"

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox"
  config.vm.box = "gusztavvargadr/windows-server"
  config.vm.define "windows-domain-controller"
  config.vm.hostname = "dc"

  # NOTE: The default winrm transport 'negotiate' stops working after the domain controller is configured
  # https://groups.google.com/forum/#!topic/vagrant-up/sZantuCM0q4
  config.winrm.transport = :plaintext
  config.winrm.basic_auth_only = true
  config.winrm.timeout = 2000

  config.vm.network "private_network", ip: $domain_ip_address

  # SECTION: Provisioners
  config.vm.provision "Create Forrest", type: "shell", path: "Scripts/Invoke-Forrest.ps1", args: [$domain, $password]
  config.vm.provision "Reboot Machine", type: "shell", reboot: true
  config.vm.provision "Configure Admin Supreme", type: "shell", path: "Scripts/Configure-AdminSupreme.ps1", args: [$username]
  config.vm.provision "Configure Domain", type: "shell", path: "Scripts/Configure-Domain.ps1"
  config.vm.provision "Create Test Users", type: "shell", path: "Scripts/New-ADTestUsers.ps1", args: [$password]
  # !SECTION: Provisioners

end
