#!/usr/bin/env bash

bin=`dirname ${0}`
${bin}/export_dist_mode.sh


function stop_zookeeper {
	echo "Stopping zookeeper..."
	"$bin"/hbase-daemon.sh --config "${HBASE_CONF_DIR}" stop zookeeper
	exit 0
}

if [ "${distMode}" == 'false' ]; then
	exit 0
else
	trap stop_zookeeper HUP INT TERM EXIT SIGHUP SIGINT SIGTERM
	echo "Starting zookeeper..."

	commandToRun=${commandToRun:-"foreground_start"}
	"$bin"/hbase-daemon.sh --config "${HBASE_CONF_DIR}" $commandToRun zookeeper
fi
