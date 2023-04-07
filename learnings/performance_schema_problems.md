# Problems with remote login into MySQL caused by performance_schema tables


If you cannot make remote connection into MySQL and you get errors like:

* Table ‘performance_schema.session_variables’ doesn’t exist
* Native table ‘performance_schema’.’session_variables’ has the wrong structure

or something similar connected with performance_schema tables it means that schema is damaged. To repair it you need to ssh machine/ instance and run following commands (MySQL root password is requires):

* sudo mysql_upgrade -u root -p –force
* sudo service mysql restart

If “mysql_upgrade” give you error like this:
`mysql_upgrade: [ERROR] 1010: Error dropping database (can’t rmdir ‘./performance_schema/’, errno: 17)` go into MySQL datadir and delete manually this subdirectory (“rm -rf performance_schema”). After it update will be successful.

Links:

* [https://stackoverflow.com/questions/31967527/table-performance-schema-session-variables-doesnt-exist](https://stackoverflow.com/questions/31967527/table-performance-schema-session-variables-doesnt-exist)
* [https://stackoverflow.com/questions/32000911/errornative-table-performance-schema-has-the-wrong-structure](https://stackoverflow.com/questions/32000911/errornative-table-performance-schema-has-the-wrong-structure)
