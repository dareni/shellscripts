#!/usr/bin/env groovy
# Run the hsql sqltool and connect to derby.
@Grab('org.hsqldb:sqltool:2.3.3') import org.hsqldb.sqltool.*
@Grab('org.apache.derby:derby:10.11.1.1') import org.apache.derby.jdbc.AutoloadedDriver
args = new String[2]
//args[0]="--inlineRc=url=jdbc:hsqldb:hsql://localhost:9001/xdb,user=SA,password="
args[0]="--inlineRc=url=jdbc:derby:users,user=SA,password="
args[1]="--driver=org.apache.derby.jdbc.AutoloadedDriver"
org.hsqldb.cmdline.SqlTool.main(args)
