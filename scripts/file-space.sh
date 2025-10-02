#!/bin/bash

echo -n "Type the directory "
read DIR
if [[ -z $DIR ]]
then
	echo "Error! Type the directory!"
	exit;
else

echo "-------------------------------"
du -ahx $DIR | sort -rh | head
echo "-------------------------------"
fi
