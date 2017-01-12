#!/bin/sh

if [ "$1" = "" ] ; then
	echo "Usage:./profile.sh file"
	return
fi

if [ ! -f $1 ] ; then
	echo "'$1' not exist"
	return
fi

IMAGE_DIR="profile/image"
DOT_DIR="profile/dot"

if [ ! -d $IMAGE_DIR ] ; then
	mkdir -p $IMAGE_DIR
fi

if [ ! -d $DOT_DIR ] ; then
	mkdir -p $DOT_DIR
fi

valgrind --tool=callgrind --callgrind-out-file=$DOT_DIR/callgrind.out.%p $1 

for i in `ls $DOT_DIR`
do
	python gprof2dot.py -f callgrind -n10 -s $DOT_DIR/$i > $DOT_DIR/$i.dot
	dot -Tpng $DOT_DIR/$i.dot -o $IMAGE_DIR/$i.png
done
