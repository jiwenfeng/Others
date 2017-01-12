#!/bin/sh

if [ "$1" = "" ] ; then
	echo "Usage:./profile file"
fi

if [ ! -f $1 ] ; then
	echo "'$1' not exist"
fi

rm -rf *.png

valgrind --tool=callgrind $1

for i in `ls callgrind.out.*`
do
	python gprof2dot.py -f callgrind -n10 -s $i > $i.dot
	dot -Tpng $i.dot -o $i.png
	rm -rf $i.dot $i
done
