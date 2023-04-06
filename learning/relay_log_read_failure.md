# Relay log read failure: Could not parse relay log event entry – binary log is corrupted


We had replication error on one of our replicas:

|  | `Last_Errno: 1594``Last_Error: Relay log read failure: Could not parse relay log event entry. The possible reasons are: the master's binary log is corrupted (you can check this by running 'mysqlbinlog' on the binary log), the slave's relay log is corrupted (you can check this by running 'mysqlbinlog' on the relay log), a network problem, or a bug in the master's or slave's MySQL code. If you want to check the master's binary log or slave's relay log, you will be able to know their names by issuing 'SHOW SLAVE STATUS' on this slave.` |
| - | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |

Solution is described in this article – [MySQL relay log corrupted, how do I fix it? Tried but failed](https://dba.stackexchange.com/questions/53893/mysql-relay-log-corrupted-how-do-i-fix-it-tried-but-failed).

In our case this error happened when someone ran heavy query on that replica which created extremely huge temporary files causing total saturation of the hard disk. MySQL server is able to survive full disk error but in this specific case happened that local copy of bin log on replica was corrupted. Command mysqlbinlog Relay_Master_Log_File showed that bin log on master was OK.

* run SHOW SLAVE STATUS\G
  * note – Master_Host, Master_User, Relay_Master_Log_File, Exec_Master_Log_Pos
* find your master user password
* construct commnad: CHANGE MASTER TO MASTER_HOST=’Master_Host’,MASTER_USER=’Master_User’, MASTER_PASSWORD=’yourpassword’, MASTER_LOG_FILE=’Relay_Master_Log_File’, MASTER_LOG_POS=Exec_Master_Log_Pos;
* run:
  * stop slave;
  * reset slave all;
  * CHANGE MASTER TO MASTER_HOST=’Master_Host’,MASTER_USER=’Master_User’, MASTER_PASSWORD=’yourpassword’, MASTER_LOG_FILE=’Relay_Master_Log_File’, MASTER_LOG_POS=Exec_Master_Log_Pos;
  * start slave;
* check again SHOW SLAVE STATUS\G – everything should be OK now

Command “reset slave all” resets all replication channels.
When you set master log file and position to the last correctly applied values from “show slave status” output all following logs or their parts will be reloaded from the master.
