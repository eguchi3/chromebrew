require 'package'

class Xxhash < Package
  description 'xxHash is an extremely fast non-cryptographic hash algorithm, working at speeds close to RAM limits.'
  homepage 'https://cyan4973.github.io/xxHash/'
  version '0.8.1'
  license 'BSD-2 and GPL-2+'
  compatibility 'all'
  source_url 'https://github.com/Cyan4973/xxHash.git'
  git_hashtag "v#{version}"

  binary_url({
    aarch64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/xxhash/0.8.1_armv7l/xxhash-0.8.1-chromeos-armv7l.tar.xz',
     armv7l: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/xxhash/0.8.1_armv7l/xxhash-0.8.1-chromeos-armv7l.tar.xz',
       i686: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/xxhash/0.8.1_i686/xxhash-0.8.1-chromeos-i686.tar.xz',
     x86_64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/xxhash/0.8.1_x86_64/xxhash-0.8.1-chromeos-x86_64.tar.xz'
  })
  binary_sha256({
    aarch64: '7ad8cdd3611bf8336070ec55d92c30cae584656c3720ca2368101826ca089c4a',
     armv7l: '7ad8cdd3611bf8336070ec55d92c30cae584656c3720ca2368101826ca089c4a',
       i686: '5d70bb5ac38e15afd006ac0c6957ef81cfae0a05d27428ffbc3501b7b899cd10',
     x86_64: 'c1f0005397d8433a33ab6195f82d7f17e6271530599ad52538c6550360b97afc'
  })

  no_patchelf
  no_zstd

  def self.build
    system 'make', "PREFIX=#{CREW_PREFIX}", "LIBDIR=#{CREW_LIB_PREFIX}"
  end

  def self.install
    system 'make', "PREFIX=#{CREW_PREFIX}", "LIBDIR=#{CREW_LIB_PREFIX}", "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end
