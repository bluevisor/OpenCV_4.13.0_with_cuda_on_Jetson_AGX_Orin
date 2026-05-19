Setup Nvidia Jetson AGX Orin (JetPack 6.x / L4T R36):

_Last updated: 2026-05-18_

Prerequisites: ~12 GB free disk + swap on the target. Build takes ~2-3 h on AGX Orin with `make -j$(nproc)`.

1, Install JetPack 6 using NVIDIA's SDK Manager from an x86 Ubuntu 20.04 or 22.04 host. To enter Force Recovery on the AGX Orin Devkit: hold the **Force Recovery** button, tap **Reset**, then release Force Recovery. Connect via USB-C.

2, Ensure JetPack components (CUDA, cuDNN, TensorRT, etc.) are installed — SDK Manager normally does this, but if you only flashed the base L4T image, run:
`sudo apt update && sudo apt install -y nvidia-jetpack`

3, Set max performance:
`sudo nvpmodel -m 0` (MAXN; on JetPack 6.2 the AGX Orin also exposes MAXN_SUPER),
`sudo jetson_clocks`

4, Install jtop (Ubuntu 22.04 uses PEP 668, so `--break-system-packages` is required):
`sudo apt update`,
`sudo apt install -y python3-pip`,
`sudo pip3 install -U jetson-stats --break-system-packages`

5, Install OpenCV with CUDA: clone this repo, then
`chmod +x install_OpenCV_4.13.0_with_cuda_on_Jetpack_6.sh`,
`./install_OpenCV_4.13.0_with_cuda_on_Jetpack_6.sh`
(the script uses `sudo` internally — do not run the whole script with sudo or `~/.bashrc` will be modified for root).

6, Verify the install:
`python3 -c "import cv2; print(cv2.__version__, cv2.cuda.getCudaEnabledDeviceCount())"`
Expected: `4.13.0 1`

7, TensorRT: ships pre-installed with JetPack 6. For the Python/dev bindings:
`sudo apt-get install -y python3-libnvinfer-dev`

8, Install PyTorch — use the NVIDIA Jetson AI Lab pip index (preferred over PyPI extra-index, which serves broken SBSA wheels):
see https://forums.developer.nvidia.com/t/pytorch-for-jetson/72048 or the JetPack-AI-Lab index documented at https://pypi.jetson-ai-lab.io/
