# Model Triage — i.MX93 Competition Analysis

Tracking progress sourcing TFLite models for the i.MX93 CPU benchmarking deliverable. Target column in the competition analysis spreadsheet: **i.MX93 CPU (2× Cortex-A55, 2 threads, XNNPACK)**.

Status legend:
- **Sourced** — TFLite file in hand, all parameters verified, ready to benchmark.
- **Needs conversion** — base model located but quantization/format conversion required.
- **Blocked** — no clear path to a TFLite file matching the target spec; documented why.
- **TBD** — not yet investigated.

## Triage table

| #    | Model Name                          | Architecture     | Target quant         | Input shape       | Source URL | Format found | SHA256 | Status | Notes |
|------|-------------------------------------------|------------------|----------------------|-------------------|------------|--------------|--------|--------|-------|
| 11.1 | ResNet50 w8a8 224×224                     | ResNet50         | w8a8 (int8/int8)     | 1×224×224×3       |  https://huggingface.co/qualcomm/ResNet50          |TFLITE w8a8 (Qualcomm AI Hub, QAIRT 2.45)              |158ca1bd97b26e62c43ad0bd2f6a71e63d4342574c0e25ba7b996383d9cf1a76         |Sourced    |Smoke-tested on board, ~166ms with 2t+XNNPACK       |
| 11.2 | MobileNetV2 w8a8 224×224                  | MobileNetV2      | w8a8 (uint8/uint8)    | 1×224×224×3       |https://huggingface.co/qualcomm/MobileNet-v2            |TFLITE w8a8 (Qualcomm AI Hub, QAIRT 2.45)              | ce69c99c2b30       |Sourced    |Smoke-tested on board, ~33ms with 2t+XNNPACK       |
| 11.3 | MobileNetV2 w8a16 224×224                 | MobileNetV2      | w8a16 (int8/int16)   | 1×224×224×3       |            |              |        | TBD    |       |
| 11.4 | MobileNetV2 w8a16_mixed_int16 224×224     | MobileNetV2      | w8a16 mixed int16    | 1×224×224×3       |            |              |        | TBD    |       |
| 11.5 | ViT-Base                                  | ViT-Base/16      | (spec unclear — confirm) | 1×224×224×3   |            |              |        | TBD    | Spreadsheet doesn't list quant — ask mentor |
| 11.6 | BEVDet MobileNetV2 w8a16_mixed_fp16       | BEVDet (MNv2 backbone) | w8a16 mixed fp16 | 1×6×3×256×704     |            |              |        | TBD    | Multi-camera input — fps definition needs decision |
| 11.7 | DeepLabV3-Plus-MobileNet w8a8             | DeepLabV3+ (MNv2) | w8a8 (int8/int8)    | (confirm — typically 1×513×513×3 or 1×257×257×3) | |  |        | TBD    | Confirm input shape with mentor |
| 11.8 | DeepLabV3-Plus-MobileNet w8a16            | DeepLabV3+ (MNv2) | w8a16 (int8/int16)  | (same as 11.7)    |            |              |        | TBD    |       |
| 11.9 | ResNet101 w8a8 224×224                    | ResNet101        | w8a8 (int8/int8)     | 1×224×224×3       |            |              |        | TBD    |       |
| 11.10| ViT-Tiny                                  | ViT-Tiny/16      | (spec unclear — confirm) | 1×224×224×3   |            |              |        | TBD    | Same spec ambiguity as ViT-Base |

## Per-model investigation log

### 11.1 ResNet50 w8a8
- Downloaded: <05/20/2026> from https://huggingface.co/qualcomm/ResNet50
- File: resnet50-tflite-w8a8.zip (21M zipped, 26.3M extracted)
- SHA256: 158ca1bd97b26e62c43ad0bd2f6a71e63d4342574c0e25ba7b996383d9cf1a76
- Auxiliary files preserved in models/aux/resnet50_w8a8/ (metadata.json, labels.txt — ImageNet 1000 classes)
- Inspect: input uint8 [1,224,224,3] scale=1/255 zp=0; output uint8 [1,1000] scale=0.164 zp=51
- No custom ops; XNNPACK delegate applied cleanly on Ubuntu and on board
- Smoke test (2 threads, XNNPACK, 3+7 iters): avg 165.7ms, std 0.5ms, init 205ms
- Model is fully sourced and validated.

### 11.2 MobileNetV2 w8a8
- Downloaded: <05/20/2026> from https://huggingface.co/qualcomm/MobileNet-v2
- File: mobilenet_v2-tflite-w8a8.zip (3.3M zipped, 4.0M extracted)
- SHA256: ce69c99c2b307d45b03c1bd5ccdd3ee8b66e9cf704c087c6db76d78340c90d71
- Aux files: models/aux/mobilenetv2_w8a8/ (metadata.json, labels.txt — same ImageNet 1000 labels)
- Inspect: input uint8 [1,224,224,3] scale=1/255 zp=0; output uint8 [1,1000] scale=0.171 zp=63
- No custom ops; XNNPACK applied with 36 delegate kernels (depthwise-separable architecture splits heavily)
- Smoke test (2t XNNPACK, 15+31 iters): avg 33.2ms, std 105μs, init 40ms
- Note: page listed model size as "w8a16: 4.39 MB" but file is uint8/uint8 = w8a8; treating as page typo
- Status: Sourced and validated.

### 11.3 MobileNetV2 w8a16

### 11.4 MobileNetV2 w8a16_mixed_int16

### 11.5 ViT-Base

### 11.6 BEVDet

### 11.7 DeepLabV3-Plus-MobileNet w8a8

### 11.8 DeepLabV3-Plus-MobileNet w8a16

### 11.9 ResNet101 w8a8

### 11.10 ViT-Tiny

## Open questions for mentor

- ViT-Base and ViT-Tiny rows in the spreadsheet don't specify quantization — what's the target? (Assume w8a8 for parity with the rest, or match what Hexagon ran?)
- DeepLabV3+ input resolution — spreadsheet doesn't list it. Confirm.
- BEVDet "fps" — should reported value be scenes/sec or per-camera-frames/sec (6× scenes)?
- For models we cannot source or convert in reasonable time, is "could not source — see notes" acceptable in the spreadsheet cell, or should we substitute a nearest-equivalent model?

## Verification protocol (applied per sourced model)

Before promoting a row to **Sourced**, confirm via Python script (`scripts/verify_model.py`, TBD):

1. Input shape matches target.
2. Input/output dtype matches quantization claim.
3. Quantization scheme via `interpreter.get_input_details()` / `get_output_details()` `quantization_parameters`.
4. Single inference runs without operator errors.
5. Output shape and value range pass sanity check (not all zeros, no NaN).

## Transfer protocol

1. Download to `~/ml-inference-benchmark/models/` on Ubuntu.
2. `sha256sum` and record in table.
3. Run verification script on Ubuntu.
4. `scp` to i.MX93 (target dir TBD — likely `/home/root/models/` or similar).
5. `sha256sum` on board, confirm match.
6. Smoke-test with `benchmark_model` (1 thread, 1 iter) before full benchmarking run.