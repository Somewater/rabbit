#! /bin/sh
### BEGIN INIT INFO
# Provides:		  vk-rabbit-notify
# Required-Start:	$local_fs $remote_fs
# Required-Stop:	 $local_fs $remote_fs
# Default-Start:	 2 3 4 5
# Default-Stop:	  S 0 1 6
# Short-Description: vk-rabbit-notify initscript
# Description:	   vk-rabbit-notify
### END INIT INFO

# Add to boot:
# $ chmod 755 /etc/init.d/blah
# $ update-rc.d blah defaults
# Remove from boot:
# $ update-rc.d -f blah remove

# Options
REPO_PATH=/data/srv/RABBITS/vk
DAEMON=$REPO_PATH/rabbit_server/lib/daemons/vk_notify/vk_notify_daemon.rb
DAEMON_ARGS=
NAME=rabbit-vk-notify # as init.d link name
USER=pav
GROUP=pav

# Do not edit

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
RUNDIR=$REPO_PATH/tmp/pids
PIDFILE=$RUNDIR/$NAME.pid

test -x $DAEMON || exit 0

. /lib/lsb/init-functions

#set -e

case "$1" in
  start)
	echo -n "Starting $NAME: "
	mkdir -p $RUNDIR
	touch $PIDFILE
	chown $USER:$GROUP $RUNDIR $PIDFILE
	chmod 755 $RUNDIR

	if start-stop-daemon --start --quiet --umask 007 --pidfile $PIDFILE --chuid $USER:$GROUP --exec $DAEMON -- $DAEMON_ARGS
	then
		echo "$NAME."
	else
		echo "failed"
	fi
	;;
  stop)
	echo -n "Stopping $NAME: "
	if start-stop-daemon --stop --retry TERM/300/KILL/5 --pidfile $PIDFILE
	then
		echo "$NAME."
	else
		echo "failed"
	fi
	rm -f $PIDFILE
	sleep 1
	;;

  restart|force-reload)
	${0} stop
	${0} start
	;;
  reload)
	echo -n "$NAME reloading "
	if start-stop-daemon --stop --quiet --signal USR1 --pidfile ${PIDFILE}
		then
				echo "reloaded"
		else
				echo "not reloaded"
				exit 1
		fi
		;;

  status)
	echo -n "$NAME is "
	status_of_proc -p ${PIDFILE} "$DAEMON" && exit 0 || exit $?
	;;

  *)
	echo "Usage: /etc/init.d/$NAME {start|stop|restart|reload}" >&2
	exit 1
	;;
esac

exit 0
