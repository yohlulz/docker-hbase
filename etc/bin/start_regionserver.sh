#!/usr/bin/env bash

bin=`dirname ${0}`
${bin}/export_dist_mode.sh


function stop_all {
	echo "Stopping regionserver..."
	"$bin"/hbase-daemon.sh --config "${HBASE_CONF_DIR}" stop regionserver
	exit 0
}

if [ "${distMode}" == 'false' ]; then
	exit 0
else
	trap stop_all HUP INT TERM EXIT SIGHUP SIGINT SIGTERM
	echo "Starting regionserver..."

	commandToRun=${commandToRun:-"foreground_start"}
	"$bin"/hbase-daemon.sh --config "${HBASE_CONF_DIR}" --hosts "${HBASE_REGIONSERVERS}" $commandToRun regionserver
fi
