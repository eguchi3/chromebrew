require 'package'

class Git < Package
  description 'Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.'
  homepage 'https://git-scm.com/'
  version '2.37.2'
  license 'GPL-2'
  compatibility 'all'
  source_url 'https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.37.2.tar.xz'
  source_sha256 '1c3d9c821c4538e7a6dac30a4af8bd8dcfe4f651f95474c526b52f83406db003'

  binary_url({
    aarch64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/git/2.37.2_armv7l/git-2.37.2-chromeos-armv7l.tar.xz',
     armv7l: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/git/2.37.2_armv7l/git-2.37.2-chromeos-armv7l.tar.xz',
       i686: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/git/2.37.2_i686/git-2.37.2-chromeos-i686.tar.xz',
     x86_64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/git/2.37.2_x86_64/git-2.37.2-chromeos-x86_64.tar.xz'
  })
  binary_sha256({
    aarch64: '70220afef4ed6b3a3d1efefce28ab02a118e09e206c1e6f7411959855839085e',
     armv7l: '70220afef4ed6b3a3d1efefce28ab02a118e09e206c1e6f7411959855839085e',
       i686: 'f1d49a1f9cab20818b67a654af0ce6f073c68bf972643426fbd122ecd58293ef',
     x86_64: '1c683f85c63ab3eb205b3f023c85b3422b940da4e958c7445928d0e9c94b5903'
  })

  depends_on 'ca_certificates' => :build
  depends_on 'musl_curl' => :build
  depends_on 'rust' => :build
  depends_on 'musl_brotli' => :build
  depends_on 'musl_libidn2' => :build
  depends_on 'musl_libunbound' => :build
  depends_on 'musl_libunistring' => :build
  depends_on 'musl_native_toolchain' => :build
  depends_on 'musl_ncurses' => :build
  depends_on 'musl_openssl' => :build
  depends_on 'musl_zlib' => :build
  depends_on 'musl_zstd' => :build
  depends_on 'musl_expat' => :build

  is_musl
  is_static
  no_patchelf
  no_zstd

  def self.patch
    # Patch to prevent error function conflict with libidn2
    # By replacing all calls to error with git_error.
    system "sed -i 's,^#undef error\$,#undef git_error,' usage.c"
    sedcmd = 's/\([[:blank:]]\)error(/\1git_error(/'.dump
    system "grep -rl '[[:space:]]error(' . | xargs sed -i #{sedcmd}"
    sedcmd2 = 's/\([[:blank:]]\)error (/\1git_error (/'.dump
    system "grep -rl '[[:space:]]error (' . | xargs sed -i #{sedcmd2}"
    system "grep -rl ' !!error(' . | xargs sed -i 's/ \!\!error(/ \!\!git_error(/g'"
    system "sed -i 's/#define git_error(...) (error(__VA_ARGS__), const_error())/#define git_error(...) (git_error(__VA_ARGS__), const_error())/' git-compat-util.h"
    # CMake patches.
    # Avoid undefined reference to `trace2_collect_process_info' &  `obstack_free'
    system "sed -i 's,compat_SOURCES unix-socket.c unix-stream-server.c,compat_SOURCES unix-socket.c unix-stream-server.c compat/linux/procinfo.c compat/obstack.c,g' contrib/buildsystems/CMakeLists.txt"
    # The VCPKG optout in this CmakeLists.txt file is quite broken.
    system "sed -i 's/set(USE_VCPKG/#set(USE_VCPKG/g' contrib/buildsystems/CMakeLists.txt"
    system "sed -i 's,set(PERL_PATH /usr/bin/perl),set(PERL_PATH #{CREW_PREFIX}/bin/perl),g' contrib/buildsystems/CMakeLists.txt"
    system "sed -i 's,#!/usr/bin,#!#{CREW_PREFIX}/bin,g' contrib/buildsystems/CMakeLists.txt"
    # Without the following DESTDIR doesn't work.
    system "sed -i 's,\${CMAKE_INSTALL_PREFIX}/bin/git,\${CMAKE_BINARY_DIR}/git,g' contrib/buildsystems/CMakeLists.txt"
    system "sed -i 's,\${CMAKE_INSTALL_PREFIX}/bin/git,\\\\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/bin/git,g' contrib/buildsystems/CMakeLists.txt"
    system "sed -i 's,\${CMAKE_INSTALL_PREFIX},\\\\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX},g' contrib/buildsystems/CMakeLists.txt"
  end

  def self.build
    # This build is dependent upon the musl curl package
    @curl_static_libs = `#{CREW_MUSL_PREFIX}/bin/curl-config --static-libs`.chomp.gsub('=auto', '')
    @git_libs = "#{@curl_static_libs} \
        -l:libresolv.a \
        -l:libm.a \
        -l:libbrotlidec-static.a \
        -l:libbrotlicommon-static.a \
        -l:libzstd.a \
        -l:libz.a \
        -l:libssl.a \
        -l:libcrypto.a \
        -l:libpthread.a \
        -l:libncursesw.a \
        -l:libtinfow.a \
        -l:libcurl.a \
        -l:libidn2.a \
        -l:libexpat.a"

    Dir.mkdir 'contrib/buildsystems/builddir'
    Dir.chdir 'contrib/buildsystems/builddir' do
      # This is needed for git's cmake compiler check, which assumes glibc sysctl.h
      FileUtils.mkdir_p 'sys'
      FileUtils.ln_s "#{CREW_MUSL_PREFIX}/#{ARCH}-linux-musl#{MUSL_ABI}/include/linux/sysctl.h", 'sys/sysctl.h'

      system "#{MUSL_CMAKE_OPTIONS.gsub('LDFLAGS=\'',
                                        "LDFLAGS=\' #{@git_libs} -L#{CREW_MUSL_PREFIX}/lib \
         -Wl,-rpath=#{CREW_MUSL_PREFIX}/lib").gsub('-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=TRUE',
                                                   '-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF')} \
          -DCMAKE_C_STANDARD_LIBRARIES='#{@git_libs}' \
          -DCMAKE_CXX_STANDARD_LIBRARIES='#{@git_libs}' \
          -DNO_VCPKG=TRUE \
          -DUSE_VCPKG=FALSE \
          -Wdev \
          -G Ninja \
          .."
      system 'samu'
    end
  end

  def self.install
    system "DESTDIR=#{CREW_DEST_DIR} samu -C contrib/buildsystems/builddir install"
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/share/git-completion"
    FileUtils.cp_r Dir.glob('contrib/completion/.'), "#{CREW_DEST_PREFIX}/share/git-completion/"

    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/etc/bash.d/"
    @git_bashd_env = <<~GIT_BASHD_EOF
      # git bash completion
      source #{CREW_PREFIX}/share/git-completion/git-completion.bash
    GIT_BASHD_EOF
    File.write("#{CREW_DEST_PREFIX}/etc/bash.d/git", @git_bashd_env)
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"
    # Simplying the following block leads to the symlink not being created properly.
    Dir.chdir "#{CREW_DEST_PREFIX}/bin" do
      FileUtils.ln_s '../share/musl/bin/git', 'git'
    end
  end

  def self.check
    # Check to see if linking libcurl worked, which means
    # git-remote-https should exist
    unless File.symlink?("#{CREW_DEST_MUSL_PREFIX}/libexec/git-core/git-remote-https") ||
           File.exist?("#{CREW_DEST_MUSL_PREFIX}/libexec/git-core/git-remote-https")
      abort 'git-remote-https is broken'.lightred
    end
  end
end
