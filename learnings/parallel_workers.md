# Settings for parallel replication workers


We currently (2018/04) run several MySQL 5.7.25 replicas with parallel replication workers. Over time there were huge changes in load on replicas so I had to adjust settings several times to keep up with changes and correct always newly occurring replication lags. So I want to summarize my experiences with these tuning – maybe someone else could take some inspiration from it.

* slave_parallel_type – we have only one database so “LOGICAL_CLOCK” is the right value for us
* slave_parallel_workers – we started on 4 and are currently on 24 – so never take anything for “overkill” – values must be tested – do not rely just on someone’s opinion
* innodb_thread_concurrency – we use currently “0” for unlimited concurrency, but value depends entirely on load on specific replica – for some other project I had to limit concurrency to some reasonable value in dependency on number of CPU cores, otherwise there were situations when all CPUs have been totally overloaded with running queries
* innodb_concurrency_tickets – this is important setting, read about it in documentation – some operations could require a lot of “concurrency tickets” – you can check it using query: “select * from INFORMATION_SCHEMA.INNODB_TRX where trx_concurrency_tickets > 0” – currently we use value 50000
* innodb_lock_wait_timeout – very important setting for parallel replication workers especially if you have a lot of concurrent transactions and workers can encounter conflicting locks and would have to wait – we currently use 240
* slave_transaction_retries – setting related to previous parameter – shows maximum number of retries for workers in case of conflicts – how many times shall worker repeat attempt – we currently use value 50
* range_optimizer_max_mem_size – this is not exactly setting necessary for replication but wrong value can slow down very significantly your queries and it can also cause replication lags due to locks – we currently use “0” for “no limit”
* innodb_temp_data_file_path – this can be “life saving” setting if users use heavy queries which require usage of temporary tablespace. If you do not limit size of temp tablespace it can grow without limits, consume all remaining disk space and although MySQL can survive this situation very well, replication will of course stop. Which can cause lags many hours long and you could have huge problems to recover replicas from it. Setting looks like this – innodb_temp_data_file_path = ibtmp1:12M:autoextend:max:100G – i.e. max size in this example is 100GB
* read_only=ON – otherwise you will see replication error due to data conflicts if for example some developer changes some data etc.
* binlog_format=ROW – quickest variant for our environment
* slave_preserve_commit_order=1 – to ensure consistent status of data on replicas
* slave_compressed_protocol=ON – speeds significantly transfer of binlogs from master
* slave_pending_jobs_size_max – if replication contains some huge operations and this setting is too low (default is 16MB which is not much) then it can slower down workers very significantly, because huge changes must wait until query is empty – we currently use 1GB
* slave_checkpoint_period – how often replica issues checkpoints – default value 300 (milliseconds) was too small for our environment – currently we use value 1500
* max_allowed_packet, slave_max_allowed_packet – these setting can we very sensitive for you but depends on load etc. so you must read about it and test it

Update 2019-07-01:

* Previously mentioned settings helped a lot – replicas still had replication lags when we imported huge amounts of data but recovered from then fairly quickly. But lately we started to import much more data to the master and all that continuously. And with that change our replicas fell behind and gather still bigger and bigger lags.
* After many tests we had to change some other MySQL parameters – some of them could actually compromise data consistency in case of crash of some replica. But we did not have crash of any replica in several months and we can create new replica very quickly by using disk snapshot and backup done on master by Percona XtraBackup tool.
* New settings:

> back_log=750
> query_cache_size=0
> innodb_flush_log_at_trx_commit=2
> thread_cache_size=200
> innodb_flush_log_at_timeout=1800
> binlog_group_commit_sync_delay=50
> innodb_thread_sleep_delay=0

Update 2019-07-09:

* Our replica used for staging got overloaded with tests which caused skyrocketing replication lags even with improved settings – processlist was showing a lot of “system locks”. Therefore I fiddled once again with setting and change in “sync_binlog” from 1 up to 300 made real difference
