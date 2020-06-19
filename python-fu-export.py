#!/usr/bin/env python
from gimpfu import *
import sys
import Tkinter
import tkMessageBox
import os
import time

sep = os.path.sep

def get_filename_parts(fileName) :
  pagedir, localName = os.path.split(fileName)
  fileNo, fileExt = os.path.splitext(localName)
  fileNo = int(fileNo)
  return (pagedir, localName, fileNo, fileExt)

def start_pages(firstFile, oneShot) :
  last = 0;
  pagedir, filename, fileNo, fileExt = get_filename_parts(firstFile)

  nextFileLoc = pagedir + sep + str(fileNo).zfill(4) + fileExt
  print("nextfile: " + nextFileLoc)
  while os.path.exists(nextFileLoc) :
    print("file "+firstFile)
    tmpName = str(fileNo).zfill(4)

    theImage = pdb.gimp_xcf_load(0, nextFileLoc, nextFileLoc)
    theActiveLayer = pdb.gimp_image_get_active_layer(theImage)

    saveFile =  pagedir + sep + tmpName + '.png'
    compression=9
    pdb.file_png_save(theImage, theActiveLayer, saveFile, saveFile, 0, compression, 0, 0, 0, 0, 0)

    fileNo += 1
    tmpName = str(fileNo).zfill(4)
    nextFileLoc = pagedir + sep + tmpName + fileExt
    sys.stdout.flush()
    if (oneShot) :
      nextFileLoc = ""

  print("all done")

#Use gimpshelf for persistence across individual script invocation.
#Use parasite for custom data storage in xcf artifacts.

#See /usr/lib/gimp/2.0/python/gimpfu.py
register(
 "python-fu-export",                         #keyboard shortcut
 "Workflow for xcf page cleanup. Iterates over the xcf\
 files in a directory. The files must be 4 digit eg 0001.xcf.\
 A simple script to save the time of opening\
 and saving many files.",      #tool tip
 "Clean an xcf image.",  #description
 "Daren Isaacs",                                  #author
 "Open source (BSD 3-clause license)",            #licence
 "2020",                                          #year
 "python-fu-export",                         #Label for menu
#prepend <Image><Load><Save><Toolbox>
#or <> will error with the options, also see gimpfu.py
 "",                                              #image type
 [ (PF_FILE, "file", "The file of the first image.", "none"),
   (PF_TOGGLE, "oneshot", "Process just a single file.", 1)
 ],                                              #input parameters
 [                                               #output parameters
 ],
 start_pages,                                     #function callback name
 "<Toolbox>/Custom"                               #menu
)

main()
