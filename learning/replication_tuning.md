# MySQL replication troubleshooting – Lags on replicas


Problem we had with replication:

Replicas sometimes showed older “Read_Master_Log_Pos” then actual position on master. It looked like they do not know about changes on master. And replication delay was up to 1 hour. Only after this time they synchronized with master again.

Problem was caused by network:

* replicas disconnected from master because of too many unsuccessful connection attempts
* default value of “max_connect_errors” is 10 which can be too small if only connections on master are from replicas
* mysql blocks wrong connections after reaching this value
* default setting for “slave_net_timeout” is 3600 second – which means if connection is broken replica will check for changes on master only after this time
* so it is reasonable to set “slave_net_timeout” to much lower value like 30 second
* if you see in error log too many problems with connections is is reasonable to try “skip-name-resolve”, “skip-host-cache” setting in etc/mysql/my.cnf file
