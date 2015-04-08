#!/bin/sh

# Generated at Thu Mar  5 14:33:50 2015 with Daemon::Control 0.001006

### BEGIN INIT INFO
# Provides:          MIDAS FastCGI daemon
# Required-Start:    $nginx
# Required-Stop:     $nginx
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start MIDAS FastCGI daemon
# Description:       Start the daemon that runs the MIDAS webapp backend
### END INIT INFO`

[ -r /var/www/MIDAS/live/midas_env.sh ] && . /var/www/MIDAS/live/midas_env.sh

if [ -x /var/www/MIDAS/live/midas ];
then
    /var/www/MIDAS/live/midas $1
else
    echo "Required program /var/www/MIDAS/live/midas not found!"
    exit 1;
fi
