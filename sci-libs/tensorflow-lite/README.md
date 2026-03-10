# TensorFlow Lite + bgremover Gentoo Overlay

## Package listing

### sci-libs/tensorflow-lite

Builds the TensorFlow Lite (LiteRT) C/C++ inference runtime from the main
TensorFlow source tree using the upstream CMake build system.

**Versions:**
- `2.21.0` — Latest stable release (March 2026)
- `9999`   — Live git master

**USE flags:**
| Flag     | Default | Description                                      |
|----------|---------|--------------------------------------------------|
| `xnnpack`| off     | XNNPACK CPU delegate for optimised inference     |
| `gpu`    | off     | OpenCL GPU delegate (experimental)               |
| `ruy`    | off     | RUY matrix multiplication backend                |
| `test`   | off     | Build and run kernel unit tests                  |

**Important notes:**

1. **Network sandbox is disabled** (`RESTRICT="network-sandbox"`). The
   TF Lite CMake build downloads ~10 vendored dependencies at configure time
   (farmhash, fft2d, gemmlowp, ruy, cpuinfo, XNNPACK, pthreadpool, FP16,
   NEON_2_SSE, ml_dtypes) that have no Gentoo packages. This is the main
   trade-off; a fully offline build would require packaging each of those
   dependencies separately.

2. The build requires **C++20** and **CMake ≥ 3.16**.

3. System packages used where possible: `dev-cpp/abseil-cpp`,
   `dev-libs/flatbuffers`, `dev-cpp/eigen`.

4. Two artifacts are installed:
   - `libtensorflow-lite.a` — static C++ library + CMake config
   - `libtensorflowlite_c.so` — C API shared library

### media-video/bgremover

V4L2 webcam background remover using TF Lite + DeepLab v3.

Depends on `sci-libs/tensorflow-lite`.

## Quick start

```bash
# In your local overlay root:
cp -r sci-libs/ media-video/ /var/db/repos/myoverlay/

# Generate manifests:
cd /var/db/repos/myoverlay/sci-libs/tensorflow-lite
ebuild tensorflow-lite-2.21.0.ebuild manifest

cd /var/db/repos/myoverlay/media-video/bgremover
ebuild bgremover-0_pre20200701.ebuild manifest

# Install:
emerge -av sci-libs/tensorflow-lite
emerge -av media-video/bgremover
```

## Architecture support

Both packages are keyworded `~amd64 ~arm64`. The TF Lite CMake build
natively supports both architectures. On x86_64 it uses NEON_2_SSE
for NEON intrinsic translation; on arm64 native NEON is used directly.
