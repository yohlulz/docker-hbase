#!/usr/bin/env bash

bin=`dirname "${BASH_SOURCE-$0}"`
export bin=`cd "$bin">/dev/null; pwd`
. "$bin"/hbase-config.sh

export distMode=`"$bin"/hbase --config "$HBASE_CONF_DIR" org.apache.hadoop.hbase.util.HBaseConfTool hbase.cluster.distributed | head -n 1`
