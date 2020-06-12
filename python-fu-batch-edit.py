#!/usr/bin/env python
from gimpfu import *
import sys
import Tkinter
import tkMessageBox
import os
import time

sep = os.path.sep

def do_preprocessing(fileName) :
  print("do_preprocessing "+fileName)
  theImage = pdb.gimp_xcf_load(0, fileName, fileName)
  pdb.gimp_image_undo_enable(theImage)
  theActiveLayer = pdb.gimp_image_get_active_layer(theImage)
  operation = 2 
  displayId = pdb.gimp_display_new(theImage)
  return (theImage, displayId)

def do_postprocessing(theImage, fileName, displayId) :
  print("do_postprocessing "+fileName)
  theActiveLayer = pdb.gimp_image_get_active_layer(theImage)
  pdb.script_fu_guides_remove(theImage, theActiveLayer)
  pdb.gimp_xcf_save(0, theImage, theActiveLayer, fileName, fileName)
  pdb.gimp_display_delete(displayId)

def get_filename_parts(fileName) :
  pagedir, localName = os.path.split(fileName)
  fileNo, fileExt = os.path.splitext(localName)
  fileNo = int(fileNo)
  return (pagedir, localName, fileNo, fileExt)

def start_pages(firstFile, oneShot) :
  last = 0;
  window = Tkinter.Tk()
  window.wm_withdraw()
  pagedir, filename, fileNo, fileExt = get_filename_parts(firstFile)

  nextFileLoc = pagedir + sep + str(fileNo).zfill(4) + fileExt
  print("nextfile: " + nextFileLoc)
  while os.path.exists(nextFileLoc) :
    print("file "+firstFile)
    tmpName = str(fileNo).zfill(4)
    theImage, displayId = do_preprocessing(nextFileLoc)
    pdb.gimp_progress_set_text("Ok 'Gimp Continue' popup on file "+tmpName+".")
    time.sleep(1)
    tkMessageBox.showinfo(title="Gimp Continue", message="Edit page "+
        tmpName +" and ok when complete.")
    do_postprocessing(theImage, nextFileLoc, displayId)
    fileNo += 1
    tmpName = str(fileNo).zfill(4)
    nextFileLoc = pagedir + sep + tmpName + fileExt
    sys.stdout.flush()
    if (oneShot) :
      nextFileLoc = ""

  print("all done")
  window.destroy()

#Use gimpshelf for persistence across individual script invocation.
#Use parasite for custom data storage in xcf artifacts.

#See /usr/lib/gimp/2.0/python/gimpfu.py
register(
 "python-fu-batch-edit",                         #keyboard shortcut
 "Workflow for xcf page cleanup. Iterates over the xcf\
 files in a directory. The files must be 4 digit eg 0001.xcf.\
 A simple script to save the time of opening\
 and saving many files.",      #tool tip
 "Clean an xcf image.",  #description
 "Daren Isaacs",                                  #author
 "Open source (BSD 3-clause license)",            #licence
 "2020",                                          #year
 "python-fu-batch-edit",                         #Label for menu
#prepend <Image><Load><Save><Toolbox> 
#or <> will error with the options, also see gimpfu.py
 "",                                              #image type
 [ (PF_FILE, "file", "The file of the first page", "none"),
   (PF_TOGGLE, "oneshot", "Process just a single file.", 1)
 ],                                              #input parameters
 [                                               #output parameters
 ],
 start_pages,                                     #function callback name
 "<Toolbox>/Custom"                               #menu
)

main()
