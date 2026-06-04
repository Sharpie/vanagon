platform "amazon-2-aarch64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  packages = %w(
    autoconf
    automake
    cmake3
    createrepo
    curl
    gcc
    gcc-c++
    libtool
    libarchive
    make
    rpm-libs
    rpm-build
    rsync
    systemd
    which
  )
  plat.provision_with("yum install -y --nogpgcheck  #{packages.join(' ')}")
  plat.install_build_dependencies_with "yum install --assumeyes"
  plat.docker_image "amazonlinux:2"
  plat.docker_arch "linux/arm64"
end
