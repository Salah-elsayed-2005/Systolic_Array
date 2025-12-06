# Verification Plan Table — CDL Module Verification

## Criteria Definitions

### AHB Subordinate Criteria (1-21)
- 1: RW writes update registers; store_weights/store_inputs assert correctly.
- 2: AHB pipelining between address and data phases is correct.
- 3: Busy signaling: device busy reflected; hready behavior matches busy paths.
- 4: Buffer occupancy error: write during buffer busy sets error bit and blocks write.
- 5: Error clear semantics: reading low/high error bytes clears respective bits.
- 6: Illegal access protection: correct hresp/hready behavior for write-only/read-only regions.
- 7: Sliced writes update only targeted bytes per address and size.
- 8: RAW hazard handling: immediate read after write returns in-flight updated value.
- 9: Control behavior: start_inference goes high on write and auto-clears when data_ready.
- 10: Activation behavior: activation value drives actv_mode and supports RAW read.
- 11: Output RO path: output matches systolic_out; stalls when buffer busy.
- 12: Design-busy write blocking: writes suppressed while design_busy is active.
- 13: Burst INCR correctness: addresses increment and data aligned for INCR8/INCR4.
- 14: Burst WRAP correctness: addresses wrap correctly; read sequence aligned for WRAP8.
- 15: End-to-end sequencing: correct high-level operation order (weights → load → inputs → start → infer → poll → retrieve).
- 16: Weight transfer completeness: all required weights delivered to subordinate.
- 17: Weight load indication: accelerator reflects weight loading progress/status.
- 18: Input transfer completeness: all input vectors delivered to subordinate.
- 19: Start inference control: subordinate starts operation when commanded.
- 20: Completion polling: status correctly indicates inference completion when done.
- 21: Output retrieval: data can be read back correctly after completion.

### Systolic PE Criteria (22-42)
- 22: Reset clears all PE state (weight, accumulator, shift registers).
- 23: Weight loading: weight register captures input when shift_enable=1 and operate_f=0.
- 24: Weight holding: weight register retains value when shift_enable=0.
- 25: Horizontal shift: shifted output correctly propagates input/weight during respective phases.
- 26: MAC operation: multiply-accumulate produces correct mathematical result.
- 27: Signed multiplication: correct handling of all sign combinations (pos×pos, pos×neg, neg×pos, neg×neg).
- 28: Multiplier saturation: products outside [-128, 127] saturate to INT8_MIN/MAX.
- 29: Accumulator operation: sequential accumulation maintains correct sum across cycles.
- 30: Accumulator saturation: sums outside [-128, 127] saturate to INT8_MIN/MAX.
- 31: Zero multiplication: zero operands produce zero products.
- 32: Mode control: operate_f correctly switches between weight-load and inference phases.
- 33: Pipeline control: shift_enable gates operations correctly in both phases.

### Systolic Array Criteria (34-47)
- 34: Reset clears all 64 PEs and output collection logic.
- 35: Weight loading: column-wise weight distribution over 8 cycles to all rows.
- 36: Input staggering: proper wavefront propagation with cycle-by-cycle row activation.
- 37: Horizontal data flow: inputs propagate left-to-right through PE array.
- 38: Vertical accumulation: partial sums accumulate top-to-bottom through columns.
- 39: Output collection: col_sums correctly gathers bottom-row PE accumulators.
- 40: Matrix-vector operation: correct computation for staggered vector inputs.
- 41: Matrix-matrix operation: correct full 8×8 matrix multiply with batch inputs.
- 42: send2bias gating: sum_to_bias output correctly gated by send2bias signal.
- 43: Control distribution: shift_enable and operate_f broadcast correctly to all PEs.
- 44: Sparse matrix handling: correct operation with partial array utilization.
- 45: Pipeline stall/resume: array can pause and resume without data corruption.
- 46: Array-level saturation: PE saturation propagates correctly to outputs.
- 47: Sequential inference: back-to-back operations maintain or clear state as designed.

### Bias Adder Criteria (48-58)
- 48: Reset clears all 8 output lane registers.
- 49: Parallel addition: all 8 lanes compute independently and simultaneously.
- 50: Signed addition: correct two's complement arithmetic for all sign combinations.
- 51: Positive saturation: sums > 127 saturate to 127 (INT8_MAX).
- 52: Negative saturation: sums < -128 saturate to -128 (INT8_MIN).
- 53: Lane isolation: operations in one lane don't affect other lanes.
- 54: Boundary values: correct handling at saturation boundaries (±127, ±128).
- 55: Zero operands: correct pass-through when bias or accumulator is zero.
- 56: Output registration: results properly clocked through output registers.
- 57: Partial saturation: some lanes saturate while others compute normally.
- 58: Sequential operation: correct behavior over consecutive clock cycles.

### Activation Criteria (59-70)
- 59: Reset clears output register.
- 60: ReLU mode: positive values pass through, negative values clamp to zero.
- 61: Binary mode: outputs 1 for non-negative, 0 for negative (sign-based classification).
- 62: Identity mode: all input values pass through unchanged.
- 63: Leaky ReLU mode: positive pass through, negative scaled by α=0.5 (arithmetic right shift).
- 64: Mode selection: activation_mode correctly selects between 4 activation functions.
- 65: Sign detection: MSB correctly interpreted for signed value classification.
- 66: Arithmetic shift: sign-preserving right shift for Leaky ReLU negative values.
- 67: Zero handling: zero treated correctly in each activation mode.
- 68: Mode switching: transitions between modes update output correctly on next cycle.
- 69: Invalid mode: undefined modes default to safe behavior (Identity).
- 70: Output registration: activation results properly clocked through output register.


## Verification Plan Table

### AHB Subordinate Module Tests

Module Tested | Feature Tested | Test Name | Criteria Number | Description of Test Inputs | Description of Expected Outputs
--- | --- | --- | --- | --- | ---
`ahb_subordinate_cdl` | Basic RW writes | Write Weights (64-bit) | 1, 2 | Write a 64-bit value to weights at address 0x00 using the maximum transfer size. | Weights register updates to the written value and store_weights asserts for the write event. Address and data phases occur with correct pipelining timing.
`ahb_subordinate_cdl` | Basic RW writes | Write Inputs (64-bit) | 1, 2 | Write a 64-bit value to inputs at address 0x08 using the maximum transfer size. | Inputs register updates to the written value and store_inputs asserts for the write event. Address and data phases occur with correct pipelining timing.
`ahb_subordinate_cdl` | Basic RW writes | Write Bias (64-bit) | 1, 2 | Write a 64-bit value to bias at address 0x10 using the maximum transfer size. | Bias register updates to the written value. Address and data phases occur with correct pipelining timing.
`ahb_subordinate_cdl` | Busy signaling | Set Buffer Busy | 3 | Assert buffer busy prior to subsequent transactions. | Device busy state is reflected as defined; error bit for device busy may be set; any reads that should stall due to buffer conditions show hready de-assertion behavior consistent with busy handling.
`ahb_subordinate_cdl` | Buffer occupancy error | Write Weights while Buffer Busy | 4 | With buffer busy asserted, attempt to write a full-width value to weights at address 0x00. | Buffer occupancy error bit (lower byte bit 0) is set. The weights register does not change (write is blocked). The transfer exhibits busy-related stall behavior.
`ahb_subordinate_cdl` | Bias read | Read Bias (64-bit) | 5 | Read bias at address 0x10 using the maximum transfer size. | Returned data equals the most recently written bias value and confirms normal read behavior.
`ahb_subordinate_cdl` | Error clear | Read Error Lower Byte | 5 | Read the lower byte of the error register at address 0x20 as a single byte. | Buffer occupancy error flag (bit 0) clears as a result of reading the lower byte.
`ahb_subordinate_cdl` | Error clear | Read Error Upper Byte | 5 | Read the upper byte of the error register at address 0x21 as a single byte. | Device busy error flag (bit 8) clears as a result of reading the upper byte.
`ahb_subordinate_cdl` | Illegal access protection | Read Weights (Write-Only Region) | 6 | Attempt to read weights at address 0x00 using the maximum transfer size. | The access is rejected with an error response and ready de-assertion during the error; weights content remains unchanged.
`ahb_subordinate_cdl` | Illegal access protection | Write Output (Read-Only Region) | 6 | Attempt to write a full-width value to output at address 0x18. | The access is rejected with an error response and ready de-assertion during the error; output content remains sourced by the systolic output only.
`ahb_subordinate_cdl` | Sliced writes | Input Slice Write (2 bytes) | 7 | Write two bytes to inputs at address 0x0D using a two-byte transfer size. | Only the targeted two bytes within the inputs register are modified at the correct offset; other bytes remain unchanged.
`ahb_subordinate_cdl` | Sliced writes | Bias Slice Write (4 bytes) | 7 | Write four bytes to bias at address 0x12 using a four-byte transfer size. | The four bytes update the correct slice within the bias register at the computed offset; surrounding bytes remain unchanged.
`ahb_subordinate_cdl` | RAW hazards | Read Bias after Slice Write | 8 | After performing a sliced write to bias, immediately read two bytes overlapping the modified region at address 0x11. | The immediate read returns the in-flight updated data for overlapping bytes, demonstrating RAW hazard handling; bytes outside the overlap reflect prior register values.
`ahb_subordinate_cdl` | Control behavior | Set Start Inference | 9 | Write a single byte with bit 0 set to the control register at address 0x22. | Control register updates and the start_inference signal asserts high.
`ahb_subordinate_cdl` | RAW hazards (control) | Read Control Immediately | 8, 9 | Immediately read back the control register at address 0x22 after setting bit 0. | The read returns the just-written control value, confirming RAW hazard behavior on the control path.
`ahb_subordinate_cdl` | Control auto-clear | Data Ready De-asserts Start | 9 | Assert data ready after start_inference is high. | Start_inference de-asserts automatically, indicating processing completion and readiness to fetch output data.
`ahb_subordinate_cdl` | Output/Status/Error update | Design Busy and Systolic Output | 3, 11 | Assert design busy and drive the systolic output to a known value (all ones). | Output register reflects the driven systolic output. Status indicates design busy. Error status for device busy is set as defined. Read-dependent stalls occur per busy logic when applicable.
`ahb_subordinate_cdl` | Status read timing | Read Status | 3, 11 | Read status at address 0x23 as a single byte while data ready and design busy are asserted. | The fetched status byte reflects current flags (e.g., data ready and design busy) and is returned with correct read timing.
`ahb_subordinate_cdl` | Activation behavior | Write Activation | 10 | Write a single-byte activation value to address 0x24. | Activation register updates and actv_mode reflects the lower bits of the activation value.
`ahb_subordinate_cdl` | RAW hazards (activation) | Read Activation Immediately | 8, 10 | Immediately read activation at address 0x24 after writing the new value. | The read returns the just-written activation value, demonstrating RAW hazard handling for activation.
`ahb_subordinate_cdl` | Output RO read | Read Output Data | 11 | Read output at address 0x18 with maximum size after driving a known systolic output value. | Returned data matches the systolic output value. If buffer busy is active, read may stall appropriately.
`ahb_subordinate_cdl` | Design-busy write blocking | Write Weights while Design Busy | 12 | With design busy asserted, attempt to write a full-width value to weights at address 0x00. | The write is blocked and weights do not change; any busy-related ready behavior appears as defined.
`ahb_subordinate_cdl` | Burst INCR | Weights Burst INCR8 (bytes) | 13 | Issue an incrementing burst of eight byte-wide writes starting at address 0x00. | Addresses increment per beat and bytes are placed correctly into the weights register across the sequence; final register content matches the burst data order.
`ahb_subordinate_cdl` | Burst INCR | Bias Burst INCR4 (halfwords) | 13 | Issue an incrementing burst of four halfword-wide writes starting at address 0x10. | Addresses increment correctly and halfwords align properly within the bias register; final content matches the provided sequence.
`ahb_subordinate_cdl` | Burst WRAP | Bias Burst Read WRAP8 (bytes) | 14 | Issue a wrapping burst read of eight byte beats starting at address 0x12. | Read addresses wrap correctly within the designated region, and the returned byte sequence matches the expected wrapped order and alignment.
`ahb_accelerator` | End-to-end sequencing | E2E: Weight Transfer Phase | 15, 16 | System initiates an inference operation and transfers all required weight data to the subordinate via the weights address range (0x00–0x07). | Subordinate receives the complete set of weights, reflected by weights register contents and store_weights activity; overall operation flow remains in the weight transfer phase.
`ahb_accelerator` | Weight loading | E2E: Accelerator Loads Weights | 15, 17 | Accelerator loads the transferred weights into the systolic array after the transfer phase. | Status reflects the loading activity as designed; when loading completes, indicators show ready state for subsequent input transfer.
`ahb_accelerator` | Polling status | E2E: Poll for Weight Load Completion | 15, 17 | System polls the status register to detect completion of weight loading before proceeding. | Status transitions from busy/loading to ready; polling observes the correct completion indication, allowing progression to input phase.
`ahb_accelerator` | Input transfer | E2E: Input Vectors Transfer | 15, 18 | System transfers the input vectors to the subordinate via the inputs address range (0x08–0x0F). | Subordinate inputs register content reflects all vectors delivered; store_inputs activity occurs for each transfer; system completes input phase.
`ahb_accelerator` | Start inference | E2E: Command Start Inference | 15, 19 | System sets the start command in the control register (bit 0) to begin inference. | Start_inference asserts; system transitions to inference phase; control reflects the commanded start.
`ahb_accelerator` | Inference execution | E2E: Accelerator Performs Operation | 15, 19 | Accelerator runs the operation after start is commanded. | Design busy status indicates active inference; systolic array processes input vectors using loaded weights.
`ahb_accelerator` | Completion polling | E2E: Poll for Inference Completion | 15, 20 | System polls the status register until inference completion is indicated. | Status transitions to indicate completion; polling detects completion without ambiguity, enabling data retrieval.
`ahb_accelerator` | Output retrieval | E2E: Retrieve Output Data | 15, 21 | System reads back results from the output address range (0x18–0x1F) after completion. | Output data reads return the computed results; read timing is correct; data integrity matches expected inference output for the given inputs and weights.

### Systolic PE Module Tests

Module Tested | Feature Tested | Test Name | Criteria Number | Description of Test Inputs | Description of Expected Outputs
--- | --- | --- | --- | --- | ---
`systolic_pe` | Reset state | Reset State Verification | 22 | Apply asynchronous reset (n_rst=0) followed by release. | All outputs (shifted, out_acc) are zero; internal registers (weight, accumulator, shift) cleared.
`systolic_pe` | Weight loading | Load Weight 0x05 | 23 | Set in=0x05, shift_enable=1, operate_f=0 for one cycle. | Weight register captures 0x05; shifted output shows 0x05; accumulator remains 0.
`systolic_pe` | Weight loading | Load Weight 0x0A (overwrite) | 23 | After loading 0x05, set in=0x0A, shift_enable=1, operate_f=0 for one cycle. | Weight register updates to 0x0A (overwrites previous); shifted output shows 0x0A.
`systolic_pe` | Weight holding | Weight Hold Test | 24 | Load weight 0x0A, then set shift_enable=0, in=0xFF for one cycle. | Weight register retains 0x0A (not overwritten by 0xFF); shifted output unchanged.
`systolic_pe` | Horizontal shift | Shifted Output During Load | 25 | During weight load phase (operate_f=0), apply sequence of inputs with shift_enable=1. | Shifted output propagates weights horizontally; each cycle outputs the loaded weight value.
`systolic_pe` | MAC operation | MAC (10 × 3 = 30) | 26 | Load weight=10, then set in=3, shift_enable=1, operate_f=1 for one cycle. | Accumulator outputs 30 (10×3); shifted output passes input value 3.
`systolic_pe` | MAC operation | MAC Accumulation (10×5 + 30) | 26, 29 | After accumulator has 30, apply in=5 with same weight=10 and operate_f=1. | Accumulator outputs 80 (30 + 10×5); demonstrates sequential accumulation.
`systolic_pe` | Signed multiplication | Signed Mult (+10 × +12) | 27 | Load positive weight +10, multiply by positive input +12. | Product is +120; verifies positive × positive signed multiplication.
`systolic_pe` | Signed multiplication | Signed Mult (+10 × -5) | 27 | Load positive weight +10, multiply by negative input -5. | Product is -50; verifies positive × negative signed multiplication.
`systolic_pe` | Signed multiplication | Signed Mult (-10 × +8) | 27 | Load negative weight -10, multiply by positive input +8. | Product is -80; verifies negative × positive signed multiplication.
`systolic_pe` | Signed multiplication | Signed Mult (-6 × -7) | 27 | Load negative weight -6, multiply by negative input -7. | Product is +42; verifies negative × negative yields positive result.
`systolic_pe` | Mixed sign accumulation | Mixed Sign Accumulation | 27, 29 | Load weight=5; first multiply by +10 (acc=50), then by -8 (acc=10). | Accumulator correctly handles mixed-sign sequential operations: 50 + (5×-8) = 10.
`systolic_pe` | Multiplier saturation | Positive Saturation | 28 | Load weight=127 (INT8_MAX), multiply by input=2. | Product saturates to 127 (not 254); multiplier implements positive saturation.
`systolic_pe` | Multiplier saturation | Negative Saturation | 28 | Load weight=-128 (INT8_MIN), multiply by input=2. | Product saturates to -128 (not -256); multiplier implements negative saturation.
`systolic_pe` | Accumulator saturation | Accumulator Overflow Saturation | 30 | Load weight=10; accumulate 10×12=120, then add another 10×12=120. | Accumulator saturates to 127 (not 240); demonstrates positive overflow protection.
`systolic_pe` | Accumulator saturation | Accumulator Underflow Saturation | 30 | Load weight=-10; accumulate -10×12=-120 twice. | Accumulator saturates to -128 (not -240); demonstrates negative overflow protection.
`systolic_pe` | Zero multiplication | Zero Weight Multiplication | 31 | Load weight=0, multiply by non-zero input=50. | Product is 0; verifies zero weight handling.
`systolic_pe` | Zero multiplication | Zero Input Multiplication | 31 | Load non-zero weight=25, multiply by input=0. | Product is 0; verifies zero input handling.
`systolic_pe` | Sequential loading | Sequential Weight Loading | 23, 25 | Load weights 1, 2, 3 sequentially with shift_enable=1, operate_f=0. | Each weight loads correctly; shifted output shows progression; demonstrates pipeline shifting.
`systolic_pe` | Reset behavior | Inference After Reset | 22 | Perform inference (acc=63), then reset, then check outputs. | After reset, accumulator is 0; all state cleared regardless of prior operation.
`systolic_pe` | Long sequence | Long Accumulation Sequence | 29 | Load weight=2; perform MAC with inputs 1,2,3,4 sequentially. | Final accumulator value is 20 (2×1 + 2×2 + 2×3 + 2×4); maintains correctness over extended sequence.
`systolic_pe` | Pipeline control | Disabled Shift During Inference | 33 | Start inference with shift_enable=1, then disable shift_enable mid-operation. | When shift_enable=0, accumulation stops; accumulator holds previous value; demonstrates enable control.

### Systolic Array Module Tests

Module Tested | Feature Tested | Test Name | Criteria Number | Description of Test Inputs | Description of Expected Outputs
--- | --- | --- | --- | --- | ---
`systolic_array` | Reset state | Reset State Verification | 34 | Apply asynchronous reset (n_rst=0) to entire array. | All col_sums outputs are zero; all 64 PEs cleared; sum_to_bias is zero.
`systolic_array` | Weight loading | Load Identity Weights | 35 | Load uniform weights (all 1s) via in_bus over 8 cycles with shift_enable=1, operate_f=0. | Weights propagate through all rows in each column; each PE in rightmost column loaded after 8 cycles.
`systolic_array` | Matrix-vector operation | MatVec All 1s × All 1s | 36, 37, 38, 39, 40 | With weights=1, input staggered vector of 1s (one per row per cycle). | Each column accumulates to 1; col_sums = 0x0101010101010101; demonstrates proper wavefront.
`systolic_array` | Control signal | send2bias Gating | 42 | With valid col_sums, toggle send2bias between 0 and 1. | When send2bias=0, sum_to_bias=0; when send2bias=1, sum_to_bias equals col_sums; confirms gating.
`systolic_array` | Weight loading | Load Sequential Weights | 35 | Load weights 1-8 sequentially per row via in_bus=0x0807060504030201 over 8 cycles. | Each row in array receives its designated weight value; demonstrates varied weight loading.
`systolic_array` | Matrix-vector operation | MatVec Sequential Weights × All 1s | 40 | With sequential weights, input staggered vector of all 1s. | col_sums = 0x0807060504030201; each column outputs its weight value.
`systolic_array` | Sparse matrix | Full Matrix Multiply 2×2 | 44 | Use only 2×2 subregion (top-left); load weights accordingly, input 2 staggered values. | Only first two columns produce non-zero outputs; unused PEs remain at zero; demonstrates partial utilization.
`systolic_array` | Signed operation | Signed Multiplication | 27, 46 | Load negative weight=-5 in row 0, multiply by positive input=4. | Column 0 output is -20 (0xEC); demonstrates signed arithmetic through array.
`systolic_array` | Matrix-matrix operation | Batch Processing | 41 | Load weights=2 uniformly; input 8 staggered vectors with values 1-8. | Each column accumulates 2×(row_value); col_sums = 0x100E0C0A08060402; demonstrates full 8×8 operation.
`systolic_array` | Zero handling | Zero Input Vector | 31, 40 | Load non-zero weights=5; input all-zero vector. | All col_sums are zero; demonstrates zero propagation through array.
`systolic_array` | Zero handling | Zero Weight Matrix | 31, 35 | Load all-zero weights; input non-zero vector values=10. | All col_sums are zero; demonstrates zero weight behavior across array.
`systolic_array` | Full utilization | Full Row Accumulation | 38, 41 | Load uniform weights=1; simultaneously input value=1 to all rows for 15 cycles. | Each column accumulates 8 products (8×1×1=8); col_sums = 0x0808080808080808; stress test.
`systolic_array` | Pipeline control | Pipeline Stall | 45 | Start inference, disable shift_enable for 3 cycles, then re-enable. | Array pauses computation during stall; resumes correctly; final result matches expected (accounting for delay).
`systolic_array` | Saturation propagation | Positive Saturation | 46 | Load weight=127 (max); multiply by input=2 to trigger PE saturation. | col_sums show saturation values (0x7F...); PE-level saturation propagates to array output.
`systolic_array` | Saturation propagation | Negative Saturation | 46 | Load weight=-128 (min); multiply by input=2 to trigger PE saturation. | col_sums show saturation values (0x80...); negative saturation propagates correctly.
`systolic_array` | Reset behavior | Reset During Operation | 34 | Start inference mid-operation (cycle 2), then apply reset. | All col_sums return to zero; array state completely cleared regardless of operation phase.
`systolic_array` | Sequential inference | Back-to-Back Inferences | 47 | Perform first inference (input=1), then immediately perform second inference (input=2) without reset. | Accumulators continue accumulating; col_sums = 3 (1+2 per column); demonstrates accumulator persistence.

### Bias Adder Module Tests

Module Tested | Feature Tested | Test Name | Criteria Number | Description of Test Inputs | Description of Expected Outputs
--- | --- | --- | --- | --- | ---
`bias_adder` | Reset state | Reset State Verification | 48 | Apply asynchronous reset (n_rst=0). | All 8 output lanes (out_b) are zero; output registers cleared.
`bias_adder` | Parallel addition | Positive Addition (8+2=10) | 49, 50 | Apply out_acc=0x0808... (8 in all lanes), bias=0x0202... (2 in all lanes). | out_b=0x0A0A... (10 in all lanes); demonstrates basic parallel signed addition.
`bias_adder` | Zero operand | Zero Bias | 55 | Apply out_acc=0x0505... (5 in all lanes), bias=0x0000... (all zero). | out_b=0x0505...; accumulator passes through unchanged when bias is zero.
`bias_adder` | Zero operand | Zero Accumulator | 55 | Apply out_acc=0x0000... (all zero), bias=0x0707... (7 in all lanes). | out_b=0x0707...; bias passes through when accumulator is zero.
`bias_adder` | Positive saturation | Positive Saturation | 51, 54 | Apply out_acc=0x7F7F... (127 in all lanes), bias=0x0101... (1 in all lanes). | out_b=0x7F7F... (127); sum 128 saturates to INT8_MAX (127).
`bias_adder` | Negative addition | Negative Addition (no sat) | 50 | Apply out_acc=0xFEFE... (-2 in all lanes), bias=0xFEFE... (-2 in all lanes). | out_b=0xFCFC... (-4); demonstrates negative addition without saturation.
`bias_adder` | Negative saturation | Large Negative Saturation | 52, 54 | Apply out_acc=0x8080... (-128 in all lanes), bias=0xFFFF... (-1 in all lanes). | out_b=0x8080... (-128); sum -129 saturates to INT8_MIN (-128).
`bias_adder` | Mixed signs | Positive + Negative | 50 | Apply out_acc=0x0A0A... (+10), bias=0xFBFB... (-5). | out_b=0x0505... (+5); demonstrates two's complement addition with sign change.
`bias_adder` | Mixed signs | Negative + Positive | 50 | Apply out_acc=0xF6F6... (-10), bias=0x0F0F... (+15). | out_b=0x0505... (+5); demonstrates negative + positive yielding positive.
`bias_adder` | Lane independence | All Lanes Different Values | 49, 53 | Apply out_acc=0x0807060504030201 (different per lane), bias=0x0101... (uniform 1). | out_b=0x0908070605040302; each lane independently computes acc[i]+1; no cross-talk.
`bias_adder` | Boundary values | Max Positive Value | 54 | Apply out_acc=0x7F7F... (+127), bias=0x0000... (0). | out_b=0x7F7F... (+127); boundary value passes through correctly without saturation.
`bias_adder` | Boundary values | Max Negative Value | 54 | Apply out_acc=0x8080... (-128), bias=0x0000... (0). | out_b=0x8080... (-128); boundary value passes through correctly without saturation.
`bias_adder` | Near saturation | Near Positive Saturation | 54 | Apply out_acc=0x7E7E... (+126), bias=0x0101... (+1). | out_b=0x7F7F... (+127); exactly at boundary, no false saturation; result is 127.
`bias_adder` | Near saturation | Near Negative Saturation | 54 | Apply out_acc=0x8181... (-127), bias=0xFFFF... (-1). | out_b=0x8080... (-128); exactly at boundary, no false saturation; result is -128.
`bias_adder` | Large overflow | Large Positive Overflow | 51 | Apply out_acc=0x7F7F... (+127), bias=0x7F7F... (+127). | out_b=0x7F7F... (+127); sum 254 saturates to 127; large overflow handling.
`bias_adder` | Large overflow | Large Negative Overflow | 52 | Apply out_acc=0x8080... (-128), bias=0x8080... (-128). | out_b=0x8080... (-128); sum -256 saturates to -128; large underflow handling.
`bias_adder` | Lane independence | Alternating Lane Values | 49, 53 | Apply out_acc alternating -10/+10 per lane, bias=0x0505... (uniform +5). | out_b alternates -5/+15; each lane computes independently with no interference.
`bias_adder` | Reset behavior | Reset During Operation | 48 | Apply non-zero inputs, clock once, then reset mid-operation. | After reset, all out_b lanes return to zero; state cleared regardless of inputs.
`bias_adder` | Sequential operation | Sequential Different Inputs | 58 | Apply first input pair (1+1), clock; then second pair (5+10), clock. | First cycle out_b=0x0202...; second cycle out_b=0x0F0F...; demonstrates sequential updates.
`bias_adder` | Partial saturation | One Lane Saturates, Others Don't | 53, 57 | Apply out_acc=0x7F0A050302010101, bias=0x0101... (uniform +1). | Lane 7 saturates to 0x7F; others add normally (0x0B,0x06,0x04,0x03,0x02,0x02,0x02); lane isolation verified.

### Activation Module Tests

Module Tested | Feature Tested | Test Name | Criteria Number | Description of Test Inputs | Description of Expected Outputs
--- | --- | --- | --- | --- | ---
`activation` | Reset state | Reset State Verification | 59 | Apply asynchronous reset (n_rst=0). | Output register is zero (out=0); module initialized.
`activation` | ReLU mode | ReLU Positive Input | 60, 65, 67 | Set activation_mode=3'b000 (ReLU), apply positive input in=0x0A0A... | out=0x0A0A...; positive values pass through unchanged in ReLU mode.
`activation` | ReLU mode | ReLU Negative Input | 60, 65 | Set activation_mode=3'b000 (ReLU), apply negative input in=-1. | out=0; negative values clamp to zero in ReLU mode.
`activation` | ReLU mode | ReLU Zero Input | 60, 67 | Set activation_mode=3'b000 (ReLU), apply zero input in=0. | out=0; zero treated as non-negative (passes as zero).
`activation` | ReLU mode | ReLU Large Positive | 60 | Set activation_mode=3'b000 (ReLU), apply in=0x7F7F... (+127). | out=0x7F7F...; boundary positive value passes through ReLU unchanged.
`activation` | ReLU mode | ReLU Large Negative | 60 | Set activation_mode=3'b000 (ReLU), apply in=0x8080... (-128). | out=0; boundary negative value clamps to zero in ReLU.
`activation` | Binary mode | Binary Positive Input | 61, 65 | Set activation_mode=3'b001 (Binary), apply positive input in=0x0A0A... | out=1; positive input produces binary output of 1.
`activation` | Binary mode | Binary Negative Input | 61, 65 | Set activation_mode=3'b001 (Binary), apply negative input in=-1. | out=0; negative input produces binary output of 0.
`activation` | Binary mode | Binary Zero Input | 61, 67 | Set activation_mode=3'b001 (Binary), apply zero input in=0. | out=1; zero treated as non-negative, outputs 1 in binary mode.
`activation` | Binary mode | Binary Large Positive | 61 | Set activation_mode=3'b001 (Binary), apply in=0x7F7F... (+127). | out=1; boundary positive produces binary 1.
`activation` | Binary mode | Binary Large Negative | 61 | Set activation_mode=3'b001 (Binary), apply in=0x8080... (-128). | out=0; boundary negative produces binary 0.
`activation` | Identity mode | Identity Positive Input | 62 | Set activation_mode=3'b010 (Identity), apply arbitrary positive in=0x1234... | out=0x1234...; input passes through unchanged in Identity mode.
`activation` | Identity mode | Identity Negative Input | 62 | Set activation_mode=3'b010 (Identity), apply negative in=-10. | out=-10; negative value passes through unchanged in Identity mode.
`activation` | Identity mode | Identity Zero Input | 62, 67 | Set activation_mode=3'b010 (Identity), apply zero in=0. | out=0; zero passes through unchanged.
`activation` | Identity mode | Identity All Bits Set | 62 | Set activation_mode=3'b010 (Identity), apply in=0xFFFF... | out=0xFFFF...; all bit patterns preserved in Identity mode.
`activation` | Leaky ReLU mode | Leaky ReLU Positive | 63, 65 | Set activation_mode=3'b011 (Leaky ReLU), apply positive in=8. | out=8; positive values pass through unchanged in Leaky ReLU.
`activation` | Leaky ReLU mode | Leaky ReLU Negative Even | 63, 66 | Set activation_mode=3'b011 (Leaky ReLU), apply negative even in=-8. | out=-4; arithmetic right shift by 1 (α=0.5): -8>>>1 = -4.
`activation` | Leaky ReLU mode | Leaky ReLU Negative Odd | 63, 66 | Set activation_mode=3'b011 (Leaky ReLU), apply negative odd in=-9. | out=-5; arithmetic right shift rounds toward negative: -9>>>1 = -5.
`activation` | Leaky ReLU mode | Leaky ReLU Zero | 63, 67 | Set activation_mode=3'b011 (Leaky ReLU), apply zero in=0. | out=0; zero passes through unchanged.
`activation` | Leaky ReLU mode | Leaky ReLU Large Negative | 63, 66 | Set activation_mode=3'b011 (Leaky ReLU), apply in=-128. | out=-64; -128>>>1 = -64 (0xC0); boundary negative scaling.
`activation` | Mode switching | Mode Switch ReLU to Binary | 64, 68 | Apply in=0x0505...; first cycle mode=ReLU, second cycle mode=Binary. | First cycle out=0x0505...; second cycle out=1; demonstrates mode transition.
`activation` | Mode switching | Mode Switch Identity to Leaky ReLU | 64, 68 | Apply in=-10; first cycle mode=Identity, second cycle mode=Leaky ReLU. | First cycle out=-10; second cycle out=-5; mode switching updates output correctly.
`activation` | Edge cases | ReLU Boundary Positive | 60 | Set mode=ReLU, apply in=+1 (just above zero). | out=+1; boundary case at positive edge passes through.
`activation` | Edge cases | ReLU Boundary Negative | 60 | Set mode=ReLU, apply in=-1 (just below zero). | out=0; boundary case at negative edge clamps to zero.
`activation` | Invalid mode | Invalid Mode Default | 64, 69 | Set activation_mode=3'b111 (invalid), apply in=0x1111... | out=0x1111...; invalid mode defaults to Identity (safe passthrough).
`activation` | Reset behavior | Reset During Operation | 59 | Apply non-zero input with active mode, then reset mid-operation. | After reset, out=0; register cleared regardless of current operation.
`activation` | Sequential modes | Sequential Mode Changes | 64, 68 | Apply same input in=0x0F0F...; cycle through ReLU→Binary→Identity modes. | Each mode change updates output correctly: ReLU(0x0F0F)→Binary(1)→Identity(0x0F0F).
`activation` | Sequential inputs | ReLU Alternating Signs | 60, 65 | Set mode=ReLU; apply positive in=0x0A0A..., then negative in=0xF6F6... | First cycle out=0x0A0A...; second cycle out=0; ReLU responds correctly to sign changes.
`activation` | Leaky ReLU edge | Leaky ReLU Small Negative | 63, 66 | Set mode=Leaky ReLU, apply small negative in=-2. | out=-1; -2>>>1 = -1; small magnitude scaling verified.
`activation` | Mode comparison | All Modes Same Input | 64 | Apply same positive in=0x1010...; test each of 4 modes sequentially. | ReLU(0x1010), Binary(1), Identity(0x1010), Leaky(0x1010); characterizes each mode's behavior.

