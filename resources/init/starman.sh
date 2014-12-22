#!/bin/sh

# Generated at Thu Dec 18 13:28:19 2014 with Daemon::Control 0.001006

### BEGIN INIT INFO
# Provides:          MIDAS starman server
# Required-Start:    $nginx
# Required-Stop:     $nginx
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start MIDAS starman server
# Description:       Start starman server to run the MIDAS webapp backend
### END INIT INFO`


export PERL5LIB=/www/jt6/perl5/lib/perl5


if [ -x /www/jt6/MIDAS/resources/init/starman ];
then
   su -m www-data -c "/www/jt6/MIDAS/resources/init/starman $1"
else
    echo "Required program /www/jt6/MIDAS/resources/init/starman not found!"
    exit 1;
fi
