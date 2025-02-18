require 'package'

class Libsigsegv < Package
  description 'GNU libsigsegv is a library for handling page faults in user mode.'
  homepage 'https://www.gnu.org/software/libsigsegv/'
  version '2.14'
  license 'GPL-2+'
  compatibility 'all'
  source_url 'https://ftpmirror.gnu.org/libsigsegv/libsigsegv-2.14.tar.gz'
  source_sha256 'cdac3941803364cf81a908499beb79c200ead60b6b5b40cad124fd1e06caa295'

  binary_url({
    aarch64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/libsigsegv/2.14_armv7l/libsigsegv-2.14-chromeos-armv7l.tpxz',
     armv7l: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/libsigsegv/2.14_armv7l/libsigsegv-2.14-chromeos-armv7l.tpxz',
       i686: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/libsigsegv/2.14_i686/libsigsegv-2.14-chromeos-i686.tpxz',
     x86_64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/libsigsegv/2.14_x86_64/libsigsegv-2.14-chromeos-x86_64.tpxz'
  })
  binary_sha256({
    aarch64: '72d6d5f467bfeb47fac29f664344385021932108ca3c72de2719181e1744ec7c',
     armv7l: '72d6d5f467bfeb47fac29f664344385021932108ca3c72de2719181e1744ec7c',
       i686: '08efedeb5ea7af99b35ed1073b20feed5bb1a89dfc5f6a1e3f5e0159f254e22f',
     x86_64: 'efc24c18a85c611994d3e516994ab71a0a1f79780d47af8267940d68ae7f8716'
  })

  def self.build
    system 'autoreconf -fiv'
    # libsigsegv fails to build with LTO.
    ENV['CREW_DISABLE_ENV_OPTIONS'] = '1'
    reload_constants
    system "#{CREW_ENV_FNO_LTO_OPTIONS} ./configure #{CREW_OPTIONS} \
    --enable-shared \
    --enable-static \
    --enable-relocatable"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end

  def self.check
    system 'make', 'check'
  end
end
