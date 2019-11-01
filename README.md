
## Overview ##

bindfs  -  https://bindfs.org/

This repo has been patched to support NDK compilation for android, since some functions are not provided by bionic which are used in `src/userinfo.c`.

bindfs is a FUSE filesystem for mirroring a directory to another
directory, similarly to `mount --bind`. The permissions of the mirrored
directory can be altered in various ways.

Some things bindfs can be used for:
- Making a directory read-only.
- Making all executables non-executable.
- Sharing a directory with a list of users (or groups).
- Modifying permission bits using rules with chmod-like syntax.
- Changing the permissions with which files are created.

Non-root users can use almost all features, but most interesting
use-cases need `user_allow_other` to be defined in `/etc/fuse.conf`.


## Installation ##

Make sure FUSE 2.6.0 or above is installed (https://github.com/libfuse/libfuse).

Download a [release](https://bindfs.org/downloads/) or clone this repository.

Then compile and install as usual:

    ./configure
    make
    make install

If you want the mounts made by non-root users to be visible to other users,
you may have to add the line `user_allow_other` to `/etc/fuse.conf`.

In Linux-based OSes, you may have to add your user to the `fuse` group.


## Usage ##

See the `bindfs --help` or the man-page for instructions and examples.


## OS X note ##

The following extra options may be useful under osxfuse:

    -o local,allow_other,extended_security,noappledouble

See https://github.com/osxfuse/osxfuse/wiki/Mount-options for details.


## Test suite ##

[![Build Status](https://travis-ci.org/mpartel/bindfs.svg?branch=master)](https://travis-ci.org/mpartel/bindfs)

Bindfs comes with a (somewhat brittle and messy) test suite.
The test suite has two kinds of tests: those that have to be run as root and
those that have to be run as non-root. To run all of the tests, do
`make check` both as root and as non-root.

The test suite requires Ruby 1.8.7+. If you're using [RVM](https://rvm.io/)
then you may need to use `rvmsudo` instead of plain `sudo` to run the root
tests.

### Vagrant test runner ###

There is also a set of Vagrant configs for running the test suite on a variety
of systems. Run them with `vagrant/test.rb` (add `--help` for extra options).

You can destroy all bindfs Vagrant machines (but not the downloaded images)
with `make vagrant-clean`.


## Cross Compile Instructions for Android Using NDK ##

- bindfs requires fuse libraries for compilation. fuse compiled with NDK is used for this.

- Follow instructions for [fuse](https://github.com/agnostic-apollo/fuse) but do not build it.

- Copy `bindfs` directory to `android_ndk_cross_compile_build_automator/packages` directory.

- Copy `bindfs/post_build_scripts/bindfs_extractor.sh` file to `android_ndk_cross_compile_build_automator/$POST_BUILD_SCRIPTS_DIR/` directory.

- Add/Set `fuse bindfs` to `$PROJECTS_TO_BUILD` in `android_ndk_cross_compile_build_automator.sh`.

- Add/Set `fusermount_extractor.sh bindfs_extractor.fs` to `$POST_BUILD_SCRIPTS_TO_RUN` in `android_ndk_cross_compile_build_automator.sh`. You can skip this optionally if you do not want to create a zip of the fusermount and bindfs binaries of all the archs that are built.

- Add/Set `armeabi armeabi-v7a arm64-v8a x86 x86-64` to `$ARCHS_SRC_TO_BUILD` in `android_ndk_cross_compile_build_automator.sh` or whatever ARCHS_SRC you want to build for. API_LEVEL in ARCH_SRC files must be 21 or higher otherwise compilation will fail. NDK must also be higher than r15. Check `fuse/android_ndk_cross_compile_build.sh` for more details.

```
#install dependencies
sudo apt install autoconf automake libtool

cd android_ndk_cross_compile_build_automator

#build
bash ./android_ndk_cross_compile_build_automator

```

- `android_ndk_cross_compile_build_automator` will call `fuse/android_ndk_cross_compile_build.sh script` to build and install each ARCHS_SRC. fuse for each ARCHS_SRC will be installed at `android_ndk_cross_compile_build_automator/$INSTALL_DIR/fuse/$ARCHS_SRC`.

- `android_ndk_cross_compile_build_automator` will then call `bindfs/android_ndk_cross_compile_build.sh script` to build and install each ARCHS_SRC. bindfs for each ARCHS_SRC will be installed at `android_ndk_cross_compile_build_automator/$INSTALL_DIR/bindfs/$ARCHS_SRC`.

- `android_ndk_cross_compile_build_automator/$POST_BUILD_SCRIPTS_DIR/fusermount_extractor.sh` will extract `fusermount` binaries from `android_ndk_cross_compile_build_automator/$INSTALL_DIR/fuse/$ARCHS_SRC` and zip them at `android_ndk_cross_compile_build_automator/$OUT_DIR/fuse/fusermount<build-info>.zip`.

- `android_ndk_cross_compile_build_automator/$POST_BUILD_SCRIPTS_DIR/bindfs_extractor.sh` will extract `bindfs` binaries from `android_ndk_cross_compile_build_automator/$INSTALL_DIR/bindfs/$ARCHS_SRC` and zip them at `android_ndk_cross_compile_build_automator/$OUT_DIR/bindfs/bindfs<build-info>.zip`.


## Install Instructions for Termux on Android ##

- Download release zip or copy the zip built from source to your device.

- Extract the binary of your device arch or abi from the zip.
```
#command to find device arch
uname -m

#command to find device abi
getprop ro.product.cpu.abi
```

- Copy the binary to `/data/data/com.termux/files/usr/bin` and then set correct ownership and permissions by running the following commands in a non-root shell. If you run them in a root shell, then binary will only be runnable in a root shell.
```
export scripts_path="/data/data/com.termux/files/usr/bin"; export termux_uid="$(id -u)"; export termux_gid="$(id -g)"; su -c chown $termux_uid:$termux_gid "$scripts_path/bindfs" && chmod 700 "$scripts_path/bindfs";
```


## License ##

GNU General Public License version 2 or any later version.
See the file COPYING.