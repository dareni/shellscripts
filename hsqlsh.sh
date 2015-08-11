#!/bin/bash
#Environment config for hsqldb.
groovysh < <((cat <&3; cat </dev/stdin) 3<<EOF
@GrabConfig(systemClassLoader=true)
@Grab('org.hsqldb:hsqldb:2.3.3') import groovy.sql.Sql
sql = groovy.sql.Sql.newInstance("jdbc:hsqldb:mem:database", "sa", "", "org.hsqldb.jdbcDriver")
println sql.firstRow("VALUES (current_timestamp)")
println sql.firstRow("VALUES (now())")
EOF
)

