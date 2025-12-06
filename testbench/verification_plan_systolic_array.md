Systolic Array Verification Plan

Overview
- Goal: Validate functional behavior of `systolic_array` module including 8x8 PE array coordination, weight loading, matrix-vector/matrix-matrix operations, and output collection.
- Approach: Directed testcases exercised via `tb_systolic_array.sv` covering various matrix operations, data flow patterns, and control scenarios.

Test Matrix Summary

- RESET STATE
  - What: Verify all column outputs are zero after reset.
  - Why: Ensure proper initialization of entire PE array.
  - Part: Reset propagation to all 64 PEs, output collection logic.

- WEIGHT LOADING: IDENTITY
  - What: Load uniform weights (all 1s) into all columns simultaneously.
  - Why: Verify columnar weight loading propagates through all 8 rows correctly.
  - Part: Weight loading path, PE weight shift connections, 8-cycle loading.

- MATRIX-VECTOR: ALL ONES
  - What: Multiply identity-like matrix by vector of 1s with staggered input.
  - Why: Validate basic matrix-vector operation with simplest non-zero case.
  - Part: Input staggering, horizontal data flow, vertical accumulation, output collection.

- SEND2BIAS SIGNAL CONTROL
  - What: Toggle send2bias to gate sum_to_bias output.
  - Why: Verify sum_to_bias output gating logic works correctly.
  - Part: send2bias control logic, combinational gating.

- WEIGHT LOADING: SEQUENTIAL VALUES
  - What: Load weights with sequential values (1,2,3,...,8) per row.
  - Why: Confirm different weight values can be loaded and maintained.
  - Part: Weight loading with varied data, PE weight retention.

- MATRIX-VECTOR: SEQUENTIAL WEIGHTS
  - What: Perform matrix-vector multiply with sequential weights and uniform input.
  - Why: Validate correct computation with non-uniform weights.
  - Part: PE MAC operations, accumulation across array, output correctness.

- FULL MATRIX MULTIPLY: 2×2
  - What: Use 2×2 subregion with specific weights and inputs.
  - Why: Verify partial array utilization and correct result isolation.
  - Part: Sparse matrix handling, unused PE behavior.

- SIGNED OPERATION
  - What: Load negative weight (-5), multiply by positive input (4) = -20.
  - Why: Validate signed arithmetic throughout the array.
  - Part: Signed weight loading, signed multiplication, signed output.

- BATCH PROCESSING
  - What: Process multiple input vectors (8 inputs with weight=2).
  - Why: Confirm array can handle full 8×8 matrix-matrix multiply.
  - Part: Full array utilization, concurrent row processing.

- ZERO INPUT VECTOR
  - What: Process all-zero input vector with non-zero weights.
  - Why: Verify zero propagation and accumulator behavior with zero inputs.
  - Part: Zero handling in multipliers, accumulator zero cases.

- ZERO WEIGHT MATRIX
  - What: Load all-zero weights, process non-zero inputs.
  - Why: Confirm zero weights produce zero outputs regardless of inputs.
  - Part: Weight loading with zeros, multiplication by zero.

- FULL ROW ACCUMULATION
  - What: Simultaneously input to all rows (8×8 matrix of 1s).
  - Why: Validate maximum concurrent operation and accumulation stress test.
  - Part: Full array MAC operations, maximum accumulation (8 products per column).

- PIPELINE STALL
  - What: Pause inference mid-operation by deasserting shift_enable.
  - Why: Verify array can be stalled and resumed without corruption.
  - Part: shift_enable control throughout array, state preservation.

- POSITIVE SATURATION
  - What: Load max weight (127), multiply by 2 to trigger saturation.
  - Why: Confirm PE-level saturation propagates correctly to outputs.
  - Part: PE saturation logic, saturated output collection.

- NEGATIVE SATURATION
  - What: Load min weight (-128), multiply by 2 to trigger saturation.
  - Why: Validate negative saturation boundary behavior.
  - Part: PE negative saturation, signed output handling.

- RESET DURING OPERATION
  - What: Reset array mid-inference operation.
  - Why: Verify reset properly clears all PEs regardless of current state.
  - Part: Asynchronous reset propagation, state clearing.

- BACK-TO-BACK INFERENCES
  - What: Perform two consecutive inferences without resetting accumulators.
  - Why: Confirm accumulation persists across inference operations (intentional or verify clear needed).
  - Part: Accumulator persistence, multi-inference behavior.

Array-Specific Aspects Covered
- PE interconnection: Horizontal shifts (in/shifted), vertical accumulation (out_acc).
- Input staging: Proper staggering for wavefront propagation.
- Weight propagation: Column-wise weight loading over 8 cycles.
- Output collection: Gathering bottom-row PE accumulators as col_sums.
- Control distribution: shift_enable and operate_f broadcast to all PEs.
- Send2bias gating: Conditional output forwarding.
- Full array vs partial utilization: Handling sparse matrices.

Timing Aspects
- Weight loading phase: 8 cycles to load all weights into columns.
- Input phase: 8 cycles to input all rows (staggered).
- Drain phase: 7 additional cycles for data to propagate to rightmost column.
- Total latency: Expected ~15 cycles for single matrix-vector operation.

Out-of-Scope / Not Explicitly Tested
- Individual PE internal behavior: Covered by tb_systolic_pe.
- Detailed multiplier saturation: Tested at PE level.
- Timing closure: Physical design concern.
- Back-pressure mechanisms: Not present in this design.

Future Enhancements
- Add random matrix testing with reference model comparison.
- Add exhaustive corner case matrices (sparse, diagonal, upper triangular).
- Add performance characterization tests (throughput, latency).
- Add power state testing if power management added.

Pass/Fail Criteria
- Matrix-vector products match hand-calculated expected values.
- Matrix-matrix products computed correctly for all 64 output elements.
- Weight loading correctly distributes weights to all PEs.
- Control signals properly coordinate all PE operations.
- Saturation behavior consistent with PE-level specification.
- send2bias correctly gates output forwarding.
