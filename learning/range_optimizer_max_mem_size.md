# MySQL 5.7 parameter range_optimizer_max_mem_size


MySQL 5.7 (starting with 5.7.9) introduces new parameter “range_optimizer_max_mem_size”. It is possible you will never have need to change it – if you for example do not do some really heavy updates.

But we do – updates over several thousands of records with WHERE clause containing ” id in list_of_ids”. On old MySQL 5.5 it used to run without any problems for several seconds only, using primary index. But when we switched to 5.7 suddenly every one from these huge updates took almost 2 minutes.

When we tried explain plan for small version of such a query there were no problems. You have to really use full version of query with thousands of IDs. Only then you can see problems – although it shows usage of primary index, it also shows “rows” equal to the total number of rows in the table. Which means update is doing full sequential scan of the whole table. Plus it shows there are warnings.

When we issued “show warnings” we got this message:
“Memory capacity of 8388608 bytes for ‘range_optimizer_max_mem_size’ exceeded. Range optimization was not done for this query.”

Problem was solved by adding more memory to the instance to prevent problems with out of memory and setting “range_optimizer_max_mem_size=0” (meaning unlimited). Now our huge updates are back to previous speed – they run for several seconds only and explain plan shows “rows” equal to number of really updated rows.
