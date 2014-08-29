#!/usr/local/bin/python

import os
from sys import argv

if len(argv) <> 3:
    print 'Usage: mpgConvert.py infile/dir outdir [bitrate]'
    print 'Example:  mpgConvert.py ./song.mp3  /tmp 64k'
    print 'Default bitrate=128k'
    exit
    raise Exception('Incorrect usage.')

target = argv[1]
outdir = argv[2]
bitrate = '128kb'
if len(argv) == 3:
    bitrate = argv[2]
    files = []
if os.path.isfile(target):
    files = [target]
elif os.path.isdir(target):
    files = os.listdir(target)
    adjFiles = []
    for song in files:
        adjFiles.append(target + '/' + song)
    files = adjFiles 
    
if not os.path.isdir(outdir):
    os.system('mkdir ' + outdir)

for targetfile in files:
    filename = os.path.basename(targetfile)
    name, extension = os.path.splitext(filename)
    cmd = 'avconv  -i "' +  targetfile + '" -b "' + bitrate + '" -f mp3 "' + \
        outdir + '/' + name + '.mp3"'
    os.system(cmd)
    
#avconv -i in.wma -acodec mp2 -f mp2  out/file.mp3
#avconv -i in.wma -acodec libvorbis -f ogg -b 128k out/file.ogg

