# Verification Plan Table — AHB Subordinate CDL

## Criteria Definitions

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

## Verification Plan Table

Module Tested | Feature Tested | Test Name | Criteria Number | Description of Test Inputs | Description of Expected Outputs
--- | --- | --- | --- | --- | ---
`ahb_subordinate_cdl` | Basic RW writes | Write Weights/Inputs/Bias (64-bit) | 1, 2 | Write 64-bit values to weights at address 0x00, inputs at address 0x08, and bias at address 0x10 with maximum transfer size. | Weights, inputs, and bias registers update to the written values. store_weights and store_inputs signals assert for the write events. Observed timing shows correct address and data phase relationship (pipelining).
`ahb_subordinate_cdl` | Busy signaling | Set Buffer Busy | 3 | Assert buffer busy prior to subsequent transactions. | Device busy state is reflected in status; error bit for device busy is set when applicable; any reads that should stall due to buffer conditions show hready de-assertion behavior consistent with busy handling.
`ahb_subordinate_cdl` | Buffer occupancy error | Write Weights while Buffer Busy | 4 | With buffer busy asserted, attempt to write a full-width value to weights at address 0x00. | Buffer occupancy error bit (lower byte bit 0) is set. The weights register does not change (write blocked). The transfer exhibits busy behavior (stall) as appropriate.
`ahb_subordinate_cdl` | Bias read and error clear | Read Bias; Clear Error Low; Clear Error High | 5 | Read bias at address 0x10 with maximum size. Then read error lower byte at address 0x20 and error upper byte at address 0x21. | Bias returns the most recently written value. After reading the lower error byte, the buffer occupancy error bit clears. After reading the upper error byte, the device busy error bit clears. Both bytes clear according to which byte is read.
`ahb_subordinate_cdl` | Illegal access protection | Read Weights (Write-Only) | 6 | Read weights at address 0x00 with maximum size. | The access is rejected: error response asserted and ready de-asserts during the error. No valid data is produced; weights content remains unchanged.
`ahb_subordinate_cdl` | Illegal access protection | Write Output (Read-Only) | 6 | Write a full-width value to output at address 0x18. | The access is rejected: error response asserted and ready de-asserts during the error. Output content remains sourced by the systolic output only.
`ahb_subordinate_cdl` | Sliced writes | Input Slice Write (2 bytes) | 7 | Write two bytes to inputs at address 0x0D using a two-byte transfer size. | Only the targeted two bytes within the inputs register are modified at the correct offset; all other bytes remain unchanged.
`ahb_subordinate_cdl` | Sliced writes | Bias Slice Write (4 bytes) | 7 | Write four bytes to bias at address 0x12 using a four-byte transfer size. | The four bytes update the correct slice within the bias register at the computed offset; surrounding bytes remain unchanged.
`ahb_subordinate_cdl` | RAW hazards | Read Bias after Slice Write | 8 | Perform a sliced write to bias as above, then immediately read two bytes overlapping the modified region at an adjacent address (e.g., 0x11). | The immediate read returns the in-flight updated data for the overlapping bytes, demonstrating RAW hazard handling; bytes outside the overlap reflect previous register values.
`ahb_subordinate_cdl` | Control behavior | Set Start Inference | 9 | Write a value with bit 0 set to the control register at address 0x22 (one-byte access). | The control register updates and the start_inference signal asserts high.
`ahb_subordinate_cdl` | RAW hazards (control) | Read Control Immediately | 8, 9 | Immediately read back the control register at address 0x22 after writing. | The read returns the just-written control value, confirming RAW hazard behavior on the control path.
`ahb_subordinate_cdl` | Control auto-clear | Data Ready De-asserts Start | 9 | Assert data ready after start_inference is high. | Start_inference de-asserts automatically, indicating processing completion and readiness to fetch output data.
`ahb_subordinate_cdl` | Output/Status/Error update | Design Busy and Systolic Output | 3, 11 | Assert design busy and drive the systolic output to a known value (all ones). | Output register reflects the driven systolic output. Status indicates design busy. Error status for device busy is set as defined. Any read-dependent stalls occur per busy logic.
`ahb_subordinate_cdl` | Status read timing | Read Status | 3, 11 | Read status at address 0x23 as a single byte. | The fetched status byte reflects current flags (e.g., data ready and design busy) and is returned with correct read timing.
`ahb_subordinate_cdl` | Activation behavior | Write Activation | 10 | Write a single-byte activation value to address 0x24. | Activation register updates and actv_mode reflects the lower bits of the activation value.
`ahb_subordinate_cdl` | RAW hazards (activation) | Read Activation Immediately | 8, 10 | Immediately read activation at address 0x24 after writing. | The read returns the just-written activation value, demonstrating RAW hazard handling for activation.
`ahb_subordinate_cdl` | Output RO read | Read Output Data | 11 | Read output at address 0x18 with maximum size after driving a known systolic output value. | The returned data matches the systolic output value. If buffer busy is active, read may stall appropriately.
`ahb_subordinate_cdl` | Design-busy write blocking | Write Weights while Design Busy | 12 | With design busy asserted, attempt to write a full-width value to weights at address 0x00. | The write is blocked and weights do not change; any busy-related ready behavior appears as defined.
`ahb_subordinate_cdl` | Burst INCR | Weights Burst INCR8 (bytes) | 13 | Issue an incrementing burst of eight byte-wide writes starting at address 0x00. | Addresses increment per beat and bytes are placed correctly into the weights register across the sequence; final register content matches the burst data order.
`ahb_subordinate_cdl` | Burst INCR | Bias Burst INCR4 (halfwords) | 13 | Issue an incrementing burst of four halfword-wide writes starting at address 0x10. | Addresses increment correctly and halfwords align properly within the bias register; final content matches the provided sequence.
`ahb_subordinate_cdl` | Burst WRAP | Bias Burst Read WRAP8 (bytes) | 14 | Issue a wrapping burst read of eight byte beats starting at address 0x12. | Read addresses wrap correctly within the designated region, and the returned byte sequence matches the expected wrapped order and alignment.

# Verification Plan Table (Plain English)

## Criteria
- C1: Register writes update values and assert the appropriate store signals (weights/inputs/bias).
- C2: AHB pipelining shows correct timing between address and data phases during transfers.
- C3: Busy signaling reflects device conditions; status and error flags update; ready signal may stall under busy conditions.
- C4: Buffer occupancy error sets the corresponding flag and prevents writes when buffer is busy.
- C5: Error register clears individual flags when the corresponding byte is read.
- C6: Read-only and write-only protection generates the correct error response and timing on illegal accesses.
- C7: Sliced writes correctly update only the targeted portion of a register based on address and size.
- C8: Read-after-write (RAW) hazards return the most recent written value when a read overlaps a write in the same cycle.
- C9: Control register drives start of inference and automatically clears when data becomes ready.
- C10: Activation register updates mode and supports immediate readback via RAW behavior.
- C11: Output path mirrors the accelerator output and reads correctly; may stall while buffers are busy.
- C12: Design busy blocks writes to protected regions.
- C13: Incrementing burst transfers (INCR8/INCR4) place data with correct alignment and address progression.
- C14: Wrapping burst transfers (WRAP8) follow correct address wrapping and return correctly ordered read data.


Module Tested | Feature Tested | Test Name | Criteria Number | Description of Test Inputs | Description of Expected Outputs
--- | --- | --- | --- | --- | ---
`ahb_subordinate_cdl` | Basic register writes | Write weights/inputs/bias (full width) | C1, C2 | Perform normal register writes to the weights, inputs, and bias regions using full-width transfers in a clean (non-busy) condition. | The corresponding registers update to the written values; the appropriate store signals assert for the weights and inputs; address and data phases align correctly.
`ahb_subordinate_cdl` | Busy signaling | Assert buffer busy | C3 | Place the device in a buffer-busy condition prior to transactions. | Busy state is reflected in status; device busy error flag is set as defined; ready signal may de-assert under conditions specified by the design.
`ahb_subordinate_cdl` | Buffer occupancy error | Write while buffer busy | C4 | Attempt a normal write to the weights region while the buffer is busy. | Buffer occupancy error flag asserts; the write does not update the register; ready signal behavior reflects the stall condition.
 `ahb_subordinate_cdl` | Bias read and error clear | Read bias; clear error low and high | C5 | Read the bias register normally; then read the lower byte of the error register; then read the upper byte of the error register. | Bias returns the stored value; reading the lower byte clears the buffer occupancy flag; reading the upper byte clears the device busy flag.
`ahb_subordinate_cdl` | Access protection (read-only/write-only) | Read weights (read blocked) | C6 | Perform a read access to the weights region, which is designated write-only. | Error response is generated; ready signal de-asserts during the error; no valid data is produced.
`ahb_subordinate_cdl` | Access protection (read-only/write-only) | Write output (write blocked) | C6 | Perform a write access to the output region, which is designated read-only. | Error response is generated; ready signal de-asserts during the error; the output register remains unchanged.
`ahb_subordinate_cdl` | Sliced writes | Partial write to inputs | C7 | Perform a two-byte write targeting an offset within the inputs region. | Only the intended two bytes of the inputs register are modified; all other bytes remain unchanged.
`ahb_subordinate_cdl` | Sliced writes | Partial write to bias | C7 | Perform a four-byte write targeting an offset within the bias region. | Only the intended four bytes of the bias register are modified; all other bytes remain unchanged.
`ahb_subordinate_cdl` | RAW hazard handling | Read bias after partial write | C8 | Perform a partial write to the bias register; immediately perform a read that overlaps the modified portion. | The read returns the most recent written values for the overlapped bytes and previous values elsewhere, demonstrating raw hazard handling.
`ahb_subordinate_cdl` | Control signaling | Start inference via control | C9 | Write a value enabling the start of inference in the control register. | The start inference output signal asserts; control reflects the command.
`ahb_subordinate_cdl` | RAW hazard handling (control) | Immediate read of control after write | C8, C9 | After enabling start inference, immediately read the control register. | The read returns the just-written control value, demonstrating raw hazard read behavior.
`ahb_subordinate_cdl` | Auto-clear control | Data becomes ready | C9 | Assert the data-ready condition following a start command. | The start inference signal automatically de-asserts, indicating completion and readiness for data fetch.
`ahb_subordinate_cdl` | Output and status update | Device busy with valid output | C3, C11 | Assert device busy and provide a full-scale output value from the accelerator. | The output register mirrors the provided output; status reflects busy; error flags update per the busy logic.
`ahb_subordinate_cdl` | Status read timing | Read status register | C3, C11 | Read the status register while busy and data-ready conditions are active. | The returned status value matches the set bits; the timing aligns with the AHB read behavior.
`ahb_subordinate_cdl` | Activation updates | Write activation mode | C10 | Write a mode value to the activation register under normal conditions. | The activation register updates and the mode output reflects the written value.
`ahb_subordinate_cdl` | RAW hazard handling (activation) | Immediate read of activation after write | C8, C10 | After writing activation, immediately read the activation register. | The read returns the just-written activation value, demonstrating raw hazard read behavior.
`ahb_subordinate_cdl` | Output RO read | Read output value | C11 | Read the output region after providing a known accelerator output. | The read returns the expected output value; if buffers are busy, ready signal may de-assert per design.
`ahb_subordinate_cdl` | Design busy write blocking | Write while design busy | C12 | Attempt to write to the weights region while design busy is asserted. | The write is blocked and does not update the register; interface behavior reflects the busy condition.
`ahb_subordinate_cdl` | Burst INCR correctness | Incrementing burst write to weights | C13 | Perform an incrementing burst write of eight beats targeting the weights region with byte-sized transfers. | Data is placed correctly across bytes with proper address progression; final register content matches the sequence of inputs.
`ahb_subordinate_cdl` | Burst INCR correctness | Incrementing burst write to bias | C13 | Perform an incrementing burst write of four beats targeting the bias region with halfword-sized transfers. | Data is placed correctly across halfwords with proper address progression; final register content matches the sequence of inputs.
`ahb_subordinate_cdl` | Burst WRAP correctness | Wrapping burst read from bias | C14 | Perform a wrapping burst read of eight beats from an offset within the bias region with byte-sized transfers. | The read sequence follows the correct wrapping of addresses and returns data in the expected wrapped order.
