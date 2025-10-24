#!/bin/env bash

while [ true ]; do ps --cumulative -C "$1" h -o pcpu; sleep 5; done
