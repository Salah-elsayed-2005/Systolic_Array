`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_systolic_array ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.fst");
        $dumpvars;
    end

    logic clk, n_rst, shift_enable, operate_f;
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
        // Input vector: all 1s, staggered entry
        for (int cycle = 0; cycle < 8; cycle++) begin
            in_bus = 64'h0;
            in_bus[8*cycle +: 8] = 8'd1;
            @(posedge clk);
        end
        // Drain pipeline (7 more cycles for data to propagate through)
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        @(negedge clk);
        // Each column should accumulate to 1*1 = 1 (only one input per row)
        check_col_sums(status, 64'h0101010101010101);

        // ========================================
        // TEST 4: send2bias Signal Control
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: send2bias Gating", test_num);
        send2bias = 1'b0;
        @(negedge clk);
        check_sum_to_bias(status, 64'h0);
        send2bias = 1'b1;
        @(negedge clk);
        check_sum_to_bias(status, 64'h0101010101010101);
        send2bias = 1'b0;

        // ========================================
        // TEST 5: Different Weight Values
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Load Sequential Weights", test_num);
        reset_dut();
        shift_enable = 1'b1;
        operate_f = 1'b0;
        // Load weights: each row gets value 1, 2, 3, ..., 8
        in_bus = 64'h0807060504030201;
        repeat (8) @(posedge clk);
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
        // Input: all 1s, staggered
        for (int cycle = 0; cycle < 8; cycle++) begin
            in_bus = 64'h0;
            in_bus[8*cycle +: 8] = 8'd1;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        @(negedge clk);
        // Each column should have its respective weight value
        check_col_sums(status, 64'h0807060504030201);

        // ========================================
        // TEST 7: Full Matrix Multiply - Small Values
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Full Matrix Multiply 2x2", test_num);
        reset_dut();
        // Load 2x2 identity in top-left corner
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0000000000000201;  // weights: row0=1, row1=2, others=0
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Inference: two inputs staggered
        shift_enable = 1'b1;
        operate_f = 1'b1;
        // Cycle 0: input[0] = 3
        in_bus = 64'h0000000000000003;
        @(posedge clk);
        // Cycle 1: input[1] = 4
        in_bus = 64'h0000000000000400;
        @(posedge clk);
        // Drain
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        @(negedge clk);
        // Expected: col0 = 1*3 = 3, col1 = 2*4 = 8
        check_col_sums(status, 64'h0000000000000803);

        // ========================================
        // TEST 8: Signed Weight and Input
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Signed Multiplication", test_num);
        reset_dut();
        // Load negative weight in row 0
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h00000000000000FB;  // -5 in signed 8-bit
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // Input: positive value
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0000000000000004;  // input = 4
        @(posedge clk);
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        @(negedge clk);
        // Expected: -5 * 4 = -20 = 0xEC
        check_col_sums(status, 64'h00000000000000EC);

        // ========================================
        // TEST 9: Multiple Input Vectors (Batch)
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Batch Processing", test_num);
        reset_dut();
        // Load weights: all 2s
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0202020202020202;
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // First vector: values 1-8
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'(i+1);
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        @(negedge clk);
        // Each col: 2 * (row_value)
        check_col_sums(status, 64'h100E0C0A08060402);

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
        
        // Input: all zeros
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0;
        repeat (15) @(posedge clk);
        @(negedge clk);
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
        
        // Input: non-zero values
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd10;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        @(negedge clk);
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
        
        // Input: full 8x8 matrix of 1s (each row gets input simultaneously)
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0101010101010101;  // All rows get 1 simultaneously
        repeat (15) @(posedge clk);
        @(negedge clk);
        // Each column accumulates 8 * (1*1) = 8
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
        
        // Start inference then pause
        shift_enable = 1'b1;
        operate_f = 1'b1;
        in_bus = 64'h0000000000000001;
        @(posedge clk);
        shift_enable = 1'b0;  // Pause
        in_bus = 64'h0;
        repeat (3) @(posedge clk);
        shift_enable = 1'b1;  // Resume
        repeat (14) @(posedge clk);
        @(negedge clk);
        // Should still get correct result
        check_col_sums(status, 64'h0101010101010101);

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
        
        // Large input
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd2;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        @(negedge clk);
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
        
        // Positive input
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd2;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        @(negedge clk);
        // Should saturate at -128
        check_col_sums(status, 64'h8080808080808080);

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
        // Load weights
        shift_enable = 1'b1;
        operate_f = 1'b0;
        in_bus = 64'h0101010101010101;
        repeat (8) @(posedge clk);
        shift_enable = 1'b0;
        @(posedge clk);
        
        // First inference
        shift_enable = 1'b1;
        operate_f = 1'b1;
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd1;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        
        // Immediate second inference (no reset)
        for (int i = 0; i < 8; i++) begin
            in_bus = 64'h0;
            in_bus[8*i +: 8] = 8'd2;
            @(posedge clk);
        end
        in_bus = 64'h0;
        repeat (7) @(posedge clk);
        @(negedge clk);
        // Should accumulate: first pass adds 1, second adds 2 = 3 total
        check_col_sums(status, 64'h0303030303030303);

        $display("\n===========================================");
        $display("All Systolic Array Tests Complete!");
        $display("===========================================\n");
        
        @(negedge clk);
        @(negedge clk);
        $finish;
    end

endmodule

/* verilator coverage_on */
