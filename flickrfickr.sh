#!/bin/bash
# Title: flickrfickr.sh
#
# Abstract:
# This script is for the modification of JPEG photos captured by Canon cameras.
#
# Requirements:
# jhead, Matthias Wandel - http://www.sentex.net/~mwandel/jhead/index.html
# exiv2, Andreas Huggel - http://www.exiv2.org
#
# Usage:
# $ flickrfick.sh (original picture.jpg)
#
# Description:
#
# This script deletes the JPEG EXIF info from a target JPEG.
# Then transfers to the target JPEG, the JPEG EXIF information from another unrelated donor JPEG.
# The user is then prompted to use either the system date and time, the original JPEG's date and time, or a user provided date and time.
# 
# Version notes:
#
# In this version, keeping the original JPEG date and time is broken.  The date and time is always that of the donor JPEG, or user provided, or that of the system.
# The flow will be modified as, let date_string=originial JPEG Exif.Photo.DateTimeOriginal before deleting the the EXIF info.  Presenting originial 
#   Exif.Photo.DateTimeOriginal as user's first choice, followed by offering system time and finally the option to make up a new date and time (which will 
#   continue to not be checked for format compliance).
#
# At some point the user's name can be requested to update the Exif.Canon.OwnerName, at this time it is hard coded (and must be 32 ascii characters, 
#   pad with spaces if needed).
# At some point the user's camera serial number can be added requested to update the Exif.Canon.SerialNumber, at this time it is hard coded (and must be 9 
#   ascii characters)
#
# Future/To Do:
# 
# Ask for Owner.
# Ask for Serial.
# Or specify a file to pull from
# make exiv2 do everything so that jhead can be eliminated.
#


# $1, the first CLI variable is picture (make a human readable variable)
picture=$1 

#Set the Owner Name.  Must be 32 ascii characters, pad with spaces if needed
###########12345678901234567890123456789012
OwnerName="Platogarbo                      "

#Set Canon.SerialNumber
SerialNumber="000005098"

#Save the original date and time.  Just from the Exif.Photo.DateTimeOriginal tag.  There are two other tags that should have the same date and time. All will
#   be modified to carry this date and time, when the program finishes.
date_string=$(exiv2 -Pkt "$picture" |grep Exif.Photo.DateTimeOriginal)
date_string=${date_string:(-19)}

echo "Picture date detected as, "$date_string
 
if [ "$date_string" = "" ]; then
#If date_string is null,
#Use system date and time. Put into variable date_string using EXIF comaptible formatting
date_string=$(date +"%Y:%m:%d %T")
echo "No date and time was found in this picture, reverting to " $date_string " as default date."
fi

#Backup the original picture
cp "$picture" "$picture"_backup

#Specify donor picture.
#-not implemented-
#donor_picture="Sundial - Sample Canon 1Ds Mark III.jpg"
donor_picture="Pentax 645D Sample image - ex_04.jpg"

#Blank original picture's exif data
echo Deleting existing EXIF data from picture
exiv2 rm "$picture"

#Copy Exif info from a donor picture to the blanked original
echo Transfering header from donor picture to blanked original.
#Chosen method uses jhead because it is one line and no temporary files need to be created.
#Can this be done with exiv2 in one line?  I am keeping this for convenience.
jhead -te "$donor_picture" "$picture"

#proposed exiv2 transfer EXIF technique.  The extension part makes using this kind of complicated.  This would be easier if exiv2 didn't modify the filename.
#exiv2 ex -ea "$donor_picture"
#exiv2 in "$donor_picture".exv "$picture"
#rm "$picture".exv

# Do we want to change the picture's date while we're at it?  

while : ; do #begin a loop to get user input.
	echo -ne "Use this date, ($date_string) (y/n)? " #ask if we should change picture date and time
	read Confirm_Date #Get a yes on no response from user.
	
	Confirm_Date="$(echo ${Confirm_Date} | tr [:upper:] [:lower:])" # make the answer lower Case
	Confirm_Date=${Confirm_Date:0:1} # Trying to get single letter, y or n, as a response.  I wonder if you can do this in one line.
 
	if [ "$Confirm_Date" = "y" ]; then # answer Yes detected
		echo "Picture will use this date and time." #inform picture date and time
		break #Exit while loop

	elif [ "$Confirm_Date" = "n" ]; then  # answer No detected
		echo "Hit enter to use current date and time ("$(date +"%Y:%m:%d %T")"), or input a new date and time in format, YYYY:MM:DD HH:MM:SS.  Enter with care, input is not checked for format compliance." # intent to change date or keep originial  (one day we'll check validity of date format, but not today.
		read date_string #user want to use this specified date

		if [ "$date_string" = "" ]; then #Nothing, null, blank line entered 
		echo "Using current date and time." #information
		date_string=$(date +"%Y:%m:%d %T")
		break #exit while loop
		fi

	else
		echo "Invalid choice (hint: type either y or n)" #yes or no.  Don't get cute.
	fi
done

#Modifications part
echo -ne "Applying changes "

#Change the date loop
TagDate=(Exif.Image.DateTime
Exif.Photo.DateTimeOriginal
Exif.Photo.DateTimeDigitized)

for (( i = 0 ; i < ${#TagDate[@]} ; i++ ))
do
#TagDate are pulled from the array with each itteration
exiv2 -M "set "${TagDate[$i]}" $date_string" "$picture"
echo -ne "."
done #End of TagDate loop

# read -p "1st break point (remove mo option from cmd line)"

#change the serial number, there maybe more than one (even the lens).
#change the owner name (32 characters pad with spaces if needed)
exiv2 -M "set Exif.Canon.OwnerName                         Ascii         \"$OwnerName\"" "$picture"
echo -ne  "."

# read -p "2nd break point (no \"mo\")"


#change serial number (integer, 9 digits, lead with 0 if needed)
exiv2 -M "set Exif.Canon.SerialNumber                      Long          $SerialNumber" "$picture"
echo -ne  "."

# read -p "3rd break point (now with less mo)"

#Delete thumbnail
exiv2 -dt "$picture"
echo -ne  "."

#read -p "4th break point (was\: exiv2 rm -dt)"

# Kill fields that may have camera traceable info.
# The donor picture needs to have the following fields blanked because they might contain information about the camera.

#easy to add tags to the tag array.  May want to make the tag array program editable at a later date.
TagsToBlank=( Exif.Photo.MakerNote 
Exif.Canon.0x0002 
Exif.Canon.0x000d 
Exif.Canon.0x0013
Exif.Canon.0x0018
Exif.Canon.0x001c
Exif.Canon.0x001f
Exif.Canon.0x0022
Exif.Canon.0x0023
Exif.Canon.0x0024
Exif.Canon.0x0025
Exif.Canon.0x0026
Exif.Canon.0x0028 
Exif.Canon.0x0027
Exif.Canon.0x0093
Exif.Canon.0x0096
Exif.Canon.0x0097
Exif.Canon.0x0098
Exif.Canon.0x0099
Exif.Canon.0x009a
Exif.Canon.0x00a0
Exif.Canon.0x00aa
Exif.Canon.0x00b4
Exif.Canon.0x00e0
Exif.Canon.0x00d0
Exif.Canon.0x4001
Exif.Canon.0x4008
Exif.Canon.0x4009
Exif.Canon.0x4011
Exif.Canon.0x4013
Exif.Photo.UserComment
Exif.Image.GPSTag
Exif.MakerNote.Offset
Exif.MakerNote.ByteOrder )

#TagsToBlank for loop
for (( i = 0 ; i < ${#TagsToBlank[@]} ; i++ ))
do
#TagsToBlank are pulled from the array with each itteration
exiv2 -M "set "${TagsToBlank[$i]}" 0" "$picture"
echo -ne  "."

# read -p "5th break point"


done #End of TagsToBlank loop

# Remove fields that might distort the picture.
# The donor picture need to have the following fields retain original information
TagsToDelete=( Exif.Image.XResolution 
Exif.Image.YResolution 
Exif.Photo.PixelXDimension
Exif.Photo.PixelYDimension
Exif.Thumbnail.JPEGInterchangeFormat
Exif.Thumbnail.JPEGInterchangeFormatLength)

#TagsToDelete for loop
for (( i = 0 ; i < ${#TagsToDelete[@]} ; i++ ))
do
#TagsToBlank are pulled from the array with each itteration
exiv2 -M "del "${TagsToDelete[$i]}" 0" "$picture"
echo -ne  "."

# read -p "6th break point"



done # end of TagsToDelete loop
echo ""
echo "Picture modifications completed."
exiv2 "$picture"

# read -p "7th break point"

exiv2 -Pkyt "$picture" | awk '{ print "set "$0 }' |grep -i -e Owner -e Serial

# read -p "8th break point"
