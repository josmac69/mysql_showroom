#!/usr/bin/env bash

function echo_log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S.%N"): $1"
}

curdate=$(date +%Y%m%d%H%M)

if [ "$EUID" -ne 0 ]; then
  echo_log "Please run this script as root"
  exit 1
fi

homedir=$( dirname "${BASH_SOURCE[0]}")
cd $homedir
. .env

[ -z "$XTRA_MYSQL_HOST" ] && echo_log "$(basename $0): ERROR: variable XTRA_MYSQL_HOST empty or undefined" && exit 1
[ -z "$XTRA_MYSQL_USER" ] && echo_log "$(basename $0): ERROR: variable XTRA_MYSQL_USER empty or undefined" && exit 1
[ -z "$XTRA_MYSQL_PASS" ] && echo_log "$(basename $0): ERROR: variable XTRA_MYSQL_PASS empty or undefined" && exit 1
[ -z "$XTRA_BACKUP_DIR" ] && echo_log "$(basename $0): ERROR: variable XTRA_BACKUP_DIR empty or undefined" && exit 1

curbackupdir=${XTRA_BACKUP_DIR}/${curdate}
backupfilename=backup${curdate}.tar
curbackuptar=${XTRA_BACKUP_DIR}/${backupfilename}
fortarpacking=${XTRA_BACKUP_DIR}/notreadyyet.tar

echo_log "Current backup dir: ${curbackupdir}"
echo_log "Current backup tar: ${curbackuptar}"
echo_log "tar name for packing: ${fortarpacking}"

echo_log "Starting xtra backup..."
xtrabackup --host=${XTRA_MYSQL_HOST} --user=${XTRA_MYSQL_USER} --backup --target-dir=${curbackupdir} --safe-slave-backup --rsync --parallel=2 --password=${XTRA_MYSQL_PASS}
if [ $? -ne 0 ]; then
  echo_log "$(basename $0): ERROR: xtra backup phase failed"
  echo_log "restarting slave replication on source"
  echo "start slave"|mysql -u ${XTRA_MYSQL_USER} -p${XTRA_MYSQL_PASS}
  exit 1
fi

echo_log "Starting xtra prepare..."
xtrabackup --host=${XTRA_MYSQL_HOST} --user=${XTRA_MYSQL_USER}  --prepare --target-dir=${curbackupdir} --password=${XTRA_MYSQL_PASS}
if [ $? -ne 0 ]; then
  echo_log "$(basename $0): ERROR: xtra prepare phase failed"
  exit 1
fi

echo_log "Starting tar..."
cd ${curbackupdir}
rm ${fortarpacking}
tar cvfz ${fortarpacking} ./
if [ $? -ne 0 ]; then
  echo_log "$(basename $0): ERROR: tar failed"
  exit 1
fi

mv ${fortarpacking} ${curbackuptar}

rm -rf ${curbackupdir}

echo_log "All DONE"
