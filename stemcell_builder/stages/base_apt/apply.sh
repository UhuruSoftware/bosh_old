#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

debs="build-essential libssl-dev lsof \
strace bind9-host dnsutils tcpdump iputils-arping \
curl wget libcurl3 libcurl3-dev bison libreadline6-dev \
libxml2 libxml2-dev libxslt1.1 libxslt1-dev zip unzip \
nfs-common flex psmisc apparmor-utils iptables sysstat \
rsync openssh-server traceroute libncurses5-dev quota \
libaio1 gdb tripwire libcap2-bin libyaml-dev cmake\
libpcre3 libpcre3-dev apache2 libapr1 libaprutil1 php5 php5-dev \
php5-mysql php5-pgsql php5-gd php5-common php5-curl php5-mcrypt \
php5-imagick php5-xmlrpc php5-imap php-pear zend-framework \
freetds-common freetds-bin unixodbc php5-sybase smbfs \
libpango1.0-dev libgd-gd2-perl perlmagick libcalendar-simple-perl \
librrds-perl libgd2-xpm-dev mkpasswd"



# Disable interactive dpkg
debconf="debconf debconf/frontend select noninteractive"
run_in_chroot $chroot "echo ${debconf} | debconf-set-selections"

# Networking...
cp $assets_dir/etc/hosts $chroot/etc/hosts

# Timezone
cp $assets_dir/etc/timezone $chroot/etc/timezone
run_in_chroot $chroot "dpkg-reconfigure -fnoninteractive -pcritical tzdata"

# Locale
cp $assets_dir/etc/default/locale $chroot/etc/default/locale
run_in_chroot $chroot "
locale-gen en_US.UTF-8
dpkg-reconfigure -fnoninteractive -pcritical libc6
dpkg-reconfigure -fnoninteractive -pcritical locales
"

# Firstboot script
cp $assets_dir/etc/rc.local $chroot/etc/rc.local
cp $assets_dir/root/firstboot.sh $chroot/root/firstboot.sh
chmod 0755 $chroot/root/firstboot.sh

cat > $chroot/etc/apt/sources.list <<EOS
deb http://archive.ubuntu.com/ubuntu $DISTRIB_CODENAME main universe multiverse
deb http://archive.ubuntu.com/ubuntu $DISTRIB_CODENAME-updates main universe multiverse
deb http://security.ubuntu.com/ubuntu $DISTRIB_CODENAME-security main universe multiverse
EOS

# Upgrade upstart first, to prevent it from messing up our stubs and starting daemons anyway
pkg_mgr install upstart

# Upgrade
run_in_chroot $chroot "apt-get update"
run_in_chroot $chroot "apt-get -f -y --force-yes --no-install-recommends dist-upgrade"
run_in_chroot $chroot "apt-get clean"

# Install base debs needed by both the warden and bosh
pkg_mgr install $debs

run_in_chroot $chroot "
/etc/init.d/apache2 stop
update-rc.d -f apache2 remove
"
# Lifted from bosh_debs
pkg_mgr install "scsitools mg htop module-assistant debhelper runit"
#/Lifted from bosh_debs
