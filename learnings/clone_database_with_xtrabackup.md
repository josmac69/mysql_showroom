# Clone database with Percona xtrabackup


Links:

* [https://www.percona.com/doc/percona-xtrabackup/LATEST/installation/apt_repo.html](https://www.percona.com/doc/percona-xtrabackup/LATEST/installation/apt_repo.html)
* [https://www.percona.com/doc/percona-xtrabackup/LATEST/howtos/setting_up_replication.html](https://www.percona.com/doc/percona-xtrabackup/LATEST/howtos/setting_up_replication.html)

Steps:

* try to switch `mysql` user using `sudo su mysql`

  * if it does not work you will have to make changes in your `/etc/passwd` file
  * check your MySQL datafile:| 1 | `grep datadir /etc/mysql/* -r` |
    | - | -------------------------------- |
  * check line for mysql user in /etc/passwd:
    * from line like this: mysql❌116:125:MySQL Server,,,:/nonexistent:/bin/false
    * to like like this (you will have to change home dir and shell): mysql❌116:125:MySQL Server,,,:/var/lib/mysql:/bin/bash
* switch to some sudoer user
* create backup on running source MySQL database:

  | 1 | `sudo xtrabackup --user=your_db_superuser --backup --target-dir=/your/path/tobackup --safe-slave-backup --rsync --parallel=4 --password=your_db_password` |
  | - | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |

  * I tested it under mysql user and it repeatedly failed – so `sudo` seems to be necessary
  * requires db super user
  * contains “safe-slave-backup” option in case this database is a replica
  * backup can run in parallel – copies files in parallel (does not do any dump)
  * sync of file is done using “rsync” to speed it up
  * in target directory creates all files with “root:root” owner so you will have to change owner later
* Apply changes done on database during copying (e.g. “prepare backup”):

  | 1 | `sudo xtrabackup --user=your_db_superuser --prepare --target-dir=/your/path/tobackup --password=your_db_password` |
  | - | ------------------------------------------------------------------------------------------------------------------- |
* change owner:

  | 1 | `chown mysql:mysql /path/to/yourbackup` |
  | - | ----------------------------------------- |
* your hot backup is now ready to be shipped to some other database
* you can save space and network bandwidth by compressing the backup
* tar + compress:

  | 1 | `tar cvfz /your/path/tobackup/backupfile.tar ./` |
  | - | -------------------------------------------------- |
* do not forget to STOP MySQL on your target machine before you will manipulate with data files using `sudo service mysql stop`
* or you can just copy backuped files under `mysql` usert into target instance using:

  | 1 | `find /your/path/tobackup -print \| parallel -v -j8 rsync -dvzpogXuEtS -e ssh --progress {} mysql@xxx.xxx.xxx.xxx:{}` |
  | - | ----------------------------------------------------------------------------------------------------------------------- |

  * if you cannot connect to the remote `mysql` user you will have to
    * make the same changes in `/etc/passwd` file on the remote machine
    * on your backup machine generate ssh key using `ssh-keygen`
    * insert your public ssh key into `~/.ssh/authorized_keys` on your remote machine
