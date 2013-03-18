#!/bin/bash
set -e

export C_INCLUDE_PATH=/var/vcap/packages/libpq/include:$C_INCLUDE_PATH
export LIBRARY_PATH=/var/vcap/packages/libpq/lib:$LIBRARY_PATH
export PATH=/var/vcap/packages/ruby/bin:$PATH
LOG_DIR=/var/vcap/sys/log/nagios

ruby /var/vcap/packages/nagios_dashboard/nagios_dashboard/bin/generate_nagios_config.rb -s /var/vcap/store/nagios/etc/serviceext >>$LOG_DIR/generate_nagios_config.stdout.log 2>>$LOG_DIR/generate_nagios_config.stderr.log

if [ `md5sum /var/vcap/packages/nagios_dashboard/nagios_dashboard/config/uhuru-hosts.cfg | awk '{print $1}'` != `md5sum /var/vcap/packages/nagios_dashboard/nagios_dashboard/config/uhuru-hosts.cfg.old | awk '{print $1}'` ] ; then
  chmod 777 /var/vcap/packages/nagios_dashboard/nagios_dashboard/config/uhuru-hosts.cfg
  /var/vcap/jobs/nagios_dashboard/bin/nagios reload
fi

if [ `md5sum /var/vcap/packages/nagios_dashboard/nagios_dashboard/config/uhuru-ngraph.ncfg | awk '{print $1}'` != `md5sum /var/vcap/packages/nagios_dashboard/nagios_dashboard/config/uhuru-ngraph.ncfg.old | awk '{print $1}'` ] ; then
  chmod 777 /var/vcap/packages/nagios_dashboard/nagios_dashboard/config/uhuru-ngraph.ncfg.cfg
  /var/vcap/jobs/nagios_dashboard/bin/nagios_grapher restart
fi

