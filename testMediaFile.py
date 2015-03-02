#!/usr/bin/python
# Maintained at: git@github.com:dareni/shellscripts.git
import os
import time
from sys import argv
from sys import exit

if len(argv) == 1:
    documentation = \
"""
NAME
    testMediaFile.py - test a media file for errors.

SYNOPSIS
    testMediaFile.py *avi
    testMediaFile.py /opt/SG/season1/*avi /opt/SG/season2/*avi
    print "Usage: testMediaFile.py <mplayer media file>.....

DESCRIPTION
    Produce a playback log for media file(s) using mplayer. Each media file 
    is played back at an increased speed (x6). On completion of the play back 
    of each media file the output is scanned for failure key words:

        error, overflow, damage, seek failed

    If a key word exists in the play back output, all the output of the play 
    back of the faulty file is logged for review.
    
NOTES
    mplayer is a dependency.
"""
    print documentation
    exit(0)

###### test_movie_integrity ##################################################
def test_movie_integrity(file):
    command = 'mplayer -speed 100 -ao null -vo null -msglevel all=1 "' + file + '" 2>&1'
    output = os.popen(command).read()

    #Check mplayer output for an error.
    loutput= output.lower()
    if 'error' in loutput or \
        'overflow' in loutput or \
        'damage' in loutput or \
        'seek failed' in loutput: 
        return output

    return ""

###### fix_movie #############################################################

def fix_movie(file):
    command = 'mencoder -forceidx -oac copy -ovc copy "%(file_in)s" -o \
    "%(file_out)s"' % {'file_in': file, 'file_out': file+'__fixed'}
    output = os.popen(command).read()
    return output 

###### main ##################################################################

if len(argv) >= 2:
    for i in range(1, len(argv)):
        movie_filename = argv[i]
        print "=" * 79
        start_label = "== Start " + movie_filename[-45:] + " " + time.asctime()
        print start_label.ljust(79,'=')
        error = test_movie_integrity(movie_filename)
        if len(error) > 0:
            print error
            print "========="
            print "== FIX =="
            print "========="
            log = fix_movie(movie_filename)
            print log
            print "============"
            print "== Result =="
            print "============"
            error = test_movie_integrity(movie_filename+'__fixed')
            if len(error) > 0:
                print error
            else:
                print 'Successful Fix!!'
        end_label = "== End " + movie_filename[-47:] + " " + time.asctime()
        print end_label.ljust(79,'=')
        print "=" * 79
