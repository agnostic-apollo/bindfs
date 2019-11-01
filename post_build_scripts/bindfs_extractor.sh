#!/bin/bash
#title:          bindfs_extractor.sh
#description:    Extracts bindfs binaries of all ARCH_SRCs, appended ARCH_SRC to each binary and then zips all the binaries
#author:         agnostic-apollo
#usage:          Copy `bindfs/post_build_scripts/bindfs_extractor.sh` file to `android_ndk_cross_compile_build_automator/$POST_BUILD_SCRIPTS_DIR/` directory.
#                Add/Set `bindfs_extractor.sh` to `$POST_BUILD_SCRIPTS_TO_RUN` in `android_ndk_cross_compile_build_automator.sh`. 
#date:           1-Aug-2019
#versions:       1.0
#license:        MIT License


bindfs_out_dir="$OUT_DIR/bindfs"
build_info_file="$bindfs_out_dir/build_info.txt"

build_timestamp="$(date +"%Y-%m-%d %H.%M.%S")"
build_info="Build Info:"
build_info+=$'\n'"NDK_FULL_VERSION=$NDK_FULL_VERSION"
build_info+=$'\n'"C_COMPILER=$C_COMPILER"
build_info+=$'\n'"HOST_TAG=$HOST_TAG"
build_info+=$'\n'"BUILD_TIMESTAMP=$build_timestamp"

if [ -d "$bindfs_out_dir" ]; then
	rm -rf "$bindfs_out_dir"
	if [ $? -ne 0 ]; then
	echo "Failed to remove $bindfs_out_dir"
	exit 1
	fi
fi

mkdir -p "$bindfs_out_dir"
if [ ! -d "$bindfs_out_dir" ]; then
	echo "Failed to create $bindfs_out_dir"
	exit 1
fi

bindfs_binary_found=0
for ARCH_FILE in "$ARCHS_DIR"/*; do

	ARCH_SRC="$(basename "$ARCH_FILE")"

	source "$ARCH_FILE"

	bindfs_binary_path="$INSTALL_DIR/bindfs/$ARCH_SRC/usr/local/bin"
	if [ -f "$bindfs_binary_path/bindfs" ]; then
		bindfs_binary_found=1
		build_info+=$'\n\n\n\n'"ARCH_SRC=$ARCH_SRC"$'\n'"API_LEVEL=$API_LEVEL"
		build_info+=$'\n'"BINDFS=bindfs-$ARCH_SRC"
		build_info+=$'\n'"Binary Info:"$'\n'"$(cd "$bindfs_binary_path"; file bindfs)"
		build_info+=$'\n'"Shared Libraries:"$'\n'"$(readelf -d "$bindfs_binary_path/bindfs" | grep "NEEDED")"
		cp -fa "$bindfs_binary_path/bindfs" "$bindfs_out_dir/bindfs-$ARCH_SRC"
	fi
done

if [ $bindfs_binary_found -eq 1 ]; then
	echo -e "\n\n"
	echo "$build_info"
	echo "$build_info" > "$build_info_file"
	bindfs_out_zip="$OUT_DIR/bindfs-ndk-$NDK_FULL_VERSION-$C_COMPILER-$build_timestamp.zip"
	echo -e "\n\n"
	echo "Building bindfs_out_zip at $bindfs_out_zip"
	cd "$OUT_DIR"
	zip "$bindfs_out_zip" "bindfs"/*
	echo "Complete"
fi
