#!/usr/bin/env python
from gimpfu import *
import sys
import Tkinter
import tkMessageBox
import os
import time

sep = os.path.sep

def do_preprocessing(fileName) :
  #print("do_preprocessing "+fileName)
  sys.stdout.flush()
  theImage = pdb.gimp_file_load(fileName, fileName)
  pdb.gimp_image_undo_enable(theImage)
  theActiveLayer = pdb.gimp_image_get_active_layer(theImage)
  pagedir, filename, fileNo, fileExt = get_filename_parts(fileName)
  selection_op = 2 
  if (fileNo%2 != 0) :
    pdb.gimp_image_rotate(theImage, 1)
    pdb.gimp_rect_select(theImage, 108, 129, 2150, 3120, selection_op, 0, 0)
  else :
    pdb.gimp_rect_select(theImage, 283, 231, 2150, 3120, selection_op, 0, 0)

  displayId = pdb.gimp_display_new(theImage)
  return (theImage, displayId)

def do_postprocessing(theImage, fileName, displayId) :
  #print("do_postprocessing "+fileName)
  sys.stdout.flush()
  nonEmpty, x1, y1, x2, y2 = pdb.gimp_selection_bounds(theImage)
  if (nonEmpty == 1) :
    theActiveLayer = pdb.gimp_image_get_active_layer(theImage)
    x0,y0 = pdb.gimp_drawable_offsets(theActiveLayer)
    pdb.gimp_image_crop(theImage,x2-x1,y2-y1,x1,y1)
  
  pdb.script_fu_guides_remove(theImage, theActiveLayer)
  pagedir, filename, fileNo, fileExt = get_filename_parts(fileName)
  saveFile  = pagedir + sep + str(fileNo).zfill(4) + ".xcf"
  pdb.gimp_xcf_save(0, theImage, theActiveLayer, saveFile, saveFile)
  pdb.gimp_display_delete(displayId)

def get_filename_parts(fileName) :
  pagedir, localName = os.path.split(fileName)
  fileNo, fileExt = os.path.splitext(localName)
  fileNo = int(fileNo)
  return (pagedir, localName, fileNo, fileExt)

def start_pages(firstFile, oneShot) :
  last = 0;
  root = Tkinter.Tk()
  root.wm_withdraw()
  root.attributes('-topmost', 1) # Raising root above all other windows
  root.attributes('-topmost', 0)            

  pagedir, filename, fileNo, fileExt = get_filename_parts(firstFile)

  nextFileLoc = pagedir + sep + str(fileNo).zfill(4) + fileExt
  #print("start file: " + nextFileLoc)
  while os.path.exists(nextFileLoc) :
    #print("file "+firstFile)
    tmpName = str(fileNo).zfill(4)
    theImage, displayId = do_preprocessing(nextFileLoc)
    pdb.gimp_progress_set_text("Ok 'Gimp Continue' popup on file "+tmpName+".")
    time.sleep(1)
    tkMessageBox.showinfo(title="GIMP Continue", message="Adjust selection for page "+
        tmpName +" and OK when complete.")
    do_postprocessing(theImage, nextFileLoc, displayId)
    fileNo += 1
    tmpName = str(fileNo).zfill(4)
    nextFileLoc = pagedir + sep + tmpName + fileExt
    sys.stdout.flush()
    if (oneShot) :
      nextFileLoc = ""

  #print("all done")
  root.destroy()

#Use gimpshelf for persistence across individual script invocation.
#Use parasite for custom data storage in xcf artifacts.

#See /usr/lib/gimp/2.0/python/gimpfu.py
register(
 "python-fu-clip-page",                         #keyboard shortcut
 "Workflow for jpg pages to xcf. Iterates over the jpg\
 files in a directory. The files must be 4 digit eg 0001.jpg.\
 For each file:\n\
 Rotate 180 degrees odd numbered pages.\n\
 Insert a rectangular selector.\n\
 Allow custom adjustment.\n\
 Clip the image to the selection.\n\
 Save the image to an xcf.\n\
 Open the next image.\n\n\
Note: Click on the popup after each file adjustment.\n\
 ",      #tool tip
 "Clean an xcf image.",  #description
 "Daren Isaacs",                                  #author
 "Open source (BSD 3-clause license)",            #licence
 "2020",                                          #year
 "python-fu-clip-page",                         #Label for menu
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
