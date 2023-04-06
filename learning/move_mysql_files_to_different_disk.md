# Move MySQL data files / log files / temp directory to the different disk on Ubuntu / Debian


Based on:

* [How To Move a MySQL Data Directory to a New Location on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-move-a-mysql-data-directory-to-a-new-location-on-ubuntu-16-04)
* [How to change MySQL data directory?](https://stackoverflow.com/questions/1795176/how-to-change-mysql-data-directory)
* [Can not start mysql if the datadir is set to soft link](https://stackoverflow.com/questions/22684791/can-not-start-mysql-if-the-datadir-is-set-to-soft-link)
* [Mysql couldn’t write to /tmp then failed to restart](https://askubuntu.com/questions/442536/mysql-couldnt-write-to-tmp-then-failed-to-restart/557531)
* [MySQL Replication: ‘Got fatal error 1236’ causes and cures](https://www.percona.com/blog/2014/10/08/mysql-replication-got-fatal-error-1236-causes-and-cures/)

You can face this problem:

1. when your data grow too big and your disk is running out of free space
2. when you would need to improve performance by having data files and log files on different disks

**Scenario:**

1. Add new disk(s) / filesystem:

* Configure new disk on your instance / server. Make SURE disks are mounted properly and they are properly added int /etc/fstab table so they will mount properly even after restart. Missing records in fstab or typos will cause big failure !!!

2. Shutdown MySQL:

* If you work on master which has some replicas do first these steps:
  * log into mysql and do:
    * FLUSH TABLES WITH READ LOCK;
    * FLUSH LOGS;
    * 
  * check and save master status:
    * show master status;
    * (technically master status is name and size of current binlog in log file)
  * wait for all replicas to get all binlogs (Percona monitoring is very useful here)
* stop mysql using one of these commands:
  * mysqladmin -u root -p shutdown
  * sudo service mysql stop
* check if mysql daemon really ended – it can take several seconds or dozens of seconds
  * check it using command like:
    * ps -ef|grep mysql

2. If you want to move datafiles:

* check configuration parameter “datadir” in MySQL configfile to be sure about location of the files you want to move
* switch to mysql user using “sudo su mysql” or similar command depending on your Linux distro
  * if this command does not work you have to set proper shell and home directory for mysql user in /etc/passwd file
* under “mysql” user create new directory for data or log files or temp files on the new disk(s)
* under “mysql” user move files + directories to the new location – move the whole directory like “/var/lib/mysql”
* under “root” user create soft link from old location to the new location (or use sudo under some sudoer user – “mysql” by default is not sudoer unless you add it into it)
* in MySQL configuration in /etc/mysql set “datadir” or corresponding variable to the new location
* command like “ln -s /mnt/data/mysql mysql” in /var/lib directory
* but this is just for convenience – it is not enough for MySQL to start with new location – you have to configure appArmor (see below)
* If you wonder why I recommend to make both changes – symlink + changed datadir – MySQL uses in some cases internal lists of files etc. stored in text files. If you make symlink and add it to AppArmor you avoid errors due to these stored informations.

3. Move bin logs and relay logs

* check configuration parameters “relay_log” and “log_bin” to be sure about location of the files you want to move
* if you are reallocating bin logs:
  * copy existing files from /var/log/mysql to the new location
  * change paths in “relay_log” and “log_bin”
* Warning – file “mysql-bin.index” contains list of all existing bin logs with their full paths. So if you do not change content of this file you will see following situation when you start MySQL again:
  * after start MySQL will use file “mysql-bin.index” based on “log_bin” target directory
  * new bin logs will be added with new full path !!
  * old bin logs will be deleted based on their stored full path – so if you do not make any changes, old bin logs will be deleted in old location !!
* The same situation is with the file “mysql-relay-bin.index” and relay bin logs !!

4. Changes in AppArmor configuration

* If you change datadir – configure AppArmor for the new path:
  * | 1 | `sudo vi /etc/apparmor.d/tunables/alias` |
    | - | ------------------------------------------ |
  * append line at the end (with proper paths of course):| 1 | `alias /var/lib/mysql/ -> /mnt/data/mysql/,` |
    | - | ---------------------------------------------- |
* If you change “tmpdir” – you have to add this new path:
  * make change in MySQL config file for “tmpdir”
  * add the same path to the “`/etc/apparmor.d/abstractions/user-tmp`” file in way similar to this (with proper path):
    * | 12 | `owner /home/tmp/**    rwkl,``/home/tmp/            rw,` |
      | -- | ------------------------------------------------------------------------ |
* Restart AppArmor:| 1 | `sudo service apparmor restart` |
  | - | --------------------------------- |

5. Start MySQL

* start tailing MySQL error.log (see path in variable “log_error” in MySQL configfile)
* Start MySQL: sudo service mysql start
* watch messages in error.log
* Check current master status and compare it with old one – there must be continuity.
* Check “show slave status\G” on replica(s)

What can go wrong with replication:

* In some cases it might happen that master will skip to +2 or +3 higher number of binlog and replicas will give you error like this:
  * | 12 | `Last_IO_Errno: 1236``Last_IO_Error: Got fatal error 1236 from master when reading data from binary log: 'Could not find first log file name in binary log index file'` |
    | -- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
* If it happens you just have to set replicas to the new position in master’s binlog (check on master):
  * stop slave;
  * change master to master_log_file=’mysql-bin.000xxx’, master_log_pos=xxx;
  * start slave;
  * show slave status\G

Notes about AppArmor (see on [https://help.ubuntu.com/lts/serverguide/apparmor.html](https://help.ubuntu.com/lts/serverguide/apparmor.html)):

* AppArmor is loaded by default but it is not visible in “ps” output
* To see its status use on of following commands:
  * sudo apparmor_status
  * sudo service apparmor status
