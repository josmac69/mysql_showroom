# How to handle errcode 28 – no space left


You can see “Errcode: 28 – No space left” in MySQL error.log for several reasons. In the past when DBAs usually lived without monitoring it could “really surprised” them that disk was full one day… 🙂

In these days I think everyone uses some kind of monitoring so steady growth of database(s) is not so surprising anymore. On the other hand we can relatively more often see quick spikes in disk usage due to some “heavy” or “bad” query. Meaning query which returns so huge result set so it forces MySQL to create huge temporary files. In such case MySQL can consume disk space relatively “very quickly”. Depends of course on remaining disk space.

Worst case scenario is when someone starts “really heavy query” in the evening presuming he/she finds results ready in the morning. In such case you will face full disk error during the night…

Good news is – MySQL is (usually) able to handle this situation without crash. It simply blocks session(s) which cause this error. This is much better behavior than what PostgreSQL does. It simply crashes which can cause corrupted data or even corrupted transaction or commit log. Which can be very bad….

Bad news is – MySQL can stay in this “no space left” error for hours without doing anything. At least not doing any inserts/ updates or applying replication changes. On the other hand “normal small selects” can work without any problems because they are usually done only in memory.

If situation happens you have only 2 options:

* restart the whole MySQL database (sudo service mysql stop / start) – which can actually be a huge problem on production environment…
* kill session causing this situation using KILL command
  * try to identify query using commands like:
    * show full processlist
    * select * from information_schema.processlist
  * check result:
    * Older versions of MySQL (like 5.5) showed in processlist in STATE column text “Copying to tmp table on disk”. So identification of “guilty” session was quite simple.
    * Latest version 5.7 shows in processlist.STATE only text “Sending data”. So identification is more complicated if you see more queries with this STATE.
  * If you are not sure try to look into MySQL error.log. You may see row like this one:
    * 201x-xx-xxThh:mm:02.039839Z 6847100 [Note] Aborted connection 6847100 to db: ‘mydb’ user: ‘reader’ host: ‘xx.xx.xx.xx’ (Error writing file ‘/tmp/MYKwGO7j’ (Errcode: 28 – No space left )
    * here you can see ID of connection
