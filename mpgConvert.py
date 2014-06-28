#!/usr/local/bin/python
#Frozen [2013]  Soundtrack (Deluxe Edition) (Christophe Beck) YG
#Bon Jovi The Ultimate Collection 2013 [Remastered]
#Coldplay - X & Y
#Elton John The Very Best Of Magic Elton John 2010 [320 Kbps]
#Kylie Minogue - The Best of Kylie Minogue (2012)
#01 Titanium (feat. Sia).mp3
#04 Happy.mp3

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
    cmd = 'avconv  -i "' +  targetfile + '" -acodec mp3 -b 64k -f mp3 "' + \
        outdir + '/' + name + '.mp3"'
#    print cmd
    os.system(cmd)
    
#avconv -i files/ProdigySmackMyBitchUp.wma -acodec mp2 -f mp2  out/file.mp3
#avconv -i files/ProdigySmackMyBitchUp.wma -acodec libvorbis -f ogg -b 128k out/file.ogg

