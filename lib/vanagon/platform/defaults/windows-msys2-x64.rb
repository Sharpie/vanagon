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

  plat.provision_with("C:/msys64/usr/bin/pacman.exe -S --noconfirm --needed #{packages.join(' ')}")
  plat.install_build_dependencies_with 'C:/msys64/usr/bin/pacman.exe -S --noconfirm --needed'

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
