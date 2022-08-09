#!/bin/bash

#### Modify the following two lines according to the kernel name ####
#    you want to build. To look for the latest stable kernel, go to #
#    https://wiki.linuxfoundation.org/realtime/start .              #
#                                                                   #
kern_vers=5
kern_major=15
kern_minor=55      
rt_kern=rt48
KERN=$kern_vers.$kern_major.$kern_minor-$rt_kern                                          #
#                                                                   #
#                                                                   #
#####################################################################

path="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e ""
echo -e "${BLUE}--> Installing tools...${NC}"
echo -e ""

sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev

sudo apt-get install dpkg-dev # for generating debs

sudo apt install fakeroot

sudo apt install crossbuild-essential-arm64 # crosscompiling toolchain

cd $path

# git clone --depth=1 https://github.com/raspberrypi/linux

# git checkout -b rpi-5.15.55-rt a4493f3afe

echo -e ""
echo -e "${BLUE}--> Downloading kernel archives...${NC}"
echo -e ""

# wget https://mirrors.edge.kernel.org/pub/linux/kernel/v$kern_vers.x/linux-$kern_vers.$kern_major.$kern_minor.tar.gz 
git clone --depth=1 https://github.com/raspberrypi/linux
wget https://cdn.kernel.org/pub/linux/kernel/projects/rt/$kern_vers.$kern_major/patch-$KERN.patch.gz 

echo -e ""
echo -e "${BLUE}--> Extracting archives...${NC}"
echo -e ""

# tar -xzf linux-$kern_vers.tar.gz
gunzip patch-$KERN.patch.gz

echo -e ""
echo -e "${BLUE}--> Coping base RPI4 config to kernel forlder...${NC}"
echo -e ""
# cp bcm2711_defconfig linux-$kern_vers/arch/arm64/configs/

# cp rpi4_defconfig linux-$kern_vers.$kern_major.$kern_minor/arch/arm64/configs/
# cp config-5.4.0-1066-raspi_defconfig linux-$kern_vers.$kern_major.$kern_minor/arch/arm64/configs/

cp rpi4_defconfig linux/arch/arm64/configs/

# cd linux-$kern_vers

cd linux
git checkout a90998a3e

echo -e ""
echo -e "${BLUE}--> Applying patch to kernel...${NC}"
echo -e ""
patch -p1 < ../patch-$KERN.patch

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# export KERNEL=kernel8
echo -e ""
echo -e "${BLUE}--> Starting configuration...${NC}"
echo -e ""

make clean

make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- rpi4_defconfig # loads configs for RPI4 CPU

# make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig # IMPORTANT!!!!!!!!!: load previously generated .config

# # - Disable virtualization
#   - -> Virtualization
#     - -> N

# # Enable CONFIG_PREEMPT_RT
#  -> General Setup
#   -> Preemption Model (Fully Preemptible Kernel (Real-Time))
#    (X) Fully Preemptible Kernel (Real-Time)

# # Enable CONFIG_HIGH_RES_TIMERS
#  -> General setup
#   -> Timers subsystem
#    [*] High Resolution Timer Support

# # Enable CONFIG_NO_HZ_FULL
#  -> General setup
#   -> Timers subsystem
#    -> Timer tick handling (Full dynticks system (tickless))
#     (X) Full dynticks system (tickless)

# # Set CONFIG_HZ_1000 (note: this is no longer in the General Setup menu, go back twice)
#  -> Processor type and features
#   -> Timer frequency (1000 HZ)
#    (X) 1000 HZ

# # Set CPU_FREQ_DEFAULT_GOV_PERFORMANCE [=y]
#  ->  Power management and ACPI options
#   -> CPU Frequency scaling
#    -> CPU Frequency scaling (CPU_FREQ [=y])
#     -> Default CPUFreq governor (<choice> [=y])
#      (X) performance

# choose previously unchosen options
# make -j6 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs # building

echo -e ""
echo -e "${BLUE}--> Building kernel and generating .deb packages...${NC}"
echo -e ""

make -j6 bindeb-pkg # generate debs in ../kernel_folder_path

echo -e ""
echo -e "${BLUE}--> Moving files to destination folder...${NC}"
echo -e ""

# copying archives to kernel-specific directory
UBUNTU_MAJOR_FULL=$(lsb_release -rs)
kernel_dir=$KERN-$UBUNTU_MAJOR_FULL

mkdir ../$kernel_dir
cp ../*.deb ../$kernel_dir

rm ../*.deb