#!/usr/bin/env bash

 ##
 # Script For Building Android Kernel
 #

##----------------------------------------------------------##
# Specify Kernel Directory
KERNEL_DIR="$(pwd)"

# git submodule update --init --recursive --remote

##----------------------------------------------------------##
# Device Name and Model
MODEL=Xiaomi
DEVICE=surya

# Kernel Version Code
#VERSION=

# Kernel Defconfig
DEFCONFIG=${DEVICE}_defconfig

# Files
IMAGE=$(pwd)/out/arch/arm64/boot/Image
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/out/arch/arm64/boot/dts/qcom/sdmmagpie.dtb

# Verbose Build
VERBOSE=0

# Kernel Version
#KERVER=$(make kernelversion)

#COMMIT_HEAD=$(git log --oneline -1)

# Date and Time
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Specify Final Zip Name
ZIPNAME="SUPER.KERNEL.SURYA-(neutron)-$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"

##----------------------------------------------------------##
# Specify compiler.

COMPILER=neutron

##----------------------------------------------------------##
# Specify Linker
LINKER=ld.lld

##----------------------------------------------------------##

##----------------------------------------------------------##
# Clone ToolChain
function cloneTC() {

    if [ $COMPILER = "neutron" ];
    then
    mkdir Neutron
    curl -s https://api.github.com/repos/Neutron-Toolchains/clang-build-catalogue/releases/135899675/assets \
    | grep "browser_download_url.*tar.zst" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget --output-document=Neutron.tar.zst -qi -
    tar -xvf Neutron.tar.zst -C Neutron/
    
    export KERNEL_CLANG="clang"
    export KERNEL_CLANG_PATH="${KERNEL_DIR}/Neutron"
    export PATH="$KERNEL_CLANG_PATH/bin:$PATH"
    
	fi
	
    # Clone AnyKernel
    #git clone --depth=1 https://github.com/missgoin/AnyKernel3.git

	}


##------------------------------------------------------##
# Export Variables
function exports() {
	
        # Export KBUILD_COMPILER_STRING
        
#        if [ -d ${KERNEL_DIR}/clang ];
#           then
#               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
#               export LD_LIBRARY_PATH="${KERNEL_DIR}/clang/lib:$LD_LIBRARY_PATH"
        
#        elif [ -d ${KERNEL_DIR}/gcc64 ];
#           then
#               export KBUILD_COMPILER_STRING=$("$KERNEL_DIR/gcc64"/bin/aarch64-elf-gcc --version | head -n 1)       
        
        if [ -d ${KERNEL_DIR}/cosmic ];
           then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/cosmic/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')        
        
        elif [ -d ${KERNEL_DIR}/cosmic-clang ];
           then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/cosmic-clang/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')       
        
        elif [ -d ${KERNEL_DIR}/Neutron ];
           then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/Neutron/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')
               export LD_LIBRARY_PATH="${KERNEL_DIR}/Neutron/lib:$LD_LIBRARY_PATH"

        elif [ -d ${KERNEL_DIR}/aosp-clang ];
            then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/aosp-clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        fi
        
        # Export ARCH and SUBARCH
        export ARCH=arm64
        export SUBARCH=arm64
        
        # Export Local Version
        #export LOCALVERSION="-${VERSION}"
        
        # KBUILD HOST and USER
        export KBUILD_BUILD_HOST=Pancali
        export KBUILD_BUILD_USER="unknown"
        
	    export PROCS=$(nproc --all)
	    export DISTRO=$(source /etc/os-release && echo "${NAME}")
	    
	    export USE_HOST_LEX=yes
	    
	    # Server caching for speed up compile
	    #export LC_ALL=C && export USE_CCACHE=1
	    #ccache -M 100G
	
	}
        
##----------------------------------------------------------------##
# Telegram Bot Integration
##----------------------------------------------------------------##


##----------------------------------------------------------##
# Compilation
function compile() {
START=$(date +"%s")
		
	# Compile
	make O=out ARCH=arm64 ${DEFCONFIG}
	
	if [ -d ${KERNEL_DIR}/clang ];
	   then
	       make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       CC=$KERNEL_CLANG \
           CROSS_COMPILE=$KERNEL_CCOMPILE64 \
           CROSS_COMPILE_ARM32=$KERNEL_CCOMPILE32 \
           LD=${LINKER} \
           LLVM=1 \
           LLVM_IAS=1 \
           #AR=llvm-ar \
	       #NM=llvm-nm \
	       #OBJCOPY=llvm-objcopy \
	       #OBJDUMP=llvm-objdump \
	       #STRIP=llvm-strip \
	       #OBJSIZE=llvm-size \
	       V=$VERBOSE 2>&1 | tee error.log
	       
	elif [ -d ${KERNEL_DIR}/Neutron ];
	   then
	       make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       CC=$KERNEL_CLANG \
	       CROSS_COMPILE=aarch64-linux-gnu- \
	       CLANG_TRIPLE=aarch64-linux-gnu- \
	       LD=${LINKER} \
	       LLVM=1 \
	       LLVM_IAS=1 \
	       #AS=llvm-as \
	       #AR=llvm-ar \
	       #NM=llvm-nm \
	       #OBJCOPY=llvm-objcopy \
	       #OBJDUMP=llvm-objdump \
	       #STRIP=llvm-strip \
	       #READELF=llvm-readelf \
	       #OBJSIZE=llvm-size \
	       V=$VERBOSE 2>&1 | tee error.log
	
	fi
}

##----------------------------------------------------------------##
function zipping() {
	# Copy Files To AnyKernel3 Zip
	cp $IMAGE AnyKernel3
	cp $DTBO AnyKernel3
	cp $DTB AnyKernel3/dtb
	
	# Zipping and Push Kernel
	cd AnyKernel3 || exit 1
        zip -r9 ${ZIPNAME} *
        MD5CHECK=$(md5sum "$ZIPNAME" | cut -d' ' -f1)
        echo "Zip: $ZIPNAME"
        # curl -T $ZIPNAME temp.sh; echo
        curl -T $ZIPNAME https://oshi.at
        # curl --upload-file $ZIPNAME https://free.keep.sh
    cd ..
}

    
##----------------------------------------------------------##

cloneTC
exports
compile
zipping

##----------------*****-----------------------------##
