AHB Subordinate Verification Plan

Overview
- Goal: Validate functional behavior of `ahb_subordinate_cdl` against AHB-lite protocol interactions and peripheral-specific register map.
- Approach: Directed testcases exercised via `tb_ahb_subordinate_cdl.sv` and `ahb_model_updated` BFM, with status tags marking logical scenarios.

Test Matrix Summary
- WRITE: WEIGHTS/INPUTS/BIAS
  - What: 64-bit writes to weights (`0x00`), inputs (`0x08`), bias (`0x10`).
  - Why: Verify address decoding, byte-lane alignment by `HSIZE`, and data capture into internal registers.
  - Part: Write path decode, `weight_next/input_next/bias_next`, `store_weights/store_inputs` side-effects.

- READ: BIAS+ERROR
  - What: Read bias register and error register bytes (`0x20` low, `0x21` high) while `buffer_busy=1`.
  - Why: Validate read decode, correct slicing by `HSIZE`, and error flags set/cleared based on `buffer_busy/design_busy`.
  - Part: Read path decode, `error_next` generation, `r_hready` throttling when buffer busy.

- READ: WEIGHTS (ERR)
  - What: Attempt read of weights space (`0x00`...`0x0F`).
  - Why: Confirm `HRESP` error generation for read-only violations per map.
  - Part: `HRESP_LOGIC` addressing checks, response muxing and timing.

- WRITE: OUTPUT (ERR)
  - What: Attempt write to output register space (`0x18`...`0x1F`).
  - Why: Ensure writes to read-only output generate `HRESP` error.
  - Part: `HRESP_LOGIC` write error case, `HREADY_LOGIC` gating.

- WRITE: INPUT SLICE
  - What: Partial-width write to inputs (halfword at offset within `0x08` page).
  - Why: Verify correct byte enables and `store_inputs` bitmap reflects affected bytes.
  - Part: Input write slicing, `store_inputs` generation.

- WRITE/READ: BIAS+INPUT RAW
  - What: Write to bias slice then immediate read from inputs overlapping recent write window.
  - Why: Exercise RAW hazard check (`is_raw`) and ensure latest write data is visible on subsequent read when overlapping.
  - Part: Data hazard handling, `is_raw` computation using address/data-phase alignment.

- WRITE/READ: CONTROL RAW
  - What: Write control (`0x22`) then read back.
  - Why: Validate control register write path, immediate visibility (RAW) and correct field placement within `HRDATA[23:16]`.
  - Part: Control register decode and staging, RAW visibility logic.

- READ: STATUS/ACTIV/OUTPUT
  - What: With `data_ready=1`, `design_busy=1`, set `systolic_out=all 1s`; read status (`0x23`), activation (`0x24`) after a write, and output (`0x18`).
  - Why: Check status bit mapping, activation read-after-write behavior, and output register read-only path.
  - Part: Status generation, activation register handling, output sourcing from `systolic_out`.

- BURST: INCR8 (weights)
  - What: 8-beat incrementing burst write starting at `0x00` using byte transfers.
  - Why: Validate acceptance of NONSEQ+SEQ beats, master-supplied `HADDR` per beat, and cumulative write into weights.
  - Part: Burst handling via `(HTRANS==NONSEQ||SEQ)`, address-phase decode each beat, no internal address generator.

- BURST: INCR4 (bias)
  - What: 4-beat incrementing burst write to bias using halfword transfers.
  - Why: Confirm proper handling of multi-beat writes with different `HSIZE` and correct placement.
  - Part: Write path slicing and alignment across sequential beats.

- BURST: WRAP8 (read)
  - What: 8-beat wrapping burst read starting mid-page (e.g., `0x12`).
  - Why: Ensure slave follows master-provided addresses including wrap behavior and returns correct data slices.
  - Part: Read decode on each beat, HRDATA muxing per current address phase.

Protocol/Behavior Aspects Covered
- Address-phase vs data-phase alignment: Read path uses current address phase; write path uses registered address (`haddr_reg`).
- `HRESP` generation: Errors for invalid reads/writes per map.
- `HREADY` gating: Deassert when read/write side reports not ready (`buffer_busy`) or on `HRESP`.
- Burst handling: Accepts NONSEQ+SEQ beats; relies on master `HADDR` (no internal address incrementer).
- RAW hazards: Read-after-write visibility when overlapping address ranges.
- Status/Error: Correct bit setting from `data_ready/design_busy/buffer_busy` and clear-on-read behavior for error bytes.

Out-of-Scope / Not Explicitly Tested
- BUSY/IDLE `HTRANS` beats: Current tests don’t insert BUSY bubbles; the design ignores BUSY, which is protocol-correct.
- HBURST-specific constraints: No rejection of particular burst types beyond address decode.
- End-of-burst side effects: No beat counter; design does not require EoB actions.

Future Enhancements
- Add BUSY insertion sequences to confirm no side effects.
- Add fixed-length burst end tracking if needed for side-effect timing.
- Extend coverage for misaligned accesses and partial overlaps across page boundaries.

Pass/Fail Criteria
- All directed reads/writes return expected `HRDATA` and update internal state accordingly.
- Error cases assert `HRESP` and gate `HREADY` when appropriate.
- Burst sequences complete with correct data placement per beat and size.