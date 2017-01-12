#! /bin/sh

# Download prerequisites needed by gcc and install.
# Run this from the top level of the gcc source tree.
# Run this as root

apt-get update || exit 1
apt-get -y install build-essential manpages-dev || exit 1

# Necessary to build GCC.
M4=m4-1.4.17
MPFR=mpfr-2.4.2
GMP=gmp-4.3.2
MPC=mpc-0.8.1

DIR=dependence

if [ ! -d $DIR ] ; then
	mkdir $DIR
fi

cd $DIR

Install()
{
	echo "Now Install $2"
	filename=${1##*/}
	if [ ! -f $filename ] ; then
		wget $1 ||  exit 1
	fi
	if [ ! -d $2 ] ; then
		tar xvf $filename || exit 1
	fi
	cd $2
	./configure --prefix=/usr/local/ && make -j4 && make install || exit 1
	echo "$2 Installed Finish"
	cd ..
}

# Install M4
if [ ! -f /usr/local/bin/m4 -a ! -f /usr/bin/m4 ] ; then
	Install http://ftp.gnu.org/gnu/m4/$M4.tar.xz $M4
fi

# Install GMP
if [ ! -f /usr/local/lib/libgmp.a -a ! -f /usr/lib/libgmp.a ] ; then
	Install ftp://gcc.gnu.org/pub/gcc/infrastructure/$GMP.tar.bz2 $GMP
fi

# Install MPFR
if [ ! -f /usr/local/lib/libmpfr.a -a ! -f /usr/lib/libmpfr.a ] ; then
	Install ftp://gcc.gnu.org/pub/gcc/infrastructure/$MPFR.tar.bz2 $MPFR
fi


# Install MPC
if [ ! -f /usr/local/lib/libmpc.a -a ! -f /usr/lib/libmpc.a ] ; then
	Install ftp://gcc.gnu.org/pub/gcc/infrastructure/$MPC.tar.gz $MPC
fi

ldconfig

cd ..

export LD_LIBRARY_PAATH=$LD_LIBRARY_PAATH:/usr/local/lib/

echo "Now Install GCC"
./configure --prefix=/usr/local/ --disable-multilib --enable-checking=release --enable-languages=c,c++ && make -j4 && make install || exit 1
rm -rf $DIR
echo "All Installed Finish"
