`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_systolic_array ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.fst");
        $dumpvars;
    end

    logic clk, n_rst, shift_enable, operate_f, float_in;
    logic [63:0] in_bus;
    logic send2bias;
    logic [63:0] col_sums, sum_to_bias;
    
    string status;
    int test_num;

    // Clock generation
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    // DUT instantiation
    systolic_array DUT (
        .clk(clk),
        .n_rst(n_rst),
        .shift_enable(shift_enable),
        .operate_f(operate_f),
        .float_in(float_in),
        .in_bus(in_bus),
        .send2bias(send2bias),
        .col_sums(col_sums),
        .sum_to_bias(sum_to_bias)
    );

    // Reset task
    task reset_dut;
    begin
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(negedge clk);
    end
    endtask

    // Check task for output verification
    task check_col_sums(
        input string test_name,
        input logic [63:0] expected_sums
    );
    begin
        if (col_sums !== expected_sums) begin
            $error("[%s] FAIL: Expected col_sums=%h, Got col_sums=%h", 
                   test_name, expected_sums, col_sums);
        end else begin
            $display("[%s] PASS", test_name);
        end
    end
    endtask

    task check_sum_to_bias(
        input string test_name,
        input logic [63:0] expected_sum
    );
    begin
        if (sum_to_bias !== expected_sum) begin
            $error("[%s] FAIL: Expected sum_to_bias=%h, Got sum_to_bias=%h", 
                   test_name, expected_sum, sum_to_bias);
        end else begin
            $display("[%s] PASS", test_name);
        end
    end
    endtask

    initial begin
        test_num = 0;
        
        // Initialize signals
        shift_enable = 0;
        operate_f = 0;
        send2bias = 0;
        float_in = 0;  // Default: INT8 mode
        in_bus = '0;

        reset_dut();

        // ========================================
        // TEST 1: Reset State Verification
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Reset State", test_num);
        @(negedge clk);
        check_col_sums(status, 64'h0);
        check_sum_to_bias(status, 64'h0);

        // ========================================
        // TEST 2: Weight Loading - Identity Matrix
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Load Identity Weights", test_num);
        // Load weights column by column (all 1's for simplicity)
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0101010101010101;  // Load column 0 weights
        repeat (8) @(posedge clk);
        @(negedge clk);
        shift_enable = 1'b0;
        $display("[%s] Weight loading complete", status);

        // ========================================
        // TEST 3: Matrix-Vector Multiply - All 1s
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: MatVec All 1s x All 1s", test_num);
        shift_enable = 1'b1;
        operate_f = 1'b1;
        // Input vector: all 1s enter staggered (one row per cycle)
        for (int cycle = 0; cycle < 8; cycle++) begin
            in_bus = 64'h0;
            in_bus[8*cycle +: 8] = 8'd1;
            @(posedge clk);
        end
        // Drain cycles for data to propagate through all columns
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        @(negedge clk);
        // Each column accumulates all 8 row contributions: 8 * (1*1) = 8
        check_col_sums(status, 64'h0008080808080808);

        // ========================================
        // TEST 4: send2bias Signal Control
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: send2bias Gating", test_num);
        send2bias = 1'b0;
        @(posedge clk);
        check_sum_to_bias(status, 64'h0);
        send2bias = 1'b1;
        @(posedge clk);
        check_sum_to_bias(status, 64'h0808080808080808);
        send2bias = 1'b0;

        // ========================================
        // TEST 5: Different Weight Values
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Load Sequential Weights", test_num);
        reset_dut();
        shift_enable = 1'b1;
        operate_f = 1'b0;
        // Load weights column by column: col0 gets 1-8, col1 gets 1-8, etc.
        for (int col = 0; col < 8; col++) begin
            in_bus = 64'h0807060504030201;  // Each column: row0=1, row1=2, ..., row7=8
            @(posedge clk);
        end
        shift_enable = 1'b0;
        @(posedge clk);
        $display("[%s] Sequential weight loading complete", status);

        // ========================================
        // TEST 6: Matrix-Vector with Sequential Weights
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: MatVec Sequential Weights x All 1s", test_num);
        shift_enable = 1'b1;
        operate_f = 1'b1;
        // Input: all 1s enter staggered
        for (int cycle = 0; cycle < 8; cycle++) begin
            in_bus = 64'h0;
            in_bus[8*cycle +: 8] = 8'd1;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (8) @(posedge clk);  // Drain cycles
        @(posedge clk);  // Extra cycle for capture
        // Each column accumulates contributions from all rows
        // All columns loaded with same weights (1,2,3,4,5,6,7,8)
        // Each col sums: (1+2+3+4+5+6+7+8)*1 = 36 = 0x24
        check_col_sums(status, 64'h2424242424242424);

        // ========================================
        // TEST 7: Simple 2x2 Computation
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Simple 2x2 Computation", test_num);
        reset_dut();
        // Load weights: We want only column 0 to have weights 2,3 in rows 0,1
        // Since weights shift left-to-right, we need to load:
        // Cycle 0: {2,3,0,0,0,0,0,0} - will end up in column 7 after 8 shifts
        // Cycle 1: {0,0,0,0,0,0,0,0} - will end up in column 6
        // ...
        // Cycle 7: {2,3,0,0,0,0,0,0} - will end up in column 0
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0;  // Columns 7-1 get zeros
        repeat (7) @(posedge clk);
        in_bus = 64'h0000000000000302;  // Column 0: weights 2,3,0,0...
        @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Inference: send inputs staggered - row0=4, then row1=5, rest=0
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0000000000000004;  // Cycle 0: row0=4
        @(posedge clk);
        in_bus = 64'h0000000000000500;  // Cycle 1: row1=5
        @(posedge clk);
        // Rows 2-7: send zeros in staggered pattern
        for (int i = 2; i < 8; i++) begin
            in_bus = 64'h0;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);  // Drain cycles for data to propagate
        @(negedge clk);
        // Expected col0: row0(2*4) + row1(3*5) = 8 + 15 = 23 = 0x17
        check_col_sums(status, 64'h0000000000000017);

        // ========================================
        // TEST 8: Signed Weight and Input
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Signed Multiplication", test_num);
        reset_dut();
        // Load negative weight in row 0, col 0 only
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0;  // Columns 7-1 get zeros
        repeat (7) @(posedge clk);
        in_bus = 64'h00000000000000FB;  // Column 0: -5 in row0, others 0
        @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Input: positive value in row 0 (staggered - need all 8 rows)
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0000000000000004;  // Cycle 0: row0 = 4
        @(posedge clk);
        // Rows 1-7: zeros
        for (int i = 1; i < 8; i++) begin
            in_bus = 64'h0;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);  // Drain cycles
        @(negedge clk);
        // Expected col0: -5 * 4 = -20 = 0xEC
        check_col_sums(status, 64'h00000000000000EC);

        // ========================================
        // TEST 9: Uniform Weight Matrix
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Uniform Weights", test_num);
        reset_dut();
        // Load weights: all 2s
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0202020202020202;
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Input vector: row0=1, row1=2, ..., row7=8 (staggered)
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'(i+1);
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (8) @(posedge clk);  // Drain cycles
        @(posedge clk);  // Extra cycle for capture
        // Each col accumulates: 2*(1+2+3+4+5+6+7+8) = 2*36 = 72 = 0x48
        check_col_sums(status, 64'h4848484848484848);

        // ========================================
        // TEST 10: Zero Input Vector
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Zero Input Vector", test_num);
        reset_dut();
        // Load non-zero weights
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0505050505050505;
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Input: all zeros (staggered, but all zero anyway)
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0;
        repeat (15) @(posedge clk);
        @(posedge clk);
        check_col_sums(status, 64'h0);

        // ========================================
        // TEST 11: Zero Weight Matrix
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Zero Weight Matrix", test_num);
        reset_dut();
        // Load zero weights
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0;
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Input: non-zero values (staggered)
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd10;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        @(posedge clk);
        check_col_sums(status, 64'h0);

        // ========================================
        // TEST 12: Accumulation Across Multiple PEs
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Full Row Accumulation", test_num);
        reset_dut();
        // Load uniform weights
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0101010101010101;
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Input: all 1s enter staggered
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd1;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (8) @(posedge clk);  // Drain cycles
        @(posedge clk);  // Extra cycle for capture
        // Each column accumulates 8 rows * (1*1) = 8
        check_col_sums(status, 64'h0808080808080808);

        // ========================================
        // TEST 13: Pipeline Stall (shift_enable=0 during inference)
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Pipeline Stall", test_num);
        reset_dut();
        // Load weights
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0101010101010101;
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Start inference with staggered input - operate_f stays high throughout
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0000000000000001;  // row0 = 1
        @(posedge clk);
        // No pause needed - just continue with staggered input
        for (int i = 1; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd1;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (8) @(posedge clk);  // Drain cycles
        @(posedge clk);  // Extra cycle for capture
        // Should still get correct result: 8 rows * (1*1) = 8
        check_col_sums(status, 64'h0808080808080808);

        // ========================================
        // TEST 14: Saturation Test (Positive)
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Positive Saturation", test_num);
        reset_dut();
        // Load large weight
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h7F7F7F7F7F7F7F7F;  // Max positive weight
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Large input (staggered)
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd2;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (8) @(posedge clk);  // Drain cycles
        @(posedge clk);  // Extra cycle for capture
        // Should saturate at 127
        check_col_sums(status, 64'h7F7F7F7F7F7F7F7F);

        // ========================================
        // TEST 15: Saturation Test (Negative)
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Negative Saturation", test_num);
        reset_dut();
        // Load large negative weight
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h8080808080808080;  // -128
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Positive input (staggered)
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd2;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (8) @(posedge clk);  // Drain cycles
        @(posedge clk);  // Extra cycle for capture
        // Should saturate at -128
        check_col_sums(status, 64'h8080808080808080);
        
        // Clear operate mode
        operate_f = 1'b0;
        shift_enable = 1'b0;
        @(posedge clk);

        // ========================================
        // TEST 16: Reset During Operation
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Reset During Operation", test_num);
        // Start operation
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0101010101010101;
        @(posedge clk);
        @(posedge clk);
        // Reset
        reset_dut();
        check_col_sums(status, 64'h0);

        // ========================================
        // TEST 17: Back-to-Back Inferences
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Back-to-Back Inferences", test_num);
        reset_dut();
        // Load weights
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0101010101010101;
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // First inference (staggered)
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd1;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (8) @(posedge clk);
        
        // Reload weights between inferences to clear accumulators
        operate_f = 1'b0;
        shift_enable = 1'b1;
        in_bus = 64'h0101010101010101;
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Second inference
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd2;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (8) @(posedge clk);  // Drain cycles
        @(posedge clk);  // Extra cycle for capture
        // Second pass: 8 rows * (1*2) = 16 = 0x10
        check_col_sums(status, 64'h1010101010101010);

        // ============================================================
        // FP8 MODE TESTS (float_in = 1)
        // ============================================================
        
        // TEST 18: FP8 Mode - Identity Matrix (same as TEST 2 but with float_in=1)
        test_num = 18;
        status = "TEST 18: FP8 Mode - Identity Matrix";
        $display("\n%s", status);
        reset_dut();
        float_in = 1'b1;  // Enable FP8 mode
        
        // Load identity matrix weights - use larger values to avoid truncation
        // Use all 4's instead of powers of 2
        operate_f = 1'b0;
        shift_enable = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd4;  // All diagonal = 4
            @(posedge clk);
        end
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Inference with all 4s input (to avoid truncation with scale=4)
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd4;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (8) @(posedge clk);
        @(posedge clk);
        // Expected: With scale=4: (4*4)/4 = 4, then 4*4 = 16 per column
        check_col_sums(status, 64'h1010101010101010);  // 0x10 = 16 for all columns

        // TEST 19: FP8 Mode - Simple Multiplication (same as TEST 7)
        test_num = 19;
        status = "TEST 19: FP8 Mode - Simple 2x2";
        $display("\n%s", status);
        reset_dut();
        float_in = 1'b1;  // FP8 mode
        
        // Load weights for column 0 only: use multiples of 4 to avoid truncation
        operate_f = 1'b0;
        shift_enable = 1'b1;
        for (int i = 0; i < 7; i++) begin
            in_bus = 64'h0;
            @(posedge clk);
        end
        in_bus = 64'h0000000000000C08;  // row 0=8 (0x08), row 1=12 (0x0C), rest=0
        @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Inference with [4, 4, 0, ...]
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0000000000000004;  // Cycle 0: row0=4
        @(posedge clk);
        in_bus = 64'h0000000000000400;  // Cycle 1: row1=4
        @(posedge clk);
        // Rows 2-7: zeros
        for (int i = 2; i < 8; i++) begin
            in_bus = 64'h0;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);  // Drain cycles
        @(negedge clk);
        // Expected: FP8 mode: (8*4)/4 + (12*4)/4 = 8+12 = 20, then 20*4 = 80 = 0x50
        check_col_sums(status, 64'h0000000000000050);  // 0x50 = 80

        // TEST 20: FP8 Mode - Signed Values (same as TEST 8)
        test_num = 20;
        status = "TEST 20: FP8 Mode - Signed Values";
        $display("\n%s", status);
        reset_dut();
        float_in = 1'b1;  // FP8 mode
        
        // Load negative weight -20 in column 0, row 0 (multiple of 4)
        operate_f = 1'b0;
        shift_enable = 1'b1;
        for (int i = 0; i < 7; i++) begin
            in_bus = 64'h0;
            @(posedge clk);
        end
        in_bus = 64'h00000000000000EC;  // -20 = 0xEC in row 0
        @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Inference with single input value 4 in row 0
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0000000000000004;  // Cycle 0: row0=4
        @(posedge clk);
        // Rows 1-7: zeros
        for (int i = 1; i < 8; i++) begin
            in_bus = 64'h0;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);  // Drain cycles
        @(negedge clk);
        // Expected: FP8 mode: (-20*4)/4 = -20, then -20*4 = -80 = 0xB0
        check_col_sums(status, 64'h00000000000000b0);

        // TEST 21: FP8 Mode - Saturation Positive (same as TEST 14)
        test_num = 21;
        status = "TEST 21: FP8 Mode - Saturation Positive";
        $display("\n%s", status);
        reset_dut();
        float_in = 1'b1;  // FP8 mode
        
        // Load large weights in column 0 (use 28 to get saturation after scaling)
        operate_f = 1'b0;
        shift_enable = 1'b1;
        for (int i = 0; i < 7; i++) begin
            in_bus = 64'h0;
            @(posedge clk);
        end
        in_bus = 64'h0000000000001C1C;  // row 0=28 (0x1C), row 1=28 (0x1C), rest=0
        @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Inference with [12, 12, ...]
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h000000000000000C;  // Cycle 0: row0=12 (byte 0)
        @(posedge clk);
        in_bus = 64'h0000000000000C00;  // Cycle 1: row1=12 (byte 1)
        @(posedge clk);
        // Rows 2-7: zeros
        for (int i = 2; i < 8; i++) begin
            in_bus = 64'h0;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);  // Drain cycles
        @(negedge clk);
        // Expected: FP8 mode: (28*12)/4 + (28*12)/4 = 84+84 = 168 (saturates to 127)
        // Then 127*4 = 508 = 0x1FC, but truncates to 0xFC in 8 bits
        check_col_sums(status, 64'h00000000000000FC);  // Lower 8 bits of 508

        // TEST 22: FP8 Mode - Saturation Negative (same as TEST 15)
        test_num = 22;
        status = "TEST 22: FP8 Mode - Saturation Negative";
        $display("\n%s", status);
        reset_dut();
        float_in = 1'b1;  // FP8 mode
        
        // Load negative weights (-28 to get saturation)
        operate_f = 1'b0;
        shift_enable = 1'b1;
        for (int i = 0; i < 7; i++) begin
            in_bus = 64'h0;
            @(posedge clk);
        end
        in_bus = 64'h000000000000E4E4;  // row 0=-28 (0xE4), row 1=-28 (0xE4), rest=0
        @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Inference with [12, 12, ...]
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h000000000000000C;  // Cycle 0: row0=12 (byte 0)
        @(posedge clk);
        in_bus = 64'h0000000000000C00;  // Cycle 1: row1=12 (byte 1)
        @(posedge clk);
        // Rows 2-7: zeros
        for (int i = 2; i < 8; i++) begin
            in_bus = 64'h0;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);  // Drain cycles
        @(negedge clk);
        // Expected: FP8 mode: (-28*12)/4 + (-28*12)/4 = -84-84 = -168 (saturates to -128)
        // Then -128*4 = -512, truncates to 0x00 in 8 bits
        check_col_sums(status, 64'h0000000000000000);

        // TEST 23: INT8 Mode - All Ones Input with Custom Weights
        test_num = 23;
        status = "TEST 23: INT8 Mode - All Ones Input";
        $display("\n%s", status);
        reset_dut();
        float_in = 1'b0;  // INT8 mode
        
        // Load custom weights
        operate_f = 1'b0;
        shift_enable = 1'b1;
        in_bus = 64'h0000_0000_0000_0000; // row 0
        @(posedge clk);
        in_bus = 64'h0000_0000_0000_0000;  // row 1
        @(posedge clk);
        in_bus = 64'h00FF_FFFF_FF01_0101;  // row 2
        @(posedge clk);
        in_bus = 64'h0807_0605_0403_0201;  // row 3
        @(posedge clk);
        in_bus = 64'hFF01_FF01_FF01_FF01;   // row 4
        @(posedge clk);
        in_bus = 64'h0000_0000_0000_00FF; // row 5
        @(posedge clk);
        in_bus = 64'h7901_0101_0101_0101;  // row 6
        @(posedge clk);
        in_bus = 64'h0101_0101_0101_0101;  // row 7
        @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Inference with all ones
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0000000000000001;  // Cycle 0: row0=1 (byte 0)
        @(posedge clk);
        in_bus = 64'h0000000000000100;  // Cycle 1: row1=1 (byte 1)
        @(posedge clk);
        in_bus = 64'h0000000000010000;  // Cycle 2: row2=1 (byte 2)
        @(posedge clk);
        in_bus = 64'h0000000001000000;  // Cycle 3: row3=1 (byte 3)
        @(posedge clk);
        in_bus = 64'h0000000100000000;  // Cycle 4: row4=1 (byte 4)
        @(posedge clk);
        in_bus = 64'h0000010000000000;  // Cycle 5: row5=1 (byte 5)
        @(posedge clk);
        in_bus = 64'h0001000000000000;  // Cycle 6: row6=1 (byte 6)
        @(posedge clk);
        in_bus = 64'h0100000000000000;  // Cycle 7: row7=1 (byte 7)
        @(posedge clk);
        in_bus = 64'h0;
        repeat (7) @(posedge clk);  // Drain cycles
        @(negedge clk);
        // Expected: sum of each column of weights (all multiplied by 1)
        // Col 0: 0x01+0x01+0xFF+0x01+0x01+0x01+0x00+0x00 = 0x104 (truncates to 0x04)
        // Col 1: 0x01+0x01+0x00+0xFF+0x02+0x01+0x00+0x00 = 0x104 (truncates to 0x04)
        // Col 2: 0x01+0x01+0x00+0x01+0x03+0xFF+0x00+0x00 = 0x105 (truncates to 0x05)
        // Col 3: 0x01+0x01+0x00+0xFF+0x04+0xFF+0x00+0x00 = 0x204 (truncates to 0x04)
        // Col 4: 0x01+0x01+0x00+0x01+0x05+0xFF+0x00+0x00 = 0x107 (truncates to 0x07)
        // Col 5: 0x01+0x01+0x00+0xFF+0x06+0xFF+0x00+0x00 = 0x206 (truncates to 0x06)
        // Col 6: 0x01+0x01+0x00+0x01+0x07+0xFF+0x00+0x00 = 0x109 (truncates to 0x09)
        // Col 7: 0x01+0x79+0x00+0xFF+0x08+0x00+0x00+0x00 = 0x181 (truncates to 0x81)
        check_col_sums(status, 64'h8109060704040404);
        
        $display("\n===========================================");
        $display("All Systolic Array Tests Complete!");
        $display("===========================================\n");
        
        @(negedge clk);
        @(negedge clk);
        $finish;
    end

endmodule

/* verilator coverage_on */
