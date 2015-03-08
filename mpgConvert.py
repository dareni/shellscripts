#!/usr/local/bin/python
# Maintained at: git@github.com:dareni/shellscripts.git

import os
from sys import argv

def displayError():
    print 'Usage: mpgConvert.py [infile]|[indir] outdir [bitrate]'
    print 'Example:  mpgConvert.py ./song.mp3  /tmp 64k'
    print 'Example:  mpgConvert.py /songs /tmp/songs 64k'
    print 'Default bitrate=128k'

if len(argv) < 3 or len(argv) > 4:
    displayError()
    raise Exception('Incorrect usage, please specify parameters.')

target = argv[1]
outdir = argv[2]
bitrate = '128k'
print len(argv)
if len(argv) == 4:
    bitrate = argv[3]
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
    displayError()
    raise Exception('Outdir is not a directory.')

for targetfile in files:
    filename = os.path.basename(targetfile)
    name, extension = os.path.splitext(filename)
    cmd = 'avconv  -i "' +  targetfile + '" -b "' + bitrate + '" -f mp3 "' + \
        outdir + '/' + name + '.mp3"'
    print cmd
    os.system(cmd)

#avconv -i in.wma -acodec mp2 -f mp2  out/file.mp3
#avconv -i in.wma -acodec libvorbis -f ogg -b 128k out/file.ogg

