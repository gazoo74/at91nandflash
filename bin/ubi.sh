#!/bin/bash -e

usage() {
	cat <<EOF
Usage: ${0##*/} .config
EOF
}

trap 'test $? -ne 0 && ( usage && echo "Error: too few arguements!" ) >&2' 0

. $1

volid=0
cat <<EOF
#
# Generated by
EOF

# Device-tree
if test ${CONFIG_DTB:-n} = y; then
	cat <<EOF

[dtb]
mode=ubi
image=${DTB_IMAGE:-dtb}
vol_id=$volid
vol_type=static
vol_name="$CONFIG_DTB_UBI_VOLNAME"
EOF
	volid=$(($volid + 1))

	if test ${CONFIG_UBI_SPARE:-n} = y; then
		cat <<EOF

[dtb-spare]
mode=ubi
image=dtb
vol_id=$volid
vol_type=static
vol_name="$CONFIG_DTB_SPARE_UBI_VOLNAME"
EOF
		volid=$(($volid + 1))
	fi
fi

# Kernel
cat <<EOF

[kernel]
mode=ubi
image=${KERNEL_IMAGE:-dtb}
vol_id=$volid
vol_type=static
vol_name="$CONFIG_KERNEL_UBI_VOLNAME"
EOF
volid=$(($volid + 1))

if test ${CONFIG_UBI_SPARE:-n} = y; then
	cat <<EOF

[kernel-spare]
mode=ubi
image=kernel
vol_id=$volid
vol_type=static
vol_name="$CONFIG_KERNEL_SPARE_UBI_VOLNAME"
EOF
	volid=$(($volid + 1))
fi

# Persistant
cat <<EOF

[persistant]
mode=ubi
image=persistant.ubifs
vol_id=$volid
vol_size=${PERSISTANT_VOL_SIZE:-3MiB}
vol_alignement=1
vol_name="$CONFIG_PERSISTANT_UBI_VOLNAME"
EOF
volid=$(($volid + 1))