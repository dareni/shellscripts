#!/usr/bin/env groovy
#Run the hhsqldb sqltool.
@Grab('org.hsqldb:sqltool:2.3.3') import org.hsqldb.sqltool.*
@Grab('org.hsqldb:hsqldb:2.3.3') import org.hsqldb.jdbc.JDBCDriver
args = new String[1]
//args[0]="--inlineRc=url=jdbc:hsqldb:hsql://localhost:9001/xdb,user=SA,password="
args[0]="--inlineRc=url=jdbc:hsqldb:mem:test,user=SA,password="
org.hsqldb.cmdline.SqlTool.main(args)
