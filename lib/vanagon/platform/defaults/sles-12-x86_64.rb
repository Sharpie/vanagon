platform "sles-12-x86_64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  #plat.provision_with 'zypper addrepo "https://download.suse.com/Download?build=0&package=sles12-sp5&url=https://download.suse.com/Download/repo/SUSE/Products/SLE-Product-SLE-12-SP5-Desktop/x86_64/" SLES12-SP5-Updates'
  #plat.provision_with 'zypper addrepo "https://download.suse.com/Download?build=0&package=sles12-sp5&url=https://download.suse.com/Download/repo/SUSE/Updates/SLE-12-SP5/x86_64/" SLES12-SP5-Pool'
  packages = %w(aaa_base autoconf automake rsync gcc make rpm-build)
  plat.provision_with "zypper -n --no-gpg-checks install -y #{packages.join(' ')}"
  plat.install_build_dependencies_with "zypper -n --no-gpg-checks install -y"
  plat.docker_registry "registry.suse.com/suse"
  plat.docker_image "sles12sp5:latest"
  plat.docker_arch "linux/amd64"
end
