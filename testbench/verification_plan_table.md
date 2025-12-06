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
