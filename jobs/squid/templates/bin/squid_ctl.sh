#!/bin/bash -eu

JOB_NAME=squid
source "/var/vcap/packages/squid/common/utils.sh"

JOB_DIR="/var/vcap/jobs/${JOB_NAME}"
RUN_DIR="/var/vcap/sys/run/${JOB_NAME}"
LOG_DIR="/var/vcap/sys/log/${JOB_NAME}"
TMP_DIR="/var/vcap/sys/tmp/${JOB_NAME}"

mkdir -p ${JOB_DIR} ${RUN_DIR} ${LOG_DIR} ${TMP_DIR}
chown -R vcap:vcap ${JOB_DIR} ${RUN_DIR} ${LOG_DIR} ${TMP_DIR}

PIDFILE="${RUN_DIR}/${JOB_NAME}.pid"
export PATH="/var/vcap/packages/${JOB_NAME}/sbin:${PATH}"

exec 1>> ${LOG_DIR}/${JOB_NAME}_ctl.stdout.log
exec 2>> ${LOG_DIR}/${JOB_NAME}_ctl.stderr.log

# shellcheck disable=SC1009,SC1072,SC1073
case $1 in
  start)
    pid_guard "${PIDFILE}" "${JOB_NAME}"
    exec chpst -u vcap:vcap nohup squid -f "$JOB_DIR/config/squid.conf" \
      >> "${LOG_DIR}/${JOB_NAME}.stdout.log" 2>> "${LOG_DIR}/${JOB_NAME}.stderr.log" &
    ;;

  stop)
    kill_and_wait "${PIDFILE}" 180
    ;;

  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;

esac
exit 0
