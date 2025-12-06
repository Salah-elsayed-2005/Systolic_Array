# Quick Reference: Module Test Coverage

## Systolic PE Test Checklist

| # | Test Name | Category | Status |
|---|-----------|----------|--------|
| 1 | Reset State | Reset | ✓ |
| 2 | Load Weight 0x05 | Weight Load | ✓ |
| 3 | Load Weight 0x0A (overwrite) | Weight Load | ✓ |
| 4 | Weight Hold | Control | ✓ |
| 5 | MAC (10 * 3 = 30) | Inference | ✓ |
| 6 | MAC Accumulation (10*5 + 30 = 80) | Inference | ✓ |
| 7 | Signed Mult (+10 * +12) | Signed Arith | ✓ |
| 8 | Signed Mult (+10 * -5) | Signed Arith | ✓ |
| 9 | Signed Mult (-10 * +8) | Signed Arith | ✓ |
| 10 | Signed Mult (-6 * -7) | Signed Arith | ✓ |
| 11 | Mixed Sign Accumulation | Signed Arith | ✓ |
| 12 | Positive Saturation | Saturation | ✓ |
| 13 | Negative Saturation | Saturation | ✓ |
| 14 | Accumulator Overflow Sat | Saturation | ✓ |
| 15 | Accumulator Underflow Sat | Saturation | ✓ |
| 16 | Zero Multiplication | Edge Case | ✓ |
| 17 | Input Zero Multiplication | Edge Case | ✓ |
| 18 | Sequential Weight Load | Weight Load | ✓ |
| 19 | Inference After Reset | Reset | ✓ |
| 20 | Long Accumulation | Inference | ✓ |
| 21 | Disabled Shift During Inference | Control | ✓ |

**Total: 21 tests**

## Systolic Array Test Checklist

| # | Test Name | Category | Status |
|---|-----------|----------|--------|
| 1 | Reset State | Reset | ✓ |
| 2 | Load Identity Weights | Weight Load | ✓ |
| 3 | MatVec All 1s x All 1s | Matrix Ops | ✓ |
| 4 | send2bias Gating | Control | ✓ |
| 5 | Load Sequential Weights | Weight Load | ✓ |
| 6 | MatVec Sequential Weights x All 1s | Matrix Ops | ✓ |
| 7 | Full Matrix Multiply 2x2 | Matrix Ops | ✓ |
| 8 | Signed Multiplication | Signed Arith | ✓ |
| 9 | Batch Processing | Matrix Ops | ✓ |
| 10 | Zero Input Vector | Edge Case | ✓ |
| 11 | Zero Weight Matrix | Edge Case | ✓ |
| 12 | Full Row Accumulation | Matrix Ops | ✓ |
| 13 | Pipeline Stall | Control | ✓ |
| 14 | Positive Saturation | Saturation | ✓ |
| 15 | Negative Saturation | Saturation | ✓ |
| 16 | Reset During Operation | Reset | ✓ |
| 17 | Back-to-Back Inferences | Matrix Ops | ✓ |

**Total: 17 tests**

## Bias Adder Test Checklist

| # | Test Name | Category | Status |
|---|-----------|----------|--------|
| 1 | Reset State | Reset | ✓ |
| 2 | Positive Addition (8+2=10) | Basic Ops | ✓ |
| 3 | Zero Bias | Edge Case | ✓ |
| 4 | Zero Accumulator | Edge Case | ✓ |
| 5 | Positive Saturation | Saturation | ✓ |
| 6 | Negative Addition (no sat) | Basic Ops | ✓ |
| 7 | Large Negative Saturation | Saturation | ✓ |
| 8 | Positive + Negative | Signed Arith | ✓ |
| 9 | Negative + Positive | Signed Arith | ✓ |
| 10 | All Lanes Different | Lane Independence | ✓ |
| 11 | Max Positive Value | Boundary | ✓ |
| 12 | Max Negative Value | Boundary | ✓ |
| 13 | Near Positive Saturation | Boundary | ✓ |
| 14 | Near Negative Saturation | Boundary | ✓ |
| 15 | Large Positive Overflow | Saturation | ✓ |
| 16 | Large Negative Overflow | Saturation | ✓ |
| 17 | Alternating Lane Values | Lane Independence | ✓ |
| 18 | Reset During Operation | Reset | ✓ |
| 19 | Sequential Inputs | Sequential | ✓ |
| 20 | Partial Saturation | Lane Independence | ✓ |

**Total: 20 tests**

## Activation Test Checklist

| # | Test Name | Category | Status |
|---|-----------|----------|--------|
| 1 | Reset State | Reset | ✓ |
| 2 | ReLU Positive | ReLU | ✓ |
| 3 | ReLU Negative | ReLU | ✓ |
| 4 | ReLU Zero | ReLU | ✓ |
| 5 | ReLU Large Positive | ReLU | ✓ |
| 6 | ReLU Large Negative | ReLU | ✓ |
| 7 | Binary Positive | Binary | ✓ |
| 8 | Binary Negative | Binary | ✓ |
| 9 | Binary Zero | Binary | ✓ |
| 10 | Binary Large Positive | Binary | ✓ |
| 11 | Binary Large Negative | Binary | ✓ |
| 12 | Identity Positive | Identity | ✓ |
| 13 | Identity Negative | Identity | ✓ |
| 14 | Identity Zero | Identity | ✓ |
| 15 | Identity All Bits | Identity | ✓ |
| 16 | Leaky ReLU Positive | Leaky ReLU | ✓ |
| 17 | Leaky ReLU Negative Even | Leaky ReLU | ✓ |
| 18 | Leaky ReLU Negative Odd | Leaky ReLU | ✓ |
| 19 | Leaky ReLU Zero | Leaky ReLU | ✓ |
| 20 | Leaky ReLU Large Negative | Leaky ReLU | ✓ |
| 21 | Mode Switch ReLU to Binary | Mode Switch | ✓ |
| 22 | Mode Switch Identity to Leaky ReLU | Mode Switch | ✓ |
| 23 | ReLU Boundary Positive | Boundary | ✓ |
| 24 | ReLU Boundary Negative | Boundary | ✓ |
| 25 | Invalid Mode | Edge Case | ✓ |
| 26 | Reset During Operation | Reset | ✓ |
| 27 | Sequential Mode Changes | Mode Switch | ✓ |
| 28 | ReLU Alternating Signs | Sequential | ✓ |
| 29 | Leaky ReLU Small Negative | Leaky ReLU | ✓ |
| 30 | All Modes Same Input | Comparison | ✓ |

**Total: 30 tests**

## Coverage by Category

### Across All Modules

| Category | PE | Array | Bias | Activation | Total |
|----------|-----|-------|------|------------|-------|
| Reset | 2 | 2 | 2 | 2 | 8 |
| Weight Load | 4 | 2 | - | - | 6 |
| Basic Ops | - | - | 2 | - | 2 |
| Inference/Matrix Ops | 3 | 7 | - | - | 10 |
| Control | 2 | 2 | - | - | 4 |
| Signed Arithmetic | 5 | 1 | 2 | - | 8 |
| Saturation | 4 | 2 | 6 | - | 12 |
| Edge Cases | 2 | 2 | 2 | 1 | 7 |
| Lane Independence | - | - | 3 | - | 3 |
| Boundary | - | - | 4 | 2 | 6 |
| ReLU | - | - | - | 6 | 6 |
| Binary | - | - | - | 5 | 5 |
| Identity | - | - | - | 4 | 4 |
| Leaky ReLU | - | - | - | 6 | 6 |
| Mode Switch | - | - | - | 3 | 3 |
| Sequential | - | - | 1 | 1 | 2 |
| Comparison | - | - | - | 1 | 1 |

## Critical Test Cases

### Must Pass for Integration
1. **PE Test 7-10**: Signed multiplication (all combinations)
2. **PE Test 12-15**: Saturation (multiplier and accumulator)
3. **Array Test 3, 6**: Matrix-vector operations
4. **Array Test 9**: Full matrix-matrix (batch)
5. **Bias Test 5, 7**: Saturation boundaries
6. **Bias Test 10, 17, 20**: Lane independence
7. **Activation Test 2-6**: ReLU correctness
8. **Activation Test 16-20**: Leaky ReLU with α=0.5

### Recommended Test Order
1. Run PE tests first (foundation)
2. Run Array tests (integration of PEs)
3. Run Bias Adder tests (next stage)
4. Run Activation tests (final stage)

## Known Dependencies

- **Systolic Array** depends on **Systolic PE** functionality
- **Array output** feeds into **Bias Adder**
- **Bias Adder output** feeds into **Activation**
- Bottom-up testing recommended

## Test Execution Commands

```bash
# Individual module tests
fusesoc run --target=sim ece337:cdl:systolic_pe
fusesoc run --target=sim ece337:cdl:systolic_array
fusesoc run --target=sim ece337:cdl:bias_adder
fusesoc run --target=sim ece337:cdl:activation

# View waveforms
gtkwave cdl/waves/systolic_pe/waveform.fst
gtkwave cdl/waves/systolic_array/waveform.fst
gtkwave cdl/waves/bias_adder/waveform.fst
gtkwave cdl/waves/activation/waveform.fst
```

## Expected Results

All tests should:
- Print "PASS" message
- Complete without $error messages
- Generate clean waveforms
- Finish with success summary

Example output:
```
[TEST 1: Reset State] PASS
[TEST 2: Load Weight 0x05] PASS
...
===========================================
All Systolic PE Tests Complete!
===========================================
```
