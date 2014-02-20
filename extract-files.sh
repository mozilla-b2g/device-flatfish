#!/bin/bash

# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#SOC=a31
DEVICE=flatfish
COMMON=common
MANUFACTURER=allwinner

if [[ -z "${ANDROIDFS_DIR}" && -d ../../../backup-${DEVICE}/system ]]; then
    ANDROIDFS_DIR=../../../backup-${DEVICE}
fi

if [[ -z "${ANDROIDFS_DIR}" ]]; then
    echo Pulling files from device
    DEVICE_BUILD_ID=`adb shell cat /system/build.prop | grep ro.build.display.id | sed -e 's/ro.build.display.id=//' | tr -d '\n\r'`
else
    echo Pulling files from ${ANDROIDFS_DIR}
    DEVICE_BUILD_ID=`cat ${ANDROIDFS_DIR}/system/build.prop | grep ro.build.display.id | sed -e 's/ro.build.display.id=//' | tr -d '\n\r'`
fi

case "$DEVICE_BUILD_ID" in
flatfish*|full_flatfish*)
  FIRMWARE=JB
  echo Found JB firmware with build ID $DEVICE_BUILD_ID >&2
  ;;
*)
  FIRMWARE=unknown
  echo Found unknown firmware with build ID $DEVICE_BUILD_ID >&2
  echo Please download a compatible backup-${DEVICE} directory.
  echo Check the ${DEVICE} intranet page for information on how to get one.
  exit -1
  ;;
esac

#backup the whole system
if [[ ! -d ../../../backup-${DEVICE}/system  && -z "${ANDROIDFS_DIR}" ]]; then
    echo Backing up system partition to backup-${DEVICE}
    mkdir -p ../../../backup-${DEVICE} &&
    adb pull /system ../../../backup-${DEVICE}/system
fi
echo pull done

BASE_PROPRIETARY_DEVICE_DIR=vendor
PROPRIETARY_DEVICE_DIR=../../../vendor
ROOT_DIR=../../..

echo BASE_PROPRIETARY_DEVICE_DIR=$BASE_PROPRIETARY_DEVICE_DIR
echo PROPRIETARY_DEVICE_DIR=$PROPRIETARY_DEVICE_DIR

if [[ -d ${PROPRIETARY_DEVICE_DIR} ]]; then
	rm -rf $PROPRIETARY_DEVICE_DIR
fi

mkdir -p $PROPRIETARY_DEVICE_DIR
PROPRIETARY_BLOBS_LIST=$PROPRIETARY_DEVICE_DIR/vendor-blobs.mk

for NAME in allwinner broadcom imgtec invensense
do
	mkdir -p $PROPRIETARY_DEVICE_DIR/$NAME/$DEVICE/proprietary
done

mkdir -p $ROOT_DIR/device/allwinner/flatfish/media
mkdir -p $ROOT_DIR/device/allwinner/flatfish/configs

(cat << EOF) | sed s/__COMMON__/$COMMON/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > $PROPRIETARY_BLOBS_LIST
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Prebuilt libraries that are needed to build open-source libraries

# All the blobs
PRODUCT_COPY_FILES += \\
EOF

# copy_file
# pull file from the device and adds the file to the list of blobs
#
# $1 = src name
# $2 = dst name
# $3 = directory path on device
# $4 = directory name in $PROPRIETARY_DEVICE_DIR
copy_file()
{
    echo Pulling \"$1\"
#    echo ANDROIDFS_DIR=${ANDROIDFS_DIR}
#    read
    if [[ -z "${ANDROIDFS_DIR}" ]]; then
        if [[ -d $PROPRIETARY_DEVICE_DIR/$4/ ]]; then
            adb pull /$3/$1 $PROPRIETARY_DEVICE_DIR/$4/$2
	elif [[ -d $ROOT_DIR/$4/ ]]; then
	    adb pull /$3/$1 $ROOT_DIR/$4/$2
        else
            echo "$PROPRIETARY_DEVICE_DIR/$4/"
            echo "$ROOT_DIR/$4/"
            echo "Target folder didn't exist, failed to pull $1."
        fi
    else
           # Hint: Uncomment the next line to populate a fresh ANDROIDFS_DIR
           #       (TODO: Make this a command-line option or something.)
           # adb pull /$3/$1 ${ANDROIDFS_DIR}/$3/$1
        if [[ -d $PROPRIETARY_DEVICE_DIR/$4/ ]]; then
	    cp ${ANDROIDFS_DIR}/$3/$1 $PROPRIETARY_DEVICE_DIR/$4/$2
        elif [[ -d $ROOT_DIR/$4/ ]]; then
            cp ${ANDROIDFS_DIR}/$3/$1 $ROOT_DIR/$4/$2
        else
            echo "$PROPRIETARY_DEVICE_DIR/$4/"
            echo "$ROOT_DIR/$4/"
            echo "Target folder didn't exist, failed to pull $1."
        fi
    fi

    if [[ -f $PROPRIETARY_DEVICE_DIR/$4/$2 ]]; then
        echo   $BASE_PROPRIETARY_DEVICE_DIR/$4/$2:$3/$2 \\ >> $PROPRIETARY_BLOBS_LIST
    elif [[ -f $ROOT_DIR/$4/$2 ]]; then
	echo   $4/$2:$3/$2 \\ >> $PROPRIETARY_BLOBS_LIST
    else
        echo Failed to pull $1. Giving up.
        exit -1
    fi
}

# copy_files
# pulls a list of files from the device and adds the files to the list of blobs
#
# $1 = list of files
# $2 = directory path on device
# $3 = directory name in $PROPRIETARY_DEVICE_DIR
copy_files()
{
    for NAME in $1
    do
        copy_file "$NAME" "$NAME" "$2" "$3"
    done
}

KERNEL_KO="
	actuator.ko
	ad5820_act.ko
	afa750.ko
	asix.ko
	aw5306_ts.ko
	bcmdhd.ko
	bma250.ko
	cam_detect.ko
	cci.ko
	dc_sunxi.ko
	device.ko
	disp.ko
	dw9714_act.ko
	example.ko
	ft5x_ts.ko
	fxos8700.ko
	g2d_33.ko
	hi253.ko
	hid-logitech-dj.ko
	kionix_tiny.ko
	l3gd20_gyr.ko
	lcd.ko
	lis3de_acc.ko
	lis3dh_acc.ko
	lsm303d.ko
	ltr303.ko
	mcs7830.ko
	mma7660.ko
	mma8452.ko
	mma865x.ko
	Module.symvers
	mpu6050.ko
	nand.ko
	ov8825_act.ko
	pvrsrvkm.ko
	qf9700.ko
	rtl8150.ko
	s5k4ec_mipi.ko
	scsi_wait_scan.ko
	sndi2s.ko
	sndpcm.ko
	sndspdif.ko
	sun6i-i2sdma.ko
	sun6i-i2s.ko
	sun6i-ir.ko
	sun6i-pcmdma.ko
	sun6i-pcm.ko
	sun6i-sndi2s.ko
	sun6i-sndpcm.ko
	sun6i_sndspdif.ko
	sun6i_spdif.ko
	sun6i_spdma.ko
	sw-keyboard.ko
	uvcvideo.ko
	vfe_os.ko
	vfe_subdev.ko
	vfe_v4l2.ko
	videobuf2-core.ko
	videobuf2-memops.ko
	videobuf2-vmalloc.ko
	videobuf-core.ko
	videobuf-dma-contig.ko
	"
copy_files "$KERNEL_KO" "system/vendor/modules" "allwinner/$DEVICE/proprietary"

SENSOR_LIB="
	libmllite.so
	libmplmpu.so
	libinvensense_hal.so
	libmlplatform.so
	"
copy_files "$SENSOR_LIB" "system/lib" "invensense/$DEVICE/proprietary"

SENSOR_HW="
	sensors.$DEVICE.so
	"
copy_files "$SENSOR_HW" "system/lib/hw" "invensense/$DEVICE/proprietary"

BROADCOM="
	bcm40183b2.hcd
	fw_bcm40183b2.bin
	fw_bcm40183b2_apsta.bin
	fw_bcm40183b2_p2p.bin
	nvram_gb9663.txt
	"
copy_files "$BROADCOM" "system/vendor/modules" "broadcom/$DEVICE/proprietary"

BROADCOM_BIN="
	glgps
	wl
	"
copy_files "$BROADCOM_BIN" "system/bin" "broadcom/$DEVICE/proprietary"

COMMON_ETC_GPS="
	gpsconfig.xml
	"
copy_files "$COMMON_ETC_GPS" "system/etc/gps" "broadcom/$DEVICE/proprietary"

IMGTEC_LIB="
	libCedarX.so
	libCedarA.so
	libcedarxosal.so
	libcedarv.so
	libcedarv_base.so
	libcedarv_adapter.so
	libve.so
	libthirdpartstream.so
	libcedarxsftstream.so
	libfacedetection.so
	libsunxi_alloc.so
	libjpgenc.so
	libaw_h264enc.so
	libcedarxbase.so
	libaw_audio.so
	libaw_audioa.so
	libswdrm.so
	libstagefright_soft_cedar_h264dec.so
	"
copy_files "$IMGTEC_LIB" "system/lib" "imgtec/$DEVICE/proprietary"

IMGTEC_VLIB="
	libglslcompiler.so
	libIMGegl.so
	libpvr2d.so
	libpvrANDROID_WSEGL.so
	libPVRScopeServices.so
	libsrv_init.so
	libsrv_um.so
	libusc.so
	"
copy_files "$IMGTEC_VLIB" "system/vendor/lib" "imgtec/$DEVICE/proprietary"

IMGTEC_EGL="
    libEGL_POWERVR_SGX544_115.so
    libGLESv1_CM_POWERVR_SGX544_115.so
    libGLESv2_POWERVR_SGX544_115.so
    "
copy_files "$IMGTEC_EGL" "system/vendor/lib/egl" "imgtec/$DEVICE/proprietary"

IMGTEC_HW="
    hwcomposer.$DEVICE.so
    gralloc.$DEVICE.so
    "
copy_files "$IMGTEC_HW" "system/vendor/lib/hw" "imgtec/$DEVICE/proprietary"

IMGTEC_BIN="
    pvrsrvctl
    "
copy_files "$IMGTEC_BIN" "system/vendor/bin" "imgtec/$DEVICE/proprietary"

COMMON_HW="
	lights.$DEVICE.so
	gps.$DEVICE.so
	camera.$DEVICE.so
	audio.primary.$DEVICE.so
	audio_policy.default.so
	gralloc.default.so
	"
copy_files "$COMMON_HW" "system/lib/hw" "allwinner/$DEVICE/proprietary"

AUDIO_A2DP_HW="
	audio.a2dp.default.so
	"
copy_files "$AUDIO_A2DP_HW" "system/lib/hw" "allwinner/$DEVICE/proprietary"

TOOLS="
	data_resume.sh
	mke2fs.ext4
	mount.exfat
	preinstall.sh
	busybox
	fsck.exfat
	mkfs.exfat
	busybox-smp
	iostat
	mkntfs
	toolbox
	vold
	logcat
	go_recovery
	recovery
	"
copy_files "$TOOLS" "system/bin" "allwinner/$DEVICE/proprietary"

VENDOR_COMMON_LIBS="
	libril_audio.so
	libcodec_audio.so
	libril.so
	libcutils.so
	libsuspend.so
	libext4_utils.so
	libsensorservice.so
	librecovery.so
	"
copy_files "$VENDOR_COMMON_LIBS" "system/lib" "allwinner/$DEVICE/proprietary"

VENDOR_AW_LIBS="
	libOmxVdec.so
	libOmxVenc.so
	libOmxCore.so
	libstagefrighthw.so
	libtinyalsa.so
	libgui.so
	libui.so
	libhardware.so
	libhardware_legacy.so
	libstagefright.so
	"
copy_files "$VENDOR_AW_LIBS" "system/lib" "allwinner/$DEVICE/proprietary"

DEVICE_COMMON="
	media_codecs.xml
	audio_policy.conf
	phone_volume.conf
	wfd_blacklist.conf
	"
copy_files "$DEVICE_COMMON" "system/etc" "device/allwinner/common"

DEVICE_PERMISSIONS="
	tablet_core_hardware.xml
	"
copy_files "$DEVICE_PERMISSIONS" "system/etc/permissions" "device/allwinner/common"

DEVICE_BIN="
	sensors.sh
	"
copy_files "$DEVICE_BIN" "system/bin" "device/allwinner/common"

DEVICE_EGL_CFG="
	egl.cfg
	"
copy_files "$DEVICE_EGL_CFG" "system/lib/egl" "device/allwinner/common"

DEVICE_MEDIA="
	boot.wav
	"
copy_files "$DEVICE_MEDIA" "system/media" "device/allwinner/$DEVICE/media"

DEVICE_KEY_CFG="
	sw-keyboard.kl
	axp22-supplyer.kl
	"
copy_files "$DEVICE_KEY_CFG" "system/usr/keylayout" "device/allwinner/$DEVICE/configs"

DEVICE_IDC_CFG="
	ft5x_ts.idc
	"
copy_files "$DEVICE_IDC_CFG" "system/usr/idc" "device/allwinner/$DEVICE/configs"

DEVICE_GSENSOR_CFG="
	gsensor.cfg
	"
copy_files "$DEVICE_GSENSOR_CFG" "system/usr" "device/allwinner/$DEVICE/configs"

DEVICE_ETC_CFG="
	media_profiles.xml
	camera.cfg
	powervr.ini
	"
copy_files "$DEVICE_ETC_CFG" "system/etc" "device/allwinner/$DEVICE/configs"

DEVICE_ETC="
	gps.conf
	vold.fstab
	"
copy_files "$DEVICE_ETC" "system/etc" "device/allwinner/$DEVICE"

echo ...........extract done...
#read

