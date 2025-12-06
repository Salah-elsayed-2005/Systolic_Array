Systolic PE Verification Plan

Overview
- Goal: Validate functional behavior of `systolic_pe` module including weight loading, MAC operations, data shifting, and saturation logic.
- Approach: Directed testcases exercised via `tb_systolic_pe.sv` with comprehensive coverage of operational modes and edge cases.

Test Matrix Summary

- RESET STATE
  - What: Verify all outputs are zero after reset.
  - Why: Ensure proper initialization of weight register, accumulator, and shift register.
  - Part: Reset logic, register initialization.

- WEIGHT LOADING: SINGLE
  - What: Load a single weight value (0x05) with shift_enable=1 and operate_f=0.
  - Why: Verify weight register captures input during weight loading phase.
  - Part: Weight register next-state logic, load_w signal generation.

- WEIGHT LOADING: MULTIPLE
  - What: Load multiple weight values sequentially (0x0A after 0x05).
  - Why: Confirm weight register can be overwritten and updates correctly.
  - Part: Weight register update logic.

- WEIGHT HOLDING
  - What: Set shift_enable=0 during weight loading phase.
  - Why: Verify weight register holds its value when shift_enable is deasserted.
  - Part: Weight register hold logic.

- INFERENCE: SINGLE MAC
  - What: Perform single multiply-accumulate operation (10 * 3 = 30).
  - Why: Validate basic MAC functionality during inference phase (operate_f=1).
  - Part: Multiplier operation, accumulator logic, operate_f control.

- INFERENCE: ACCUMULATION
  - What: Perform multiple MAC operations accumulating results (10*3 + 10*5 = 80).
  - Why: Verify accumulator correctly accumulates products across cycles.
  - Part: Accumulator next-state logic, accumulation path.

- SIGNED MULTIPLICATION: POS × POS
  - What: Multiply positive weight (+10) by positive input (+12) = +120.
  - Why: Validate signed multiplication for positive operands.
  - Part: Multiplier signed arithmetic, sign extension.

- SIGNED MULTIPLICATION: POS × NEG
  - What: Multiply positive weight (+10) by negative input (-5) = -50.
  - Why: Verify correct signed multiplication with mixed signs.
  - Part: Multiplier handling of negative values.

- SIGNED MULTIPLICATION: NEG × POS
  - What: Multiply negative weight (-10) by positive input (+8) = -80.
  - Why: Validate signed multiplication with negative weight.
  - Part: Multiplier sign handling for weight operand.

- SIGNED MULTIPLICATION: NEG × NEG
  - What: Multiply negative weight (-6) by negative input (-7) = +42.
  - Why: Confirm negative × negative yields positive result.
  - Part: Multiplier two's complement arithmetic.

- MIXED SIGN ACCUMULATION
  - What: Accumulate 5*10 = 50, then 5*(-8) = -40, total = 10.
  - Why: Verify accumulator handles mixed sign results correctly.
  - Part: Accumulator signed addition logic.

- MULTIPLIER: POSITIVE SATURATION
  - What: Multiply 127 * 2 = 254, should saturate to 127.
  - Why: Validate multiplier saturation at INT8_MAX.
  - Part: Multiplier saturation logic for positive overflow.

- MULTIPLIER: NEGATIVE SATURATION
  - What: Multiply -128 * 2 = -256, should saturate to -128.
  - Why: Validate multiplier saturation at INT8_MIN.
  - Part: Multiplier saturation logic for negative overflow.

- ACCUMULATOR: POSITIVE OVERFLOW
  - What: Accumulate 120 + 120 = 240, should saturate to 127.
  - Why: Verify accumulator positive overflow saturation.
  - Part: Accumulator saturation logic, 9-bit intermediate sum.

- ACCUMULATOR: NEGATIVE OVERFLOW
  - What: Accumulate -120 + -120 = -240, should saturate to -128.
  - Why: Verify accumulator negative overflow saturation.
  - Part: Accumulator saturation logic for negative values.

- ZERO MULTIPLICATION: WEIGHT ZERO
  - What: Multiply weight=0 by input=50, result = 0.
  - Why: Confirm zero weight produces zero product.
  - Part: Multiplier zero handling.

- ZERO MULTIPLICATION: INPUT ZERO
  - What: Multiply weight=25 by input=0, result = 0.
  - Why: Confirm zero input produces zero product.
  - Part: Multiplier zero input handling.

- SEQUENTIAL WEIGHT LOADING
  - What: Load weights 1, 2, 3 sequentially and verify shifting.
  - Why: Validate horizontal weight shifting during load phase.
  - Part: Shift register operation during weight loading, shifted output.

- INFERENCE AFTER RESET
  - What: Perform inference, then reset, verify accumulator cleared.
  - Why: Confirm reset properly clears accumulator mid-operation.
  - Part: Reset behavior, accumulator clear.

- LONG ACCUMULATION SEQUENCE
  - What: Accumulate 2*1 + 2*2 + 2*3 + 2*4 = 20.
  - Why: Verify accumulator maintains correctness over extended sequence.
  - Part: Accumulator sequential operation.

- DISABLED SHIFT DURING INFERENCE
  - What: Start inference, disable shift_enable, verify accumulation stops.
  - Why: Validate shift_enable control during inference phase.
  - Part: Control signal interaction, accumulator enable logic.

Functional Aspects Covered
- Weight loading and holding: Correct capture and retention of weights.
- Weight shifting: Horizontal propagation during loading phase.
- Input shifting: Horizontal propagation during inference phase.
- MAC operation: Multiply-accumulate functionality.
- Signed arithmetic: Proper handling of signed 8-bit values.
- Saturation: Both multiplier and accumulator overflow/underflow protection.
- Mode control: Proper behavior switching between load and inference.
- Reset behavior: Clearing of all state.

Out-of-Scope / Not Explicitly Tested
- Combinational timing: Relies on synthesis and timing analysis.
- Multiple PE interaction: Tested at systolic_array level.
- Back-pressure from downstream: Not applicable to PE design.

Future Enhancements
- Add random testing for exhaustive sign/magnitude combinations.
- Add corner case testing for saturation boundaries (126+1, -127-1).
- Add power-on state verification beyond reset.

Pass/Fail Criteria
- All MAC operations produce correct mathematical results.
- Saturation occurs exactly at INT8_MAX (127) and INT8_MIN (-128).
- Weight loading and shifting work correctly in both phases.
- Reset clears all state properly.
- Control signals properly gate operations.
