#!/bin/bash
set -e

export C_INCLUDE_PATH=/var/vcap/packages/libpq/include:$C_INCLUDE_PATH
export LIBRARY_PATH=/var/vcap/packages/libpq/lib:$LIBRARY_PATH
export PATH=/var/vcap/packages/ruby/bin:$PATH
LOG_DIR=/var/vcap/sys/log/nagios

export GEM_HOME=/var/vcap/packages/nagios_dashboard/gem_home
export BUNDLE_GEMFILE=/var/vcap/packages/nagios_dashboard/nagios_dashboard/Gemfile

bundle exec ruby /var/vcap/packages/nagios_dashboard/nagios_dashboard/bin/generate_nagios_config.rb >>$LOG_DIR/generate_nagios_config.stdout.log 2>>$LOG_DIR/generate_nagios_config.stderr.log

if [ `md5sum /var/vcap/packages/nagios_dashboard/nagios_dashboard/config/uhuru-hosts.cfg | awk '{print $1}'` != `md5sum /var/vcap/packages/nagios_dashboard/nagios_dashboard/config/uhuru-hosts.cfg.old | awk '{print $1}'` ] ; then
  /var/vcap/jobs/nagios_dashboard/bin/nagios reload
fi
