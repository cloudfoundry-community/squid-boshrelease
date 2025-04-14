#!/bin/bash -eu

JOB_NAME=squid_exporter
source "/var/vcap/packages/squid_exporter/common/utils.sh"

JOB_DIR="/var/vcap/jobs/${JOB_NAME}"
RUN_DIR="/var/vcap/sys/run/${JOB_NAME}"
LOG_DIR="/var/vcap/sys/log/${JOB_NAME}"
TMP_DIR="/var/vcap/sys/tmp/${JOB_NAME}"

mkdir -p ${JOB_DIR} ${RUN_DIR} ${LOG_DIR} ${TMP_DIR}
chown -R vcap:vcap ${JOB_DIR} ${RUN_DIR} ${LOG_DIR} ${TMP_DIR}

PIDFILE="${RUN_DIR}/${JOB_NAME}.pid"
export PATH="/var/vcap/packages/${JOB_NAME}/bin:${PATH}"

exec 1>> ${LOG_DIR}/${JOB_NAME}_ctl.stdout.log
exec 2>> ${LOG_DIR}/${JOB_NAME}_ctl.stderr.log

# shellcheck disable=SC1009,SC1072,SC1073
case $1 in
  start)
    pid_guard "${PIDFILE}" "${JOB_NAME}"
    exec chpst -u vcap:vcap nohup squid_exporter \
      -listen="<%= p('squid_exporter.host') %>:<%= p('squid_exporter.port') %>" \
      <% if_p('squid_exporter.metrics_path') do |val| %> -metrics-path="<%= val %>" <% end %> \
      <% if_p('squid_exporter.squid_hostname') do |val| %> -squid-hostname="<%= val %>" <% end %> \
      <% if_p('squid_exporter.squid_port') do |val| %> -squid-port="<%= val %>" <% end %> \
      <% if_p('squid_exporter.squid_login') do |val| %> -squid-login="<%= val %>" <% end %> \
      <% if_p('squid_exporter.squid_password') do |val| %> -squid-password="<%= val %>" <% end %> \
      <% if_p('squid_exporter.squid_pidfile') do |val| %> -squid-pidfile="<%= val %>" <% end %> \
      >> "${LOG_DIR}/${JOB_NAME}.stdout.log" 2>> "${LOG_DIR}/${JOB_NAME}.stderr.log" &
    pid=$!
    echo "$pid" > ${PIDFILE}
    ;;

  stop)
    kill_and_wait "${PIDFILE}" 60
    ;;

  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;

esac
exit 0
