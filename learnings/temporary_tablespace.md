# How to clean or resize the ibtmp1 file in MySQL


Based on “[How to clean or resize the ibtmp1 file in MySQL?](https://stackoverflow.com/questions/41216630/how-to-clean-or-resize-the-ibtmp1-file-in-mysql)”

This is another lesson learned in rather “hard way” – temporary tablespace on one of our instances grew so big we had problems with full disk. Fortunately both Debian and MySQL are quite capable to handle full disk but replication cannot run without free disk space of course.

Documentation does not explicitly says if temporary table space can be emptied during DB run, but based on [Glossary](https://dev.mysql.com/doc/refman/5.7/en/glossary.html#glos_temporary_tablespace) or [Temporary tablespace](https://dev.mysql.com/doc/refman/5.7/en/innodb-temporary-tablespace.html) chapter it looks like no:

`The temporary tablespace is removed on normal shutdown or on an aborted initialization. The temporary tablespace is not removed when a crash occurs. In this case, the database administrator may remove the temporary tablespace manually or restart the server with the same configuration, which removes and recreates the temporary tablespace.`

Only way how to prevent problems with ever growing temporary tablespace is to limit its maximal size. But as far as I can tell this was not indicated as thing necessary to do or at least to be considered when configuring MySQL before start.

So we had to add into MySQL config file line shown below to reasonably limit size of temp tablespace and of course RESTART MySQL:

```
innodb_temp_data_file_path = ibtmp1:12M:autoextend:max:50G
```
