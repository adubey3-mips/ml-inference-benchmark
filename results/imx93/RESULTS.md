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
