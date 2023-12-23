#!/usr/bin/env groovy
//#Run the h2 sq ltool.
@Grab('com.h2database:h2:2.1.214') import org.h2.Driver
import org.h2.tools.Shell
args = new String[8]
args[0]="-url"
//args[1]="jdbc:h2:file:/tmp/dbh2/testdb;FILE_LOCK=NO;IFEXISTS=TRUE;DATABASE_TO_UPPER=FALSE;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1;INIT=SET SCHEMA public;"
//args[1]="jdbc:h2:file:/tmp/dbh2/testdb;MODE=MYSQL"
args[1]="jdbc:h2:file:./test1"
args[2]="-user"
args[3]="sa"
args[4]="-password"
args[5]="123"
args[6]="-driver"
args[7]="org.h2.Driver"
org.h2.tools.Shell.main(args)
