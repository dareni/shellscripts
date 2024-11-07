#!/usr/bin/env python
# Maintained at: git@github.com:dareni/shellscripts.git
from sys import argv
import os
import logging

#logging.basicConfig(level=logging.DEBUG)
inc = 0x800
#sink = "alsa_output.pci-0000_00_1b.0.analog-stereo"
#sink = "alsa_output.pci-0000_00_1b.0"
#sink = os.popen('pacmd dump|grep set-default-sink').read().split(" ")[1]
pacmd = 'pactl'

def getSetting(sink, cmd):
    command = pacmd + ' ' + cmd + ' ' + sink
    logging.debug('command::::' + command)
    resultList = os.popen(command).read()
    logging.debug("result::::: " + resultList)
    return resultList .rsplit(" ")

def setSetting(sink, cmd,  value):
    command = pacmd + ' ' + cmd + ' ' + sink + ' ' + str(value)
    logging.debug('command::::' + command)
    result = os.popen(command).read()

if len(argv) == 2:
    sink = os.popen(pacmd + ' get-default-sink').read().strip()
    option = argv[1]
    if option == 'plus':
        result = getSetting(sink, 'get-sink-volume')
        volume = int(result[2], 10)
        logging.debug("volume::::: " + str(volume))
        volume += inc
        if volume > 0x10000:
            volume = 0x10000
        setSetting(sink, 'set-sink-volume', volume)
    elif option == 'minus':
        result = getSetting(sink, 'get-sink-volume')
        volume = int(result[2], 10)
        volume -= inc
        if volume < 0:
            volume = 0x0
        setSetting(sink, 'set-sink-volume', volume)
    elif option == 'mute':
        result = getSetting(sink, 'get-sink-mute')
        if result[1].rstrip() == 'yes':
            value = '0'
        else:
            value = '1'
        setSetting(sink, 'set-sink-mute', value)
else:
    print("usage pa-vol.py plus | minus | mute")
