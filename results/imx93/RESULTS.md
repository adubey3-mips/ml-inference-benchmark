# i.MX93 CPU benchmark results

**Board:** phyBOARD-Nash-i.MX93 (NXP i.MX93, 2× Cortex-A55 @ aarch64)
**BSP:** ampliPHY PD26.1.0, kernel 6.12.34
**Runtime:** TFLite 2.19.0 (`/usr/bin/tensorflow-lite-2.19.0/examples/benchmark_model`)
**Model storage:** NFS mount at `/mnt/models` (host: 192.168.1.138)
**Config:** 2 threads, XNNPACK enabled, 5 warmup + 50 timed iterations, 3 reps per model with 30s cooldowns
**Headline metric:** median-of-3-rep-medians; flag if std across reps > 1%

Raw logs: `results/imx93/logs/`

---

## 11.2 MobileNetV2 w8a8

| Rep | Median (ms) | Thermal pre/post (C) | Log |
|---|---|---|---|
| 1 | 33.13 | 43.4 / 44.9 | `mobilenetv2_w8a8_2t_xnn_rep1_20260522_095842.log` |
| 2 | 33.08 | 43.4 / 44.9 | `mobilenetv2_w8a8_2t_xnn_rep2_20260522_095915.log` |
| 3 | 32.87 | 42.9 / 45.4 | `mobilenetv2_w8a8_2t_xnn_rep3_20260522_095948.log` |

**Median-of-medians: 33.08 ms / 30.23 fps** (std 0.43% across reps)

---
## 11.1 ResNet50 w8a8

| Rep | Median (ms) | Thermal pre/post (C) | Log |
|---|---|---|---|
| 1 | 165.57 | 44.4 / 48.4 | `resnet50_w8a8_2t_xnn_rep1_20260522_103921.log` |
| 2 | 165.09 | 43.9 / 48.4 | `resnet50_w8a8_2t_xnn_rep2_20260522_104001.log` |
| 3 | 165.18 | 43.9 / 48.4 | `resnet50_w8a8_2t_xnn_rep3_20260522_104042.log` |

**Median-of-medians: 165.18 ms / 6.05 fps** (std 0.15% across reps)

---


## 11.9 ResNet101 w8a8

| Rep | Median (ms) | Thermal pre/post (C) | Log |
|---|---|---|---|
| 1 | 314.25 | 41.9 / 46.9 | `resnet101_w8a8_2t_xnn_rep1_20260522_104755.log` |
| 2 | 313.14 | 42.4 / 47.9 | `resnet101_w8a8_2t_xnn_rep2_20260522_104844.log` |
| 3 | 314.24 | 42.4 / 47.9 | `resnet101_w8a8_2t_xnn_rep3_20260522_104933.log` |

**Median-of-medians: 314.24 ms / 3.18 fps** (std 0.20% across reps)

---
## 11.7 DeepLabV3-Plus-MobileNet w8a8

| Rep | Median (ms) | Thermal pre/post (C) | Log |
|---|---|---|---|
| 1 | 1465.58 | 41.9 / 49.9 | `deeplabv3plus_mobilenet_w8a8_2t_xnn_rep1_20260522_110147.log` |
| 2 | 1456.57 | 44.4 / 51.4 | `deeplabv3plus_mobilenet_w8a8_2t_xnn_rep2_20260522_110339.log` |
| 3 | 1459.73 | 45.4 / 51.9 | `deeplabv3plus_mobilenet_w8a8_2t_xnn_rep3_20260522_110530.log` |

**Median-of-medians: 1459.73 ms / 0.69 fps** (std 0.31% across reps)

---
## 11.5 ViT-Base fp32

| Rep | Median (ms) | Thermal pre/post (C) | Log |
|---|---|---|---|
| 1 | 3317.69 | 44.4 / 52.9 | `vit_base_fp32_2t_xnn_rep1_20260522_110917.log` |
| 2 | 3351.13 | 46.9 / 53.9 | `vit_base_fp32_2t_xnn_rep2_20260522_111255.log` |
| 3 | 3350.04 | 47.9 / 55.4 | `vit_base_fp32_2t_xnn_rep3_20260522_111631.log` |

**Median-of-medians: 3350.04 ms / 0.30 fps** (std 0.57% across reps)

Note: rep 1 was ~1% faster than reps 2-3, correlated with thermal creep
(pre-rep temp climbed 44.4 → 46.9 → 47.9 °C across reps). Within 1% std
threshold so result stands, but worth noting for fp32 workloads.

---
## 11.6 BEVDet fp32 (deviation: spec was w8a16_mixed_fp16)

| Rep | Median (ms) | Thermal pre/post (C) | Log |
|---|---|---|---|
| 1 | 30471.20 | 43.9 / 53.9 | `bevdet_fp32_2t_xnn_rep1_20260522_114615.log` |
| 2 | 30700.59 | 47.9 / 55.4 | `bevdet_fp32_2t_xnn_rep2_20260522_121447.log` |
| 3 | 30444.64 | 48.9 / 55.4 | `bevdet_fp32_2t_xnn_rep3_20260522_124327.log` |

**Median-of-medians: 30471.20 ms / 0.03 fps per scene (0.20 fps per camera)** (std 0.46% across reps)

Notes:
- Spreadsheet specified w8a16_mixed_fp16; Qualcomm only exports w8a8_mixed_fp16
  and only as ONNX (not TFLite). Using TFLite float as approved fallback.
  Mentor confirmed the quant label is not significant for this row.
- Model has 5 inputs (image `[1, 18, 256, 704]` = 6 cameras × 3 channels
  concatenated, plus 4 calibration matrices) and 6 outputs.
- Inputs were synthetic (TFLite default zero/random fill); inference time is
  data-independent for this graph topology.
- Memory peak 1423 MB on 1942 MB board (~73% used). No swap engaged.
- Pre-cool of ~10 min before this run; thermals plateaued at 55.4 C across
  reps 2-3 with no throttling signal.

---
## NPU (Ethos-U65) results

**Runtime:** TFLite 2.19.0 with `libethosu_delegate.so`, models compiled with Vela 4.3.0 (Ethos_U65_256, Ethos_U65_High_End system config, Dedicated_Sram_384KB memory mode)
**Config:** 2 host threads, Ethos-U delegate, 5 warmup + 50 timed iterations, 3 reps with 30s cooldowns
**BSP:** PD26.1.0 with True's `imx93-phycore-npu.dtso` patch (NPU memory region shifted to `0xC0000000`)

---

### 11.2 MobileNetV2 w8a8 (NPU)

| Rep | Median (ms) | Thermal pre/post (C) | Log |
|---|---|---|---|
| 1 | 6.07 | 43.4 / 43.9 | `mobilenetv2_w8a8_npu_rep1_20260601_120051.log` |
| 2 | 6.08 | 43.4 / 44.4 | `mobilenetv2_w8a8_npu_rep2_20260601_120125.log` |
| 3 | 6.07 | 43.4 / 44.4 | `mobilenetv2_w8a8_npu_rep3_20260601_120157.log` |

**Median-of-medians: 6.07 ms / 164.88 fps** (std 0.12% across reps)
CPU vs NPU speedup: 33.08 / 6.07 = **5.45×**

---
### 11.1 ResNet50 w8a8 (NPU)

| Rep | Median (ms) | Thermal pre/post (C) | Log |
|---|---|---|---|
| 1 | 27.93 | 43.9 / 44.4 | `resnet50_w8a8_npu_rep1_20260601_120520.log` |
| 2 | 27.93 | 43.9 / 44.9 | `resnet50_w8a8_npu_rep2_20260601_120553.log` |
| 3 | 27.93 | 43.9 / 44.4 | `resnet50_w8a8_npu_rep3_20260601_120626.log` |

**Median-of-medians: 27.93 ms / 35.81 fps** (std 0.01% across reps)
CPU vs NPU speedup: 165.18 / 27.93 = **5.91×**

---
### 11.9 ResNet101 w8a8 (NPU)

| Rep | Median (ms) | Thermal pre/post (C) | Log |
|---|---|---|---|
| 1 | 47.48 | 44.4 / 45.4 | `resnet101_w8a8_npu_rep1_20260601_122213.log` |
| 2 | 47.48 | 44.4 / 45.4 | `resnet101_w8a8_npu_rep2_20260601_122248.log` |
| 3 | 47.48 | 44.4 / 45.4 | `resnet101_w8a8_npu_rep3_20260601_122322.log` |

**Median-of-medians: 47.48 ms / 21.06 fps** (std 0.01% across reps)
CPU vs NPU speedup: 314.24 / 47.48 = **6.62×**

---

