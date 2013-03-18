#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

# Ruby
ruby_basename=ruby-1.9.3-p327
ruby_archive=$ruby_basename.tar.gz

mkdir -p $chroot/$bosh_dir/src
cp -r $dir/assets/$ruby_archive $chroot/$bosh_dir/src

run_in_bosh_chroot $chroot "
cd src
tar zxvf $ruby_archive
cd $ruby_basename
sed -i 's/\\(OSSL_SSL_METHOD_ENTRY(SSLv2[^3]\\)/\\/\\/\\1/g' ./ext/openssl/ossl_ssl.c
./configure --prefix=$bosh_dir --disable-install-doc
make -j4 && make install
"

# RubyGems
rubygems_basename=rubygems-1.8.24
rubygems_archive=$rubygems_basename.tgz

mkdir -p $chroot/$bosh_dir/src
cp -r $dir/assets/$rubygems_archive $chroot/$bosh_dir/src

run_in_bosh_chroot $chroot "
cd src
tar zxvf $rubygems_archive
cd $rubygems_basename

# This fails, but apparently does work for 1.3.7
$bosh_dir/bin/ruby setup.rb || true
"

# Skip gem docs
mkdir -p $chroot/var/vcap/bosh/etc
echo "gem: --local --no-rdoc --no-ri" >> $chroot/var/vcap/bosh/etc/gemrc

# Bundler
bundler_gem=bundler-1.2.3.gem

mkdir -p $chroot/$bosh_dir/src
cp -r $dir/assets/$bundler_gem $chroot/$bosh_dir/src

run_in_bosh_chroot $chroot "
cd src
gem install $bundler_gem --no-ri --no-rdoc
"
