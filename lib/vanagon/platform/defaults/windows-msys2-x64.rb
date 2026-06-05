platform 'windows-msys2-x64' do |plat|
  plat.servicetype 'windows'

  packages = %w[
    autoconf
    git
    make
    patch
    mingw-w64-ucrt-x86_64-gcc
    mingw-w64-ucrt-x86_64-gdbm
    mingw-w64-ucrt-x86_64-zlib
    mingw-w64-ucrt-x86_64-gcc-libs
  ]

  # Story time:
  #
  # Windows can end up with multiple MSYS2 installations. This is common
  # on GitHub actions where the runner image comes with `C:/msys64/`
  # pre-installed, but inactive, and the `msys/setup-msys2` creates a new
  # installation under `D:/a/_temp/msys64/`.
  #
  # Thus: assume Vanagon is running in a MSYS2 shell which mounts the chosen
  # MSYS2 installation and sets PATH appropriately. "UNIX" paths in this shell,
  # like `/usr/bin/` should work fine, but fully-qualified Windows paths like
  # `C:/msys64/usr/bin/` might point to the "wrong" MSYS2 installation.
  plat.provision_with("/usr/bin/pacman -S --noconfirm --needed #{packages.join(' ')}")
  plat.install_build_dependencies_with '/usr/bin/pacman -S --noconfirm --needed'

  plat.make '/usr/bin/make'
  plat.patch 'TMP=/var/tmp /usr/bin/patch.exe --binary'

  plat.platform_triple 'x86_64-w64-mingw32'

  # In the MSYS2 UCRT64 environment, gcc is the native UCRT64 compiler.
  # Do not use the full x86_64-w64-mingw32- prefix here; that is only needed
  # when cross-compiling from a Cygwin host.
  plat.environment 'CC', 'gcc'
  plat.environment 'CXX', 'g++'

  plat.package_type 'archive'
  plat.output_dir 'windows'
end
