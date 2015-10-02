#!/bin/sh
# Thanks to Jan Tomka <Jan.Tomka@gmail.com>
vimdifff() { vim - -c ":vnew $1 |windo diffthis"; }
co -p $1 | vimdifff $1
