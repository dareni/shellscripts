#!/usr/bin/python
from sys import argv
import os

inc = 0x800
#sink = "alsa_output.pci-0000_00_1b.0.analog-stereo"
sink = "alsa_output.pci-0000_00_1b.0"

def getSetting(setting):
    command = 'pacmd dump |grep ' + setting + '|grep ' + sink
    resultList = os.popen(command).read()
    return resultList .rsplit(" ")   

def setSetting(setting, sink, value):
    command = 'pacmd ' + setting + ' ' + sink + ' ' + value            
    result = os.popen(command).read()

if len(argv) == 2:
    option = argv[1]
    if option == 'plus':
        result = getSetting('set-sink-volume')
        volume = int(result[2], 16)
        volume += inc
        if volume > 0x10000:
            volume = 0x10000
        setSetting(result[0], result[1], "0x{0:x}".format(volume))
    elif option == 'minus':
        result = getSetting('set-sink-volume')
        volume = int(result[2], 16)
        volume -= inc
        if volume < 0:
            volume = 0x0
        setSetting(result[0], result[1], "0x{0:x}".format(volume))
    elif option == 'mute':
        result = getSetting('set-sink-mute')
        if result[2].rstrip() == 'yes':
            value = 'no'
        else: 
            value = 'yes'
        setSetting(result[0], result[1], value)
else:
    print "usage pa-vol.py plus | minus | mute"            
