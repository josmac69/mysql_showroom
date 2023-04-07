# Switch the binlog format at runtime


Sources:

* [https://dba.stackexchange.com/questions/6150/what-is-the-safest-way-to-switch-the-binlog-format-at-runtime](https://dba.stackexchange.com/questions/6150/what-is-the-safest-way-to-switch-the-binlog-format-at-runtime)
* [https://dev.mysql.com/doc/refman/5.7/en/binary-log-setting.html](https://dev.mysql.com/doc/refman/5.7/en/binary-log-setting.html)
* [https://www.percona.com/blog/2009/05/14/why-mysqls-binlog-do-db-option-is-dangerous/](https://www.percona.com/blog/2009/05/14/why-mysqls-binlog-do-db-option-is-dangerous/)
* [https://dev.mysql.com/doc/refman/5.5/en/replication-options-binary-log.html#option_mysqld_binlog-do-db](https://dev.mysql.com/doc/refman/5.5/en/replication-options-binary-log.html#option_mysqld_binlog-do-db)

I “inherited” 5.5 master with several 5.5 replicas with replication running for legacy reasons on STATEMENT format. Which of course is not exactly the best setting because STATEMENT based replication can for example cause different IDs on master and replica, different rows returned by query with LIMIT clause and others “funny accidents”…

Another inherited legacy problem was setting of `binlog_do_db` and `replicate_do_db` . These too parameters can be particularly harmful – read [here on Percona](https://www.percona.com/blog/2009/05/14/why-mysqls-binlog-do-db-option-is-dangerous/).

We had more and more problems especially with these too settings due to broad spectrum of applications we are using. Some changes simply were not replicated. Plus due to STATEMENT binloog format on master we had from time to time different data on replicas. Therefore we decided to remove all `*_do_db` settings and switch all instances to ROW binlog format.

We tested solution described in [this description](https://dba.stackexchange.com/questions/6150/what-is-the-safest-way-to-switch-the-binlog-format-at-runtime) and it worked. At the end we needed to restart whole master instance due to maintenance so task was a bit more simple for us.

What we did:

1. Prepared all changes in MySQL config file on master.
2. Locked tables on master – FLUSH TABLES WITH READ LOCK;
3. Stopped replication on all replicas – STOP SLAVE;
4. Restarted master with new configuration
5. Started again all slaves – START SLAVE;

So far everything works and ROW based replication seems to be much quicker then STATEMENT based replication.

Plus – it works between versions too. ROW binlog from MySQL 5.5 works on 5.7 replica.
