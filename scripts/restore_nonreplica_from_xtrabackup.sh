#!/usr/bin/env bash

function echo_log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S.%N"): $1"
}

if [ "$EUID" -ne 0 ]; then
  echo_log "Please run this script as root"
  exit 1
fi

homedir=$( dirname "${BASH_SOURCE[0]}")
cd $homedir
. ./.env

#local directory for downloading tar file
[ -z "$XTRA_BACKUP_DIR" ] && echo_log "$(basename $0): ERROR: variable XTRA_BACKUP_DIR empty or undefined" && exit 1

#local mysql home - datadir of MySQL
[ -z "$XTRA_MYSQL_HOME" ] && echo_log "$(basename $0): ERROR: variable XTRA_MYSQL_HOME empty or undefined" && exit 1

#IP of cloning replica with xtrabackup tar files
[ -z "$XTRA_CLONE_IP" ] && echo_log "$(basename $0): ERROR: variable XTRA_CLONE_IP empty or undefined" && exit 1

#remote directory on cloning replica where tar files are stored
[ -z "$XTRA_CLONE_BACKUP_DIR" ] && echo_log "$(basename $0): ERROR: variable XTRA_CLONE_BACKUP_DIR empty or undefined" && exit 1

[ "$XTRA_BACKUP_DIR" == "/" ] && echo_log "$(basename $0): ERROR: variable XTRA_BACKUP_DIR cannot be root" && exit 1

echo_log "===== refresh MySQL non replica using data files ====="
echo_log "checking latest backup on minion clone..."
latestbackup=$(su -c "ssh mysql@${XTRA_CLONE_IP} \"ls -1t ${XTRA_CLONE_BACKUP_DIR}/backup* 2>/dev/null|sort -r|head -1\" " mysql)

if [ -z "${latestbackup}" ]; then
  echo_log "latest backup not found on ${XTRA_CLONE_IP}"
  exit 1
fi

echo_log "found backup ${latestbackup} - starting download..."
backupfile=$(basename ${latestbackup})

su -c "scp mysql@${XTRA_CLONE_IP}:${XTRA_CLONE_BACKUP_DIR}/${backupfile} ${XTRA_BACKUP_DIR}" mysql
if [ $? -ne 0 ]; then
  echo_log "$(basename $0): ERROR: scp from clone failed"
  exit 1
fi
echo_log "backup download done - ${backupfile}"

echo_log "stopping local mysql..."
#in some cases stop with service command does not work - if it happens we must set mysql root password into variable
if [ -z "$XTRA_MYSQL_ROOT_PASS" ]; then
  service mysql stop
else
  mysqladmin -p${XTRA_MYSQL_ROOT_PASS} shutdown
fi

echo_log "waiting for mysqld to stop..."
sleep 30s

echo_log "checking mysqld status..."
stillrunning=$(ps -ef|grep /usr/sbin/mysqld|grep -v grep|wc -l)

if [ $stillrunning -gt 0 ]; then
  echo_log "ERROR: mysqld did not stop..."
  exit 1
fi

echo_log "removing old mysql data files..."
rm -rf ${XTRA_MYSQL_HOME}/*
if [ $? -ne 0 ]; then
  echo_log "$(basename $0): ERROR: cannot delete old local mysql data files"
  exit 1
fi

echo_log "unpacking data files from backup..."
su -c "tar -C ${XTRA_MYSQL_HOME} -zxvf ${XTRA_BACKUP_DIR}/${backupfile}" mysql
if [ $? -ne 0 ]; then
  echo_log "$(basename $0): ERROR: cannot untar backup"
  exit 1
fi

echo_log "removing downloads..."
rm ${XTRA_BACKUP_DIR}/backup*

echo_log "starting mysqld..."
service mysql --full-restart

echo_log "waiting for mysqld to start..."
sleep 30s

echo_log "checking mysqld status..."
isrunning=$(ps -ef|grep /usr/sbin/mysqld|grep -v grep|wc -l)

if [ $isrunning -eq 0 ]; then
  echo_log "ERROR: mysqld did not start..."
  exit 1
fi

echo_log "ALL DONE"
