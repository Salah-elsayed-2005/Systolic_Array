Bias Adder Verification Plan

Overview
- Goal: Validate functional behavior of `bias_adder` module including parallel 8-lane signed addition with saturation.
- Approach: Directed testcases exercised via `tb_bias_adder.sv` covering addition scenarios, saturation boundaries, and mixed-sign operations.

Test Matrix Summary

- RESET STATE
  - What: Verify all output lanes are zero after reset.
  - Why: Ensure proper initialization of output registers.
  - Part: Reset logic, register initialization across all 8 lanes.

- SIMPLE POSITIVE ADDITION
  - What: Add positive values (8+2=10) across all lanes.
  - Why: Validate basic addition functionality without saturation.
  - Part: Signed addition logic, lane separation, output registration.

- ZERO BIAS
  - What: Add zero bias to non-zero accumulator values.
  - Why: Verify accumulator pass-through when bias is zero.
  - Part: Addition with zero operand, identity case.

- ZERO ACCUMULATOR
  - What: Add non-zero bias to zero accumulator.
  - Why: Confirm bias-only output when accumulator is zero.
  - Part: Addition with zero accumulator, bias pass-through.

- POSITIVE SATURATION
  - What: Add 127 + 1 = 128, should saturate to 127.
  - Why: Validate positive overflow saturation at INT8_MAX.
  - Part: Saturation detection logic, 9-bit intermediate sum, positive clamp.

- NEGATIVE ADDITION (NO SATURATION)
  - What: Add -2 + -2 = -4 (within range).
  - Why: Verify negative addition without saturation.
  - Part: Signed arithmetic with negative operands.

- LARGE NEGATIVE SATURATION
  - What: Add -128 + -1 = -129, should saturate to -128.
  - Why: Validate negative overflow saturation at INT8_MIN.
  - Part: Saturation detection logic, negative clamp.

- MIXED SIGNS: POSITIVE + NEGATIVE
  - What: Add 10 + -5 = 5.
  - Why: Verify correct signed addition with positive acc and negative bias.
  - Part: Two's complement addition, sign handling.

- MIXED SIGNS: NEGATIVE + POSITIVE
  - What: Add -10 + 15 = 5.
  - Why: Validate signed addition with negative acc and positive bias.
  - Part: Two's complement addition with result sign change.

- ALL LANES DIFFERENT VALUES
  - What: Add different accumulator values (1-8) to uniform bias (1).
  - Why: Confirm independent operation of all 8 lanes.
  - Part: Lane isolation, parallel computation, no cross-lane interference.

- BOUNDARY: MAX POSITIVE VALUE
  - What: Pass through maximum positive value (127) with zero bias.
  - Why: Verify correct handling of boundary value without saturation.
  - Part: Boundary value propagation.

- BOUNDARY: MAX NEGATIVE VALUE
  - What: Pass through maximum negative value (-128) with zero bias.
  - Why: Verify correct handling of boundary value without saturation.
  - Part: Boundary value propagation.

- NEAR POSITIVE SATURATION
  - What: Add 126 + 1 = 127 (exactly at boundary, no saturation).
  - Why: Validate correct computation at saturation boundary.
  - Part: Boundary detection, no false saturation.

- NEAR NEGATIVE SATURATION
  - What: Add -127 + -1 = -128 (exactly at boundary, no saturation).
  - Why: Confirm correct computation at negative boundary.
  - Part: Boundary detection, no false negative saturation.

- LARGE POSITIVE OVERFLOW
  - What: Add 127 + 127 = 254, should saturate to 127.
  - Why: Verify saturation with large positive overflow.
  - Part: Large overflow detection, saturation logic.

- LARGE NEGATIVE OVERFLOW
  - What: Add -128 + -128 = -256, should saturate to -128.
  - Why: Validate saturation with large negative overflow.
  - Part: Large negative overflow detection.

- ALTERNATING LANE VALUES
  - What: Lanes alternate between positive and negative, uniform bias.
  - Why: Verify lane independence with mixed-sign pattern.
  - Part: Per-lane saturation logic, no cross-talk.

- RESET DURING OPERATION
  - What: Reset module mid-operation.
  - Why: Confirm reset properly clears all lane outputs.
  - Part: Asynchronous reset, register clearing.

- SEQUENTIAL DIFFERENT INPUTS
  - What: Apply different input combinations over consecutive cycles.
  - Why: Verify output register updates correctly each cycle.
  - Part: Sequential operation, register update timing.

- PARTIAL SATURATION
  - What: One lane saturates (127+1), others compute normally.
  - Why: Confirm lane-independent saturation doesn't affect other lanes.
  - Part: Per-lane saturation isolation.

Functional Aspects Covered
- Parallel operation: All 8 lanes compute independently and simultaneously.
- Signed addition: Correct two's complement arithmetic.
- Saturation logic: Overflow/underflow detection and clamping.
- Boundary values: Proper handling of INT8_MAX and INT8_MIN.
- Mixed signs: Correct arithmetic across positive/negative combinations.
- Lane isolation: No cross-lane interference or coupling.
- Registration: Proper pipelining through output register.

Hardware Architecture Verified
- 8 parallel adder lanes: Each lane computes independently.
- 9-bit intermediate sum: Sufficient width to detect overflow.
- Per-lane saturation: Independent saturation logic per lane.
- Output registration: Registered outputs for timing closure.

Out-of-Scope / Not Explicitly Tested
- Input timing from systolic array: Integration testing concern.
- Pipeline timing: Verified through synthesis and timing analysis.
- Combinational logic optimization: Synthesis tool responsibility.

Future Enhancements
- Add random testing with comprehensive input combinations.
- Add directed testing for all 256×256 input combinations per lane.
- Add regression suite for saturation corner cases.
- Add performance/throughput characterization.

Pass/Fail Criteria
- All additions produce mathematically correct results when within range.
- Saturation occurs exactly at boundaries: >127 → 127, <-128 → -128.
- All 8 lanes operate independently with correct isolation.
- Output registers update correctly on each clock cycle.
- Reset clears all outputs to zero.
- Mixed-sign operations compute correctly using two's complement.
