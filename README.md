# OpenCV 4.13.0 with CUDA on Jetson AGX Orin

Build script and setup notes for installing **OpenCV 4.13.0** with CUDA, cuDNN, GStreamer, and the contrib modules on **NVIDIA Jetson AGX Orin** running **JetPack 6.x** (L4T R36 / Ubuntu 22.04).

> _Last updated: 2026-05-18_

---

## Requirements

| Component | Version |
|-----------|---------|
| Hardware  | Jetson AGX Orin Devkit (other Orin variants supported — see [Notes](#notes)) |
| OS        | JetPack 6.x (L4T R36, Ubuntu 22.04) |
| CUDA      | 12.6 (bundled with JetPack 6.2) |
| cuDNN     | 9.x |
| Python    | 3.10 |
| Disk      | ~12 GB free + swap (**NVMe SSD highly recommended** — see below) |
| Build time | ~2–3 h with `make -j$(nproc)` on AGX Orin |

> **Tip:** Install the OS — or at least move `/home` and the build directory — to an **NVMe SSD**. Building OpenCV on the stock eMMC / SD card is painfully slow (many thousands of small I/Os) and can wear the flash. The AGX Orin Devkit has an M.2 Key M slot; flashing rootfs to NVMe via SDK Manager is the cleanest setup.

---

## Setup

### 1. Flash JetPack 6

Install JetPack 6 using [NVIDIA SDK Manager](https://developer.nvidia.com/sdk-manager) from an **x86 Ubuntu 20.04 or 22.04** host.

To enter **Force Recovery** mode on the AGX Orin Devkit:

1. Hold the **Force Recovery** button
2. Tap **Reset**
3. Release **Force Recovery**

Connect the device to the host with a USB-C cable. The AGX Orin Devkit has **two USB-C ports** — for flashing you must use the one **next to the 40-pin GPIO header** (the "Device" / OTG port). The other USB-C port (next to the 10GbE jack) is a regular USB 3.2 Type-C and will *not* work for SDK Manager.

---

### 2. Ensure JetPack components are installed

SDK Manager normally installs CUDA, cuDNN, TensorRT, etc. If you only flashed the base L4T image, install the meta-package:

```bash
sudo apt update && sudo apt install -y nvidia-jetpack
```

---

### 3. Set max performance

```bash
sudo nvpmodel -m 3      # 50W mode (recommended)
sudo jetson_clocks
```

Available modes on the AGX Orin Devkit:

| ID | Mode    |
|----|---------|
| 0  | MAXN    |
| 1  | 15W     |
| 2  | 30W     |
| 3  | 50W     |

> **Heads up:** `nvpmodel -m 0` (MAXN) frequently triggers `System throttled due to Over-current` under heavy CPU+GPU load — especially if you're not using the 90W barrel-jack adapter that ships with the Devkit. **Use mode 3 (50W) as the safe default**, and only switch to MAXN if you've verified your PSU and cooling can sustain it.

---

### 4. Install `jtop`

Ubuntu 22.04 enforces PEP 668, so `--break-system-packages` is required:

```bash
sudo apt update
sudo apt install -y python3-pip
sudo pip3 install -U jetson-stats --break-system-packages
```

Launch with `jtop`.

---

### 5. Build OpenCV with CUDA

```bash
git clone https://github.com/bluevisor/OpenCV_4.13.0_with_cuda_on_Jetson_AGX_Orin.git
cd OpenCV_4.13.0_with_cuda_on_Jetson_AGX_Orin
chmod +x install_OpenCV_4.13.0_with_cuda_on_Jetpack_6.sh
./install_OpenCV_4.13.0_with_cuda_on_Jetpack_6.sh
```

> **Note:** Do not run the whole script with `sudo`. The script invokes `sudo` only where needed; running everything as root would write `LD_LIBRARY_PATH` / `PYTHONPATH` into root's `~/.bashrc` instead of yours.

---

### 6. Verify the install

```bash
python3 -c "import cv2; print(cv2.__version__, cv2.cuda.getCudaEnabledDeviceCount())"
```

Expected output:

```
4.13.0 1
```

---

### 7. TensorRT _(optional)_

TensorRT 10 ships pre-installed with JetPack 6. For Python and dev headers:

```bash
sudo apt-get install -y python3-libnvinfer-dev
```

---

### 8. PyTorch _(optional)_

Use the [NVIDIA Jetson AI Lab pip index](https://pypi.jetson-ai-lab.io/) — PyPI's extra-index serves broken SBSA wheels on Jetson.

See also the [PyTorch for Jetson forum thread](https://forums.developer.nvidia.com/t/pytorch-for-jetson/72048).

---

## Notes

**Other Jetson modules.** Edit `CUDA_ARCH_BIN` in the script:

| Module | `CUDA_ARCH_BIN` |
|--------|-----------------|
| AGX Orin / Orin NX / Orin Nano | `8.7` |
| Xavier / Xavier NX             | `7.2` |
| TX2                            | `6.2` |
| Nano                           | `5.3` |

**Environment.** The script auto-detects your login shell (`$SHELL`) and appends `LD_LIBRARY_PATH` and `PYTHONPATH` to the right rc file (guarded against duplicates):

| Shell | File written |
|-------|--------------|
| bash  | `~/.bashrc` |
| zsh   | `~/.zshrc` |
| fish  | `~/.config/fish/config.fish` (fish-style `set -gx`) |

Open a new shell or `source` that file after install.

**Disabling DNN-on-GPU.** Remove `-D OPENCV_DNN_CUDA=ON` from the script's `cmake` invocation if you don't need the CUDA DNN backend (slightly faster build).

---

_Based on [`AastaNV/JEP/install_opencv4.6.0_Jetson.sh`](https://github.com/AastaNV/JEP/blob/master/script/install_opencv4.6.0_Jetson.sh)._
