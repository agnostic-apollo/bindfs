#!/bin/bash
#title:          android_ndk_cross_compile_build.sh
#description:    NDK cross compile build script for fuse using an autoconf build system	
#author:         agnostic-apollo
#usage:          To be used with `android_ndk_cross_compile_build_automator.sh`.
#date:           1-Aug-2019
#versions:       1.0
#license:        MIT License


#requires fuse to be installed at "$INSTALL_DIR/fuse/$ARCH_SRC"

#The following variables are exported by the android_ndk_cross_compile_build_automator.sh script before calling this script
#ARCH_SRC: The name of the ARCH_SRC this project is being built for
#API_LEVEL: The API_LEVEL this project is being built for, toolchain is already generated for this API level
#ABI_NAME: The abi of the arch this project is being built for
#TARGET_HOST: The host this project should be built for. It should contain any value in "arm-linux-androideabi \
#armv7a-linux-androideabi aarch64-linux-android i686-linux-android x86_64-linux-android mips64el-linux-android \
#mips64el-linux-android"

#PROJECT: The name of the project directory being built
#BUILD_DIR: The absolute path to the parent directory of the project
#INSTALL_DIR: The absolute path to the directory of that can be used as prefix for install commands
#TOOLCHAIN_DIR: The absolute path to the toolchain directory
#SYSROOT: The absolute path to the toolchain SYSROOT directory
#TOOLCHAIN_BIN_DIR: The absolute path to the toolchain bin directory
#The "CPP CC CXX LD AR AS NM RANLIB STRIP" variables are also exported depending on the toolchain

#C_COMPILER: The c compiler of the toolchain. It should contain any value in "gcc clang"
#CXX_COMPILER: The c compiler of the toolchain. It should contain any value in "g++ clang++"
#CFLAGS: The arch specific c compiler flags defined in ARCH_SRC file and any CFLAGS exported \
#before running android_ndk_cross_compile_build_automator.sh script
#CPPFLAGS: The arch specific c++ compiler flags defined in ARCH_SRC file and any CPPFLAGS exported \
#before running android_ndk_cross_compile_build_automator.sh script
#LDFLAGS: The arch specific linker flags defined in ARCH_SRC file and any LDFLAGS exported \
#before running android_ndk_cross_compile_build_automator.sh script


#set an ARCH_SRC that this project cannot be built for
UNSUPPORTED_ARCH_SRC="armeabi-android4.0.4-"

#fuse is compiled with a c compiler, but you will get compilation errors with gcc with ndk older than r15
#Android NDK provides gcc below NDK version 18 and clang in NDK versions greater or equal to 15
#SUPPORTED_C_COMPILER="gcc clang"
SUPPORTED_C_COMPILER="gcc clang"

#Android NDK provides g++ below NDK version 18 and clang++ in NDK versions greater or equal to 15
#SUPPORTED_C_COMPILER="g++ clang++"
SUPPORTED_CXX_COMPILER="g++ clang++"

#set ARCH_SRC for which not to add PIE/PIC flags 
ARCH_SRC_NOT_TO_ADD_PIE_PIC_FLAGS_FOR="armeabi-android4.0.4-"


#if ARCH_SRC is listed in UNSUPPORTED_ARCH_SRC, then exit with non catastrophic exit code $UNSUPPORTED_ARCH_SRC_EXIT_CODE
if [[ "$UNSUPPORTED_ARCH_SRC" =~ (^|[[:space:]])"$ARCH_SRC"($|[[:space:]]) ]]; then
	echo "$PROJECT cannot be built for $ARCH_SRC"
	exit $UNSUPPORTED_ARCH_SRC_EXIT_CODE
fi

#if C_COMPILER is not listed in SUPPORTED_C_COMPILER, then exit with non catastrophic exit code $UNSUPPORTED_C_COMPILER_EXIT_CODE
if [[ ! "$SUPPORTED_C_COMPILER" =~ (^|[[:space:]])"$C_COMPILER"($|[[:space:]]) ]]; then
	echo "$PROJECT cannot be built with $C_COMPILER"
	exit $UNSUPPORTED_C_COMPILER_EXIT_CODE
fi

#if CXX_COMPILER is not listed in SUPPORTED_CXX_COMPILER, then exit with non catastrophic exit code $UNSUPPORTED_CXX_COMPILER_EXIT_CODE
if [[ ! "$SUPPORTED_CXX_COMPILER" =~ (^|[[:space:]])"$CXX_COMPILER"($|[[:space:]]) ]]; then
	echo "$PROJECT cannot be built with $CXX_COMPILER"
	exit $UNSUPPORTED_CXX_COMPILER_EXIT_CODE
fi

fuse_install_path="$INSTALL_DIR/fuse/$ARCH_SRC"

fuse_pc_file_path="$fuse_install_path/usr/local/lib/pkgconfig"
if [ ! -f "$fuse_pc_file_path/fuse.pc" ]; then
	echo "Failed to find fuse.pc file for $PROJECT for $ARCH_SRC at $fuse_pc_file_path"
	exit 1
fi


#bindfs uses a c compiler and needs __ANDROID__ macro to support NDK compilation
#set c compiler specific flags
if [[ "$C_COMPILER" == "gcc" ]]; then
	CPPFLAGS="$CPPFLAGS -D __ANDROID__"
	CFLAGS="$CFLAGS -static -I$fuse_install_path/usr/local/include -I$fuse_install_path/usr/local/include/fuse"
	LDFLAGS="$LDFLAGS -static -static-libgcc -L$fuse_install_path/usr/local/lib"
		:
elif [[ "$C_COMPILER" == "clang" ]]; then
	CPPFLAGS="$CPPFLAGS -D __ANDROID__"
	CFLAGS="$CFLAGS -static -I$fuse_install_path/usr/local/include -I$fuse_install_path/usr/local/include/fuse"
	LDFLAGS="$LDFLAGS -static -static-libgcc -L$fuse_install_path/usr/local/lib"
	:
fi

#bindfs does not use c++ compiler, so not used, just a proof of concept
#set c++ compiler specific flags
if [[ "$CXX_COMPILER" == "g++" ]]; then
	#CPPFLAGS="$CPPFLAGS"
	#CXXFLAGS="$CFLAGS -static"
	#LDFLAGS="$LDFLAGS -static -static-libstdc++"
	:
elif [[ "$CXX_COMPILER" == "clang++" ]]; then
	#CXXFLAGS="$CFLAGS -static"
	#LDFLAGS="$LDFLAGS -static -static-libstdc++"
	:
fi


#executables or libraries built without PIE/PIC flags wont work on android-21 (Android 5.0) or higher
#executables or libraries built with PIE/PIC flags will only work on android-16 (Android 4.1) or higher
#executables or libraries to be run on android-15 (Android 4.0.4) or lower must be built without PIE/PIC flags,
#otherwise there will be runtime failure
#you can use the special ARCH_SRC file for these cases
#currently "armeabi-android4.0.4-" is for this case and can be used possibly with the same flags as "armeabi" other than API_LEVEL

#flags are passed automatically by NDK to clang
#if specific flags are to be added depending on ARCH_SRC
#if ARCH_SRC is not listed in ARCH_SRC_NOT_TO_ADD_PIE_PIC_FLAGS_FOR, then add PIE/PIC flags
if [[ ! "$ARCH_SRC_NOT_TO_ADD_PIE_PIC_FLAGS_FOR" =~ (^|[[:space:]])"$ARCH_SRC"($|[[:space:]]) ]]; then
	#CFLAGS="$CFLAGS -fPIE -fPIC"
	#LDFLAGS="$LDFLAGS -pie"
	:
fi


#cd to project root just in case
cd "$BUILD_DIR/$PROJECT"

#not needed for bindfs, read ahead
#If your autoconf project does not a configure script in the source code then run autoreconf to generate it from configure.ac
#autoreconf -i
#if [ $? -ne 0 ]; then
#	echo "Failure while running autoreconf for $PROJECT for $ARCH_SRC"
#	exit 1
#fi


#export path to fuse.pc file which should have been installed while building the fuse package with NDK
export PKG_CONFIG_PATH="$fuse_pc_file_path"
echo "PKG_CONFIG_PATH = \"$PKG_CONFIG_PATH\""

#run configure command, you can add any additional flags
echo -e "\n\nRunning configure for $PROJECT for $ARCH_SRC"
./configure \
	--host="$TARGET_HOST" \
	--with-sysroot="$SYSROOT" \
	--enable-static=yes \
	"$@"
if [ $? -ne 0 ]; then
	echo "Failure while running configure for $PROJECT for $ARCH_SRC"
	exit 1
fi


#get total cpu/cores
cpus="$(nproc)"
if [ $? -eq 0 ]; then
	make_jobs"-j$cpus"
fi


#you can optionally skip this depending on your project
#but probably might be better to have a clean build directory before building for different archs
#run make clean command
echo -e "\n\nRunning make clean for $PROJECT for $ARCH_SRC"
make $make_jobs clean
if [ $? -ne 0 ]; then
	echo "Failure while running make clean for $PROJECT for $ARCH_SRC"
	exit 1
fi

#run make clean command
echo -e "\n\nRunning make for $PROJECT for $ARCH_SRC"
make $make_jobs
if [ $? -ne 0 ]; then
	echo "Failure while running make clean for $PROJECT for $ARCH_SRC"
	exit 1
fi


project_install_dir_for_arch="$INSTALL_DIR/$PROJECT/$ARCH_SRC"

#run make install command
echo -e "\n\nRunning make install for $PROJECT for $ARCH_SRC"
make $make_jobs DESTDIR="$project_install_dir_for_arch" install
if [ $? -ne 0 ]; then
	echo "Failure while running make install for $PROJECT for $ARCH_SRC"
	exit 1
fi


echo -e "\n\nInstalled at $project_install_dir_for_arch"
echo "Complete"

