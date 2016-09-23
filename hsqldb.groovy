#!/usr/bin/env groovy
//#Run the hhsqldb sqltool.
@Grab('org.hsqldb:sqltool:2.3.3') import org.hsqldb.sqltool.*
@Grab('org.hsqldb:hsqldb:2.3.3') import org.hsqldb.jdbc.JDBCDriver
args = new String[1]
//args[0]="--inlineRc=url=jdbc:hsqldb:hsql://localhost:9001,user=SA"
//args[0]="--inlineRc=url=jdbc:hsqldb:file:/var/db/test,user=SA"
args[0]="--inlineRc=url=jdbc:hsqldb:hsql://localhost/test,user=sa"
//args[0]="test"
org.hsqldb.cmdline.SqlTool.main(args)
