#! /bin/sh

# Download prerequisites needed by gcc and install.
# Run this from the top level of the gcc source tree.
# Run this as root

#apt-get update || exit 1
#apt-get -y install build-essential manpages-dev || exit 1

GCC=gcc-13.2.0
# Necessary to build GCC.
M4=m4-1.4.17
MPFR=mpfr-4.2.1
GMP=gmp-6.3.0
MPC=mpc-1.3.1

DIR=dependence

if [ ! -f $GCC.tar.gz ]; then
	wget https://ftp.gnu.org/gnu/gcc/$GCC/$GCC.tar.gz
	tar xvf $GCC.tar.gz
fi

cd $GCC

if [ ! -d $DIR ] ; then
	mkdir $DIR
fi

cd $DIR

Install()
{
	echo "Now Install $2"
	filename=${1##*/}
	if [ ! -f $filename ] ; then
		wget $1 --no-check-certificate ||  exit 1
	fi
	if [ ! -d $2 ] ; then
		tar xvf $filename || exit 1
	fi
	cd $2
	./configure --prefix=/usr/local/ && make && make install || exit 1
	echo "$2 Installed Finish"
	cd ..
}

# Install M4
if [ ! -f /usr/local/bin/m4 -a ! -f /usr/bin/m4 ] ; then
	Install http://ftp.gnu.org/gnu/m4/$M4.tar.xz $M4
fi

# Install GMP
if [ ! -f /usr/local/lib/libgmp.a -a ! -f /usr/lib/libgmp.a ] ; then
	Install https://ftp.gnu.org/gnu/gmp/$GMP.tar.bz2 $GMP
fi

# Install MPFR
if [ ! -f /usr/local/lib/libmpfr.a -a ! -f /usr/lib/libmpfr.a ] ; then
Install https://ftp.gnu.org/gnu/mpfr/$MPFR.tar.bz2 $MPFR
fi


# Install MPC
if [ ! -f /usr/local/lib/libmpc.a -a ! -f /usr/lib/libmpc.a ] ; then
	Install https://ftp.gnu.org/gnu/mpc/$MPC.tar.gz $MPC
fi

ldconfig

cd ..

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/

echo `pwd `
echo "Now Install GCC"
./configure --with-gmp --with-mpfr --with-mpc --prefix=/usr/local/ --disable-multilib --enable-checking=release --enable-languages=c,c++ && make -j2 && make install || exit 1
rm -rf $DIR

echo "All Installed Finish"
