# Model Triage — i.MX93 Competition Analysis

Tracking progress sourcing TFLite models for the i.MX93 CPU benchmarking deliverable. Target column in the competition analysis spreadsheet: **i.MX93 CPU (2× Cortex-A55, 2 threads, XNNPACK)**.

Status legend:
- **Sourced** — TFLite file in hand, all parameters verified, ready to benchmark.
- **Needs conversion** — base model located but quantization/format conversion required.
- **Blocked** — no clear path to a TFLite file matching the target spec; documented why.
- **TBD** — not yet investigated.

## Triage table

| #    | Spreadsheet name                          | Architecture     | Target quant         | Input shape       | Source URL | Format found | SHA256 | Status | Notes |
|------|-------------------------------------------|------------------|----------------------|-------------------|------------|--------------|--------|--------|-------|
| 11.1 | ResNet50 w8a8 224×224                     | ResNet50         | w8a8 (int8/int8)     | 1×224×224×3       |            |              |        | TBD    |       |
| 11.2 | MobileNetV2 w8a8 224×224                  | MobileNetV2      | w8a8 (int8/int8)     | 1×224×224×3       |            |              |        | TBD    |       |
| 11.3 | MobileNetV2 w8a16 224×224                 | MobileNetV2      | w8a16 (int8/int16)   | 1×224×224×3       |            |              |        | TBD    |       |
| 11.4 | MobileNetV2 w8a16_mixed_int16 224×224     | MobileNetV2      | w8a16 mixed int16    | 1×224×224×3       |            |              |        | TBD    |       |
| 11.5 | ViT-Base                                  | ViT-Base/16      | (spec unclear — confirm) | 1×224×224×3   |            |              |        | TBD    | Spreadsheet doesn't list quant — ask mentor |
| 11.6 | BEVDet MobileNetV2 w8a16_mixed_fp16       | BEVDet (MNv2 backbone) | w8a16 mixed fp16 | 1×6×3×256×704     |            |              |        | TBD    | Multi-camera input — fps definition needs decision |
| 11.7 | DeepLabV3-Plus-MobileNet w8a8             | DeepLabV3+ (MNv2) | w8a8 (int8/int8)    | (confirm — typically 1×513×513×3 or 1×257×257×3) | |  |        | TBD    | Confirm input shape with mentor |
| 11.8 | DeepLabV3-Plus-MobileNet w8a16            | DeepLabV3+ (MNv2) | w8a16 (int8/int16)  | (same as 11.7)    |            |              |        | TBD    |       |
| 11.9 | ResNet101 w8a8 224×224                    | ResNet101        | w8a8 (int8/int8)     | 1×224×224×3       |            |              |        | TBD    |       |
| 11.10| ViT-Tiny                                  | ViT-Tiny/16      | (spec unclear — confirm) | 1×224×224×3   |            |              |        | TBD    | Same spec ambiguity as ViT-Base |

## Per-model investigation log

Use this section for free-form notes during sourcing — failed leads, conversion attempts, conversations with mentor, etc. Promote distilled facts up to the table.

### 11.1 ResNet50 w8a8

### 11.2 MobileNetV2 w8a8

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