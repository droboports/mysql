#!/usr/bin/env sh
#
# MySQL service

# import DroboApps framework functions
. /etc/service.subr

framework_version="2.1"
name="mysql"
version="5.6.26"
description="The world's most popular open source database"
depends="apache"
webui="WebUI"

prog_dir="$(dirname "$(realpath "${0}")")"
daemon="${prog_dir}/bin/mysqld"
data_dir="${prog_dir}/data"
apachedaemon="${DROBOAPPS_DIR}/apache/service.sh"
conffile="${prog_dir}/etc/mywebsql.conf"
apachefile="${DROBOAPPS_DIR}/apache/conf/includes/mywebsql.conf"
tmp_dir="/tmp/DroboApps/${name}"
pidfile="${tmp_dir}/pid.txt"
logfile="${tmp_dir}/log.txt"
statusfile="${tmp_dir}/status.txt"
errorfile="${tmp_dir}/error.txt"

# backwards compatibility
if [ -z "${FRAMEWORK_VERSION:-}" ]; then
  framework_version="2.0"
  . "${prog_dir}/libexec/service.subr"
fi

_create_user() {
  if ! id mysql; then
    adduser -S -H -h "${data_dir}" -D -s /bin/false -G nobody -u 40 mysql
  fi
  touch "${pidfile}"
  chmod 664 "${logfile}"
  chown -R mysql "${pidfile}" "${logfile}" "${data_dir}" "${prog_dir}/tmp"
}

start() {
  _create_user
  mkdir -p "${tmp_dir}/sessions"
  cp -vf "${conffile}" "${apachefile}"
  "${apachedaemon}" restart || true
  /sbin/start-stop-daemon -S -x "${daemon}" -b -- --user=mysql --basedir="${prog_dir}" --datadir="${data_dir}" --pid-file="${pidfile}" --log-error="${logfile}" --init-file="${data_dir}/.root.sql"
}

stop() {
  rm -vf "${apachefile}"
  "${apachedaemon}" restart || true
  /sbin/start-stop-daemon -K -x "${daemon}" -p "${pidfile}" -v
}

force_stop() {
  rm -vf "${apachefile}"
  "${apachedaemon}" restart || true
  /sbin/start-stop-daemon -K -s 9 -x "${daemon}" -p "${pidfile}" -v
}

# boilerplate
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
STDOUT=">&3"
STDERR=">&4"
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o xtrace   # enable script tracing

main "${@}"
