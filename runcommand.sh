#!/usr/bin/env sh
# Used to run commands from a pipe read where all output is redirected.

$1 >>$2 2>&1 &
