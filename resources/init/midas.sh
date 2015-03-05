#!/bin/sh

# Generated at Wed Mar  4 17:08:26 2015 with Daemon::Control 0.001006

### BEGIN INIT INFO
# Provides:          MIDAS FastCGI daemon
# Required-Start:    $nginx
# Required-Stop:     $nginx
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start MIDAS FastCGI daemon
# Description:       Start the daemon that runs the MIDAS webapp backend
### END INIT INFO`


export PERL5LIB=/www/jt6/perl5/lib/perl5:/www/jt6/MIDAS/dist/lib


if [ -x /www/jt6/MIDAS/resources/init/midas ];
then
    /www/jt6/MIDAS/resources/init/midas $1
else
    echo "Required program /www/jt6/MIDAS/resources/init/midas not found!"
    exit 1;
fi
