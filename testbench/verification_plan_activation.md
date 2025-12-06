Activation Verification Plan

Overview
- Goal: Validate functional behavior of `activation` module including all four activation functions (ReLU, Binary, Identity, Leaky ReLU) and mode switching.
- Approach: Directed testcases exercised via `tb_activation.sv` covering all activation modes, edge cases, and mode transitions.

Test Matrix Summary

- RESET STATE
  - What: Verify output is zero after reset.
  - Why: Ensure proper initialization of output register.
  - Part: Reset logic, register initialization.

ReLU Tests (Mode 0)

- RELU: POSITIVE INPUT
  - What: Apply positive input (0x0A0A...), expect same output.
  - Why: Verify ReLU passes positive values unchanged.
  - Part: Sign bit detection (in[63]), output selection logic.

- RELU: NEGATIVE INPUT
  - What: Apply negative input (-1), expect zero output.
  - Why: Validate ReLU clamps negative values to zero.
  - Part: Sign bit check, zero output path.

- RELU: ZERO INPUT
  - What: Apply zero input, expect zero output.
  - Why: Confirm ReLU treats zero as non-negative (passes through).
  - Part: Zero case handling in ReLU mode.

- RELU: LARGE POSITIVE
  - What: Apply maximum positive (0x7F7F...), expect passthrough.
  - Why: Verify ReLU handles boundary positive values.
  - Part: Positive value passthrough, no modification.

- RELU: LARGE NEGATIVE
  - What: Apply maximum negative (-128), expect zero.
  - Why: Validate ReLU clamps boundary negative values.
  - Part: Negative clamping at extreme values.

Binary Activation Tests (Mode 1)

- BINARY: POSITIVE INPUT
  - What: Apply positive input, expect output = 1.
  - Why: Verify Binary activation returns 1 for positive values.
  - Part: Sign bit check, constant output logic.

- BINARY: NEGATIVE INPUT
  - What: Apply negative input (-1), expect output = 0.
  - Why: Validate Binary activation returns 0 for negative values.
  - Part: Sign bit check, zero output.

- BINARY: ZERO INPUT
  - What: Apply zero input, expect output = 1.
  - Why: Confirm Binary treats zero as non-negative (outputs 1).
  - Part: Zero case handling in binary mode.

- BINARY: LARGE POSITIVE
  - What: Apply max positive (127), expect output = 1.
  - Why: Verify Binary works correctly for boundary positive.
  - Part: Sign-based classification only.

- BINARY: LARGE NEGATIVE
  - What: Apply max negative (-128), expect output = 0.
  - Why: Validate Binary classification at negative boundary.
  - Part: Sign-based classification at extremes.

Identity Activation Tests (Mode 2)

- IDENTITY: POSITIVE INPUT
  - What: Apply arbitrary positive value, expect exact passthrough.
  - Why: Verify Identity mode passes input unchanged.
  - Part: Bypass path, direct input-to-output assignment.

- IDENTITY: NEGATIVE INPUT
  - What: Apply negative value (-10), expect exact passthrough.
  - Why: Validate Identity preserves negative values.
  - Part: Signed value passthrough.

- IDENTITY: ZERO INPUT
  - What: Apply zero, expect zero output.
  - Why: Confirm Identity passes zero correctly.
  - Part: Zero passthrough.

- IDENTITY: ALL BITS SET
  - What: Apply 0xFFFF..., expect exact output.
  - Why: Verify Identity preserves all bit patterns.
  - Part: Bitwise preservation through Identity mode.

Leaky ReLU Tests (Mode 3, α=0.5)

- LEAKY_RELU: POSITIVE INPUT
  - What: Apply positive input (8), expect passthrough (8).
  - Why: Verify Leaky ReLU passes positive values unchanged.
  - Part: Sign check, positive path.

- LEAKY_RELU: NEGATIVE EVEN
  - What: Apply negative even value (-8), expect -4 (arithmetic shift right by 1).
  - Why: Validate Leaky ReLU applies α=0.5 via arithmetic right shift.
  - Part: Arithmetic right shift (>>>), sign preservation.

- LEAKY_RELU: NEGATIVE ODD
  - What: Apply negative odd value (-9), expect -5 (rounded down).
  - Why: Verify arithmetic shift rounds toward negative infinity.
  - Part: Arithmetic shift behavior with odd values.

- LEAKY_RELU: ZERO INPUT
  - What: Apply zero, expect zero output.
  - Why: Confirm Leaky ReLU preserves zero.
  - Part: Zero case handling.

- LEAKY_RELU: LARGE NEGATIVE
  - What: Apply -128, expect -64.
  - Why: Validate Leaky ReLU scaling at boundary negative value.
  - Part: Arithmetic shift with maximum negative value.

Mode Switching Tests

- MODE_SWITCH: RELU TO BINARY
  - What: Apply input in ReLU mode, then switch to Binary with same input.
  - Why: Verify mode switching updates output correctly.
  - Part: Mode multiplexer, activation_mode signal handling.

- MODE_SWITCH: IDENTITY TO LEAKY_RELU
  - What: Apply input in Identity, switch to Leaky ReLU.
  - Why: Confirm mode transitions work across all mode pairs.
  - Part: Mode control logic, output update timing.

Edge Case Tests

- RELU: BOUNDARY POSITIVE
  - What: Apply +1, expect +1.
  - Why: Verify ReLU at positive boundary (just above zero).
  - Part: Boundary condition handling.

- RELU: BOUNDARY NEGATIVE
  - What: Apply -1, expect 0.
  - Why: Validate ReLU at negative boundary (just below zero).
  - Part: Boundary clamping precision.

- INVALID MODE
  - What: Apply invalid mode value (3'b111), expect default behavior (identity).
  - Why: Verify graceful handling of invalid/undefined modes.
  - Part: Default case in mode selection logic.

- RESET DURING OPERATION
  - What: Reset module mid-operation.
  - Why: Confirm reset clears output regardless of current mode.
  - Part: Asynchronous reset, register clearing.

- SEQUENTIAL MODE CHANGES
  - What: Cycle through multiple modes with same input.
  - Why: Verify mode switching is stable and repeatable.
  - Part: Mode control stability, no state corruption.

- ALTERNATING SIGNS WITH RELU
  - What: Alternate between positive and negative inputs in ReLU mode.
  - Why: Confirm ReLU responds correctly to sign changes.
  - Part: Dynamic sign detection, output switching.

- LEAKY_RELU: SMALL NEGATIVE
  - What: Apply -2, expect -1.
  - Why: Verify Leaky ReLU works correctly for small negative values.
  - Part: Arithmetic shift with small magnitudes.

- ALL_MODES_SAME_INPUT
  - What: Apply same positive input across all 4 modes.
  - Why: Characterize each mode's behavior with identical input.
  - Part: Mode comparison, functional differentiation.

Functional Aspects Covered
- ReLU activation: Zero-clamping for negative values.
- Binary activation: Sign-based classification to 0 or 1.
- Identity activation: Direct passthrough.
- Leaky ReLU: Positive passthrough, negative scaling by 0.5.
- Mode selection: Multiplexer-based activation function selection.
- Sign detection: Proper interpretation of MSB for signed values.
- Arithmetic shift: Sign-preserving right shift for Leaky ReLU.
- Output registration: Proper clocking of output.

Activation Function Specifications
- ReLU: f(x) = x if x≥0, else 0
- Binary: f(x) = 1 if x≥0, else 0
- Identity: f(x) = x
- Leaky ReLU: f(x) = x if x≥0, else x>>1 (α=0.5)

Out-of-Scope / Not Explicitly Tested
- Floating-point activations: Design uses integer arithmetic only.
- Other activation functions: Only 4 specified modes implemented.
- Parameterized α: Leaky ReLU α fixed at 0.5.
- Input from bias_adder: Integration testing concern.

Future Enhancements
- Add exhaustive testing of all 64-bit input patterns per mode.
- Add characterization of mode switching latency.
- Add comparison with software reference model.
- Add testing with different α values if parameterized.

Pass/Fail Criteria
- ReLU correctly clamps negative to zero, passes positive unchanged.
- Binary correctly outputs 0 or 1 based on sign only.
- Identity passes all values unchanged.
- Leaky ReLU correctly scales negative values by 0.5 (arithmetic shift).
- Mode switching updates output correctly on next clock.
- Reset clears output to zero.
- Invalid modes default to safe behavior (Identity).
- Output register updates synchronously with clock.
