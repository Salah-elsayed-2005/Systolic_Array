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
 - 15: End-to-end sequencing: correct high-level operation order (weights → load → inputs → start → infer → poll → retrieve).
 - 16: Weight transfer completeness: all required weights delivered to subordinate.
 - 17: Weight load indication: accelerator reflects weight loading progress/status.
 - 18: Input transfer completeness: all input vectors delivered to subordinate.
 - 19: Start inference control: subordinate starts operation when commanded.
 - 20: Completion polling: status correctly indicates inference completion when done.
 - 21: Output retrieval: data can be read back correctly after completion.

## Verification Plan Table

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
