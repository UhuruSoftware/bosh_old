export C_INCLUDE_PATH=/var/vcap/packages/libpq/include:$C_INCLUDE_PATH
export LIBRARY_PATH=/var/vcap/packages/libpq/lib:$LIBRARY_PATH
export PATH=/var/vcap/packages/ruby/bin:$PATH
ruby /var/vcap/packages/nagios_dashboard/nagios_dashboard/bin/send_mail.rb "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"