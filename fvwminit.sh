#sudo ~/bin/cpu.sh
xrandr --output DVI-0 --auto --output DVI-1 --auto --right-of DVI-0

#hp Compaq LA2306x
xrandr --newmode "1920x1080_60"  148.50  1920 2008 2052 2200  1080 1084 1089 1125 +hsync +vsync
xrandr --addmode DVI-0 "1920x1080_60"
xrandr --output DVI-0 --mode "1920x1080_60"

#Manufacturer: DEL  Model: f045  Serial#: 1093678412
#Year: 2013  Week: 4
#EDID Version: 1.3
#Digital Display Input
#Max Image Size [cm]: horiz.: 51  vert.: 29

xrandr --newmode "1920x1080 DEL"  148.50  1920 2008 2052 2200  1080 1084 1089 1125 +hsync +vsync
xrandr --addmode DVI-1 "1920x1080 DEL"
xrandr --output DVI-1 --mode "1920x1080 DEL"

#samsung syncmaster 743b
#xrandr --newmode "1280x1024_60.00" 108.88 1280 1360 1496 1712  1024 1025 1028 1060 -HSync +Vsync
#xrandr --addmode DVI-1 "1280x1024_60.00"
#xrandr --output DVI-1 --mode "1280x1024_60.00"


#Lookup /var/log/Xorg.0.log for these settings.
#Samsung syncmaster P2250 xrandr --newmode "1920x1080_60.00"  173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync

#xrandr -newmode "1920x1080_hp" 148.50  1920 2008 2052 2200  1080 1084 1089 1125 +hsync +vsync
#xrandr --addmode VGA-0 "1920x1080_hp"
#xrandr --output VGA-0 --mode "1920x1080_hp"

xhost +192.168.100.11
