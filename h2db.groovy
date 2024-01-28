#!/usr/bin/env groovy
//#Run the h2 sq ltool.
@Grab('com.h2database:h2:2.2.224') import org.h2.Driver
import org.h2.tools.Shell
args = new String[8]
args[0]="-url"
//args[1]="jdbc:h2:file:/tmp/dbh2/testdb;FILE_LOCK=NO;IFEXISTS=TRUE;DATABASE_TO_UPPER=FALSE;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1;INIT=SET SCHEMA public;"
//args[1]="jdbc:h2:file:/tmp/dbh2/testdb;MODE=MYSQL"
//args[1]="jdbc:h2:file:./db/test;MODE=HSQLDB"
//args[1]="jdbc:h2:file:/tmp/h2/dataSource;DATABASE_TO_UPPER=FALSE;MODE=MYSQL;FILE_LOCK=NO;DB_CLOSE_ON_EXIT=FALSE"
//Note: both clients must use AUTO_SERVER=TRUE to share the database. 
args[1]="jdbc:h2:file:/tmp/h2/dataSource;DATABASE_TO_UPPER=FALSE;MODE=MYSQL;AUTO_SERVER=TRUE"
//args[1]="jdbc:h2:mem:dataSource;DATABASE_TO_UPPER=FALSE;MODE=strict"
args[2]="-user"
args[3]="sa"
args[4]="-password"
args[5]=""
args[6]="-driver"
args[7]="org.h2.Driver"
org.h2.tools.Shell.main(args)

//  Commands:
//
//    show tables;
//    select current_schema;
//    select current_catalog;
//    @info
//    select * from information_schema.tables;
//    RUNSCRIPT FROM 'create_schema.sql'
