# Verification Plan Table — data_buffer

## Criteria Definitions

- 1: RW writes to weight/input buffers update SRAM correctly; read-back returns written data.
- 2: Address indexing: weight_num and in_num correctly map to SRAM slot addresses [2:0].
- 3: Dual SRAM path (ram_w1/ram_w2): lower 32-bit and upper 32-bit writes/reads concatenate correctly to form 64-bit sram_data.
- 4: sram_state output: reflects state from active SRAM operation (ram_w1_state for weight, ram_in1_state for input, ram_out1_state for output).
- 5: Store output path: out_actv driven to output SRAMs (ram_out1/ram_out2); sram_data reflects out_actv; sram_state from ram_out1_state.
- 6: Buffer slot independence: write/read to one weight/input slot does not affect other slots.
- 7: Read-after-write (RAW) hazard: consecutive read following write to same slot returns updated data if SRAM latency allows visibility.
- 8: Reset behaviour: on n_rst low, all enables/addresses/outputs reset; after n_rst release, buffer is idle and sram_state is 00.
- 9: Data concatenation on read: {read_*2_data, read_*1_data} correctly forms 64-bit sram_data with upper 32-bit and lower 32-bit.
- 10: Multiplexing correctness: only one of write_w_enable, write_in_enable, read_w_enable, read_in_enable, store_output asserted per cycle; priority/arbitration respected.
- 11: Write path correctness: write_w1_data and write_w2_data receive lower and upper 32-bits of data respectively.
- 12: Read path correctness: read_w1_data and read_w2_data from respective SRAMs are concatenated to sram_data during read_w_enable.

## Verification Plan Table

Module Tested | Feature Tested | Test Name | Criteria Number | Description of Test Inputs | Description of Expected Outputs
--- | --- | --- | ---: | --- | ---
`data_buffer` | Basic RW | Write Weight (64-bit) | 1, 2, 11 | Write 0xDEAD_BEEF_CAFE_BABE to weight_num=0 with write_w_enable=1. | write_w1_enable and write_w2_enable asserted; write_w1_data = 0xCAFE_BABE (lower), write_w2_data = 0xDEAD_BEEF (upper); address_w1/w2[2:0] = 0; sram_state reflects sram_w1_state.
`data_buffer` | Basic RW | Read Weight (64-bit) | 1, 2, 3, 9, 12 | Read from weight_num=0 with read_w_enable=1 after prior write. | read_w1_enable and read_w2_enable asserted; address_w1/w2[2:0] = 0; sram_data = {read_w2_data, read_w1_data}; returns 0xDEAD_BEEF_CAFE_BABE.
`data_buffer` | Basic RW | Write Input (64-bit) | 1, 2, 11 | Write 0x1122_3344_5566_7788 to in_num=1 with write_in_enable=1. | write_in1_enable and write_in2_enable asserted; write_in1_data = 0x5566_7788 (lower), write_in2_data = 0x1122_3344 (upper); address_in1/in2[2:0] = 1; sram_state reflects sram_in1_state.
`data_buffer` | Basic RW | Read Input (64-bit) | 1, 2, 3, 9, 12 | Read from in_num=1 with read_in_enable=1 after prior write. | read_in1_enable and read_in2_enable asserted; address_in1/in2[2:0] = 1; sram_data = {read_in2_data, read_in1_data}; returns 0x1122_3344_5566_7788.
`data_buffer` | Slot independence | Write to All Weight Slots | 2, 6, 11 | Write distinct 64-bit patterns to weight_num = 0..7 sequentially. | Each slot receives its own write at correct address; write enables toggled per slot.
`data_buffer` | Slot independence | Read All Weight Slots | 2, 6, 9, 12 | Read from weight_num = 0..7 sequentially after prior writes. | Each read returns correct unique data for its slot without cross-slot contamination; addresses increment [2:0] correctly.
`data_buffer` | Slot independence | Write to All Input Slots | 2, 6, 11 | Write distinct 64-bit patterns to in_num = 0..7 sequentially. | Each slot receives its own write at correct address; write enables toggled per slot.
`data_buffer` | Slot independence | Read All Input Slots | 2, 6, 9, 12 | Read from in_num = 0..7 sequentially after prior writes. | Each read returns correct unique data for its slot without cross-slot contamination; addresses increment [2:0] correctly.
`data_buffer` | Output store path | Store Activation Output | 1, 4, 5, 9, 11 | Assert store_output with out_actv = 0x0011_2233_4455_6677. | write_out1_enable and write_out2_enable asserted; write_out1_data = 0x4455_6677 (lower), write_out2_data = 0x0011_2233 (upper); sram_data = out_actv; sram_state reflects sram_out1_state.
`data_buffer` | sram_state output | sram_state during weight write | 4 | Write weight with write_w_enable=1. | sram_state driven to sram_w1_state (expected 00 or 01 during operation, 10 when ready).
`data_buffer` | sram_state output | sram_state during input read | 4 | Read input with read_in_enable=1. | sram_state driven to sram_in1_state (expected 00 or 01 during operation, 10 when ready).
`data_buffer` | sram_state output | sram_state during store output | 4 | Store output with store_output=1. | sram_state driven to sram_out1_state (expected 00 or 01 during operation, 10 when ready).
`data_buffer` | RAW hazard | Write then immediately read weight | 7 | Write 0xABCD_EF12_3456_7890 to weight_num=5; assert read_w_enable next cycle. | If SRAM exposes RAW visibility, sram_data returns written data within SRAM latency; behavior documented per design SRAM spec.
`data_buffer` | RAW hazard | Write then immediately read input | 7 | Write 0x1111_2222_3333_4444 to in_num=6; assert read_in_enable next cycle. | If SRAM exposes RAW visibility, sram_data returns written data within SRAM latency; behavior documented per design SRAM spec.
`data_buffer` | Reset behaviour | Reset clears state | 8 | Assert n_rst low during active transaction; release n_rst. | All enables deasserted after reset; sram_state = 00; buffer set to initial state; next operation behaves normally.
`data_buffer` | Data integrity | End-to-end: write weights, write inputs, read both | 1, 2, 6, 9, 11, 12 | Write weight slots 0..3, write input slots 0..3, read all back. | All operations complete successfully; correct data returned for each slot; no corruption; addresses and enables correct.