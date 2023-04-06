# Investigation of locks on MySQL tables


Lately we experienced huge lags on one of our replica. Therefore I had to check queries and locks on tables.

Sources:

* [Show all current locks from get_lock](https://stackoverflow.com/questions/11034504/show-all-current-locks-from-get-lock)
* 

Activate performance_schema.metadata_locks:

* activate without restart:

|  | `UPDATE performance_schema.setup_instruments``SET enabled = 'YES'``WHERE name = 'wait/lock/metadata/sql/mdl';` |
| - | ---------------------------------------------------------------------------------------------------------------- |

* in config file: `performance_schema_instrument = 'wait/lock/metadata/sql/mdl=ON'`
* see locks: `SELECT * FROM performance_schema.metadata_locks`

Queries statistics:

`select<br/>THREAD_ID, SOURCE, EVENT_NAME,<br/>timer_wait/1e12 as duration_sec,<br/>lock_time/1e12 as lock_time_sec,<br/>CURRENT_SCHEMA,<br/>SQL_TEXT,<br/>ROWS_EXAMINED<br/>from performance_schema.events_statements_history<br/>order by timer_wait desc;`

Will show you longest queries and number of rows examined by them. This is very useful for investigation.

Blocking logs:

`SELECT<br/>r.trx_id waiting_trx_id,<br/>r.trx_mysql_thread_id waiting_thread,<br/>r.trx_query waiting_query,<br/>b.trx_id blocking_trx_id,<br/>b.trx_mysql_thread_id blocking_thread,<br/>b.trx_query blocking_query<br/>FROM information_schema.innodb_lock_waits w<br/>INNER JOIN information_schema.innodb_trx b<br/>ON b.trx_id = w.blocking_trx_id<br/>INNER JOIN information_schema.innodb_trx r<br/>ON r.trx_id = w.requesting_trx_id;`

Show locked tables:

`show open tables where In_Use > 0 ;`
