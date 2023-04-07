# Experiences with tuning of MySQL 5.7 replicas


Following text summarizes my experiences with tuning of MySQL 5.7 replicas. Results are specific for our environment (instances on Google compute engine – 4 CPUs / 20 GB RAM) and our type of data load. But it can give you some hints about what to look for…

OS:

* I tested in parallel replicas with Debian 9 and Ubuntu 16.04. With purely default settings on OS and MySQL 5.7 database was performing better on Ubuntu.
* When I tuned further thread concurrency, IO concurrency and disk flushing method situation changed – replica with Debian 9 is now generally quicker.

MySQL tuning:

* avoid lags due to network problems:
  * slave_net_timeout=3
  * slave_compressed_protocol=ON
* thread concurrency:
  * slave_preserve_commit_order=1
  * slave-parallel-workers = 16
  * innodb_thread_concurrency=128
  * slave-parallel-type=LOGICAL_CLOCK
  * innodb_purge_threads=16
* IO threads:
  * innodb_read_io_threads=16
    innodb_write_io_threads=16
* buffer pool – 75% of RAM
* DNS switched off (caused lags in replication):
  * skip-host-cache
  * skip-name-resolve
* binlog:
  * binlog_row_image=full
  * binlog_format=ROW
  * binlog_cache_size=1G
  * binlog_stmt_cache_size=1G
* query cache – switched off (will be removed from MySQL anyway):
  * query_cache_type=0
* higher buffers for transactions (specific for our data load):
  * transaction_prealloc_size = 65536
  * transaction_alloc_block_size = 65536
* settings for tmp tables (specific for our data load):
  * tmp_table_size = 2147483648
  * max_heap_table_size = 2147483648
* innodb log settings:
  * innodb_log_buffer_size=512M
* skip gap locks if possible:
  * innodb_locks_unsafe_for_binlog = ON
* flushing method:
  * innodb_flush_method = O_DIRECT
