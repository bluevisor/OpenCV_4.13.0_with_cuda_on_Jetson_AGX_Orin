#!/bin/bash
#
# Copyright (c) 2022, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.
#
# Modified from this script: https://github.com/AastaNV/JEP/blob/master/script/install_opencv4.6.0_Jetson.sh

version="4.13.0"
folder="workspace"

set -e

# Fail fast if a prior 'sudo ./install...' left a root-owned workspace/ behind.
if [ -e "$folder" ] && [ ! -w "$folder" ]; then
    owner=$(stat -c '%U:%G' "$folder" 2>/dev/null || echo 'unknown')
    echo "** ERROR: '$folder' exists but is not writable by $USER (owned by $owner)."
    echo "**        This usually means a previous run used 'sudo ./install...'."
    echo "** Fix:   sudo rm -rf $folder            # discard old build tree, OR"
    echo "**        sudo chown -R \"\$USER:\$USER\" $folder   # keep it"
    exit 1
fi

for (( ; ; ))
do
    echo "Do you want to remove the default OpenCV (yes/no)?"
    read rm_old

    if [ "$rm_old" = "yes" ]; then
        echo "** Remove other OpenCV first"
        sudo apt -y purge '*libopencv*'
        break
    elif [ "$rm_old" = "no" ]; then
        break
    else
        echo "** Please type 'yes' or 'no'"
    fi
done


echo "------------------------------------"
echo "** Install requirement (1/4)"
echo "------------------------------------"
sudo apt-get update
sudo apt-get install -y build-essential cmake git libgtk-3-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
sudo apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
sudo apt-get install -y libtbb-dev libjpeg-dev libpng-dev libtiff-dev
sudo apt-get install -y libv4l-dev v4l-utils qv4l2
sudo apt-get install -y libopenblas-dev liblapacke-dev   # BLAS + LAPACK(E) for cv::gemm fast path
sudo apt-get install -y libeigen3-dev                    # enables alphamat, rgbd posegraph, parts of sfm
sudo apt-get install -y libvtk9-dev                      # enables the viz module (3D visualization)
sudo apt-get install -y libhdf5-dev                      # enables the hdf module (HDF5 matrix I/O)
sudo apt-get install -y libtesseract-dev libleptonica-dev # enables OCR in the text module
sudo apt-get install -y libgflags-dev libgoogle-glog-dev # with Eigen, enables full sfm module
sudo apt-get install -y curl


echo "------------------------------------"
echo "** Download opencv "${version}" (2/4)"
echo "------------------------------------"
mkdir -p "$folder"
cd "$folder"
curl -L https://github.com/opencv/opencv/archive/${version}.zip -o opencv-${version}.zip
curl -L https://github.com/opencv/opencv_contrib/archive/${version}.zip -o opencv_contrib-${version}.zip
unzip -o opencv-${version}.zip
unzip -o opencv_contrib-${version}.zip
rm opencv-${version}.zip opencv_contrib-${version}.zip
cd opencv-${version}/


echo "------------------------------------"
echo "** Build opencv "${version}" (3/4)"
echo "------------------------------------"
if [ -d release ] && ! rm -rf release 2>/dev/null; then
    echo "** ERROR: cannot remove 'release/' — it contains files owned by another user."
    echo "** Fix:   sudo rm -rf release    (or chown to \$USER first)"
    exit 1
fi
mkdir release
cd release/
# CUDA_ARCH_BIN: Orin, Orin NX, Orin Nano: 8.7; Xavier, Xavier NX: 7.2; TX2: 6.2; Nano: 5.3
cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D CMAKE_CXX_STANDARD=17 \
    -D CMAKE_CUDA_STANDARD=17 \
    -D WITH_CUDA=ON \
    -D WITH_CUDNN=ON \
    -D WITH_CUBLAS=ON \
    -D OPENCV_DNN_CUDA=ON \
    -D WITH_NVCUVID=OFF \
    -D WITH_NVCUVENC=OFF \
    -D CUDA_ARCH_BIN="8.7" \
    -D CUDA_ARCH_PTX="" \
    -D ENABLE_FAST_MATH=ON \
    -D CUDA_FAST_MATH=ON \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${version}/modules \
    -D GLOG_INCLUDE_DIR=/usr/include \
    -D GFLAGS_INCLUDE_DIR=/usr/include \
    -D WITH_GSTREAMER=ON \
    -D WITH_LIBV4L=ON \
    -D WITH_OPENGL=ON \
    -D BUILD_opencv_python3=ON \
    -D PYTHON3_EXECUTABLE=/usr/bin/python3 \
    -D PYTHON3_PACKAGES_PATH=/usr/local/lib/python3.10/dist-packages \
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D BUILD_EXAMPLES=OFF \
    ..
make -j$(nproc)


echo "------------------------------------"
echo "** Install opencv "${version}" (4/4)"
echo "------------------------------------"
sudo make install
sudo ldconfig

# Append env-var exports to the user's login-shell rc file (bash, zsh, or fish).
shell_name=$(basename "${SHELL:-/bin/bash}")
case "$shell_name" in
    fish)
        rc_file="$HOME/.config/fish/config.fish"
        mkdir -p "$(dirname "$rc_file")"
        touch "$rc_file"
        ld_line='set -gx LD_LIBRARY_PATH /usr/local/lib $LD_LIBRARY_PATH'
        py_line='set -gx PYTHONPATH /usr/local/lib/python3.10/dist-packages/ $PYTHONPATH'
        reload_cmd="source $rc_file"
        ;;
    zsh)
        rc_file="$HOME/.zshrc"
        touch "$rc_file"
        ld_line='export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH'
        py_line='export PYTHONPATH=/usr/local/lib/python3.10/dist-packages/:$PYTHONPATH'
        reload_cmd="source $rc_file"
        ;;
    *)
        rc_file="$HOME/.bashrc"
        ld_line='export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH'
        py_line='export PYTHONPATH=/usr/local/lib/python3.10/dist-packages/:$PYTHONPATH'
        reload_cmd="source $rc_file"
        ;;
esac

grep -qxF "$ld_line" "$rc_file" || echo "$ld_line" >> "$rc_file"
grep -qxF "$py_line" "$rc_file" || echo "$py_line" >> "$rc_file"


echo "** Install opencv "${version}" successfully"
echo "** Detected shell: $shell_name -> wrote env vars to $rc_file"
echo "** Open a new shell or run '$reload_cmd' to pick them up."
echo "** Verify with: python3 -c 'import cv2; print(cv2.__version__, cv2.cuda.getCudaEnabledDeviceCount())'"
echo "** Bye :)"
