# What can happen when you try to use very big VARCHAR columns


If you try to use really big VARCHAR columns like 60000 bytes and try to index it you will see things happening…

* MySQL has internal limit max 65 535 bytes for combined size of all columns in the row (not counting blob and text types). But this works only for `latin1` character set. UTF8 has to reserve 3 bytes per character. So if you try to create such a column on database with UTF8 default char set – you will get error message `Column length too big for column '......' (max = 21845)`
* IF you create such a column with max size MySQL allows you and try to index it you will see error message `specified key was too long; max key length is 3072 bytes`. Size 3072 bytes is “magical limit” in 5.7 for index key prefixes for tables using “dynamic” or “compressed” row format. Otherwise limit is 767 bytes. Check your variable `innodb_default_row_format` for row format and `innodb_large_prefix` for check if you can use bigger limit or not.
