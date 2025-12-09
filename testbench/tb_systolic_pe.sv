`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_systolic_pe ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.fst");
        $dumpvars;
    end

    logic clk, n_rst;
    logic [7:0] in;
    logic [7:0] acc_above;
    logic shift_enable;
    logic operate_f;
    logic [7:0] shifted;
    logic [7:0] out_acc;

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
    systolic_pe DUT (
        .clk(clk),
        .n_rst(n_rst),
        .in(in),
        .acc_above(acc_above),
        .shift_enable(shift_enable),
        .operate_f(operate_f),
        .shifted(shifted),
        .out_acc(out_acc)
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
    task check_output(
        input string test_name,
        input logic [7:0] expected_shifted,
        input logic [7:0] expected_acc,
        input logic check_shifted,
        input logic check_acc
    );
    begin
        if (check_shifted && shifted !== expected_shifted) begin
            $error("[%s] FAIL: Expected shifted=%h, Got shifted=%h", 
                   test_name, expected_shifted, shifted);
        end
        if (check_acc && out_acc !== expected_acc) begin
            $error("[%s] FAIL: Expected out_acc=%h, Got out_acc=%h", 
                   test_name, expected_acc, out_acc);
        end
        if ((!check_shifted || shifted === expected_shifted) && 
            (!check_acc || out_acc === expected_acc)) begin
            $display("[%s] PASS", test_name);
        end
    end
    endtask

    initial begin
        test_num = 0;
        
        // Initialize signals
        in = 8'h00;
        acc_above = 8'h00;
        shift_enable = 0;
        operate_f = 0;

        reset_dut();

        // ========================================
        // TEST 1: Reset State Verification
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Reset State", test_num);
        @(negedge clk);
        check_output(status, 8'h00, 8'h00, 1'b1, 1'b1);

        // ========================================
        // TEST 2: Weight Loading - Single Weight
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Load Weight 0x05", test_num);
        in = 8'h05;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Weight should be loaded, shifted output should show weight
        check_output(status, 8'h05, 8'h00, 1'b1, 1'b1);

        // ========================================
        // TEST 3: Weight Loading - Multiple Weights
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Load Weight 0x0A (overwrite)", test_num);
        in = 8'h0A;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'h0A, 8'h00, 1'b1, 1'b1);

        // ========================================
        // TEST 4: Weight Holding (shift_enable=0)
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Weight Hold", test_num);
        in = 8'hFF;
        shift_enable = 0;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Weight should remain 0x0A, shifted unchanged
        check_output(status, 8'h0A, 8'h00, 1'b1, 1'b1);

        // ========================================
        // TEST 5: Inference - Single MAC Operation (acc_above = 0)
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: MAC (0 + 10 * 3 = 30)", test_num);
        acc_above = 8'h00;  // Top row PE gets 0 from above
        in = 8'h03;  // input = 3, weight = 0x0A (10)
        shift_enable = 1;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        // shifted should pass input, acc should have 0 + 10*3 = 30
        check_output(status, 8'h03, 8'd30, 1'b1, 1'b1);

        // ========================================
        // TEST 6: Inference - Vertical Accumulation
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Vertical Acc (30 + 10 * 5 = 80)", test_num);
        acc_above = 8'd30;  // Receiving accumulation from PE above
        in = 8'h05;  // input = 5, accumulate 30 + 10*5 = 80
        shift_enable = 1;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'h05, 8'd80, 1'b1, 1'b1);

        // ========================================
        // TEST 7: Signed Multiplication - Positive x Positive
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Signed Mult (+10 * +12)", test_num);
        reset_dut();
        // Load positive weight
        in = 8'd10;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Multiply with positive input
        in = 8'd12;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'd12, 8'd120, 1'b1, 1'b1);

        // ========================================
        // TEST 8: Signed Multiplication - Positive x Negative
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Signed Mult (+10 * -5)", test_num);
        reset_dut();
        // Load positive weight
        in = 8'd10;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Multiply with negative input
        in = -8'sd5;  // -5
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, -8'sd5, -8'sd50, 1'b1, 1'b1);

        // ========================================
        // TEST 9: Signed Multiplication - Negative x Positive
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Signed Mult (-10 * +8)", test_num);
        reset_dut();
        // Load negative weight
        in = -8'sd10;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Multiply with positive input
        in = 8'd8;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'd8, -8'sd80, 1'b1, 1'b1);

        // ========================================
        // TEST 10: Signed Multiplication - Negative x Negative
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Signed Mult (-6 * -7)", test_num);
        reset_dut();
        // Load negative weight
        in = -8'sd6;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Multiply with negative input
        in = -8'sd7;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, -8'sd7, 8'd42, 1'b1, 1'b1);

        // ========================================
        // TEST 11: Vertical Accumulation with Mixed Signs
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Vertical Acc Mixed Signs", test_num);
        reset_dut();
        // Load weight 5
        in = 8'd5;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // First cycle: acc_above=0, product=5*10=50, output=50
        in = 8'd10;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        check_output("Vertical Acc Step 1", 8'd10, 8'd50, 1'b1, 1'b1);
        // Second cycle: acc_above=50 (from above PE), product=5*(-8)=-40, output=50-40=10
        in = -8'sd8;
        acc_above = 8'd50;
        @(posedge clk);
        @(negedge clk);
        check_output(status, -8'sd8, 8'd10, 1'b1, 1'b1);

        // ========================================
        // TEST 12: Positive Saturation
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Positive Saturation", test_num);
        reset_dut();
        // Load weight 127 (max positive)
        in = 8'd127;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Multiply: 0 + 127*2 = 254, but should saturate at 127
        in = 8'd2;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'd2, 8'd127, 1'b1, 1'b1);

        // ========================================
        // TEST 13: Negative Saturation
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Negative Saturation", test_num);
        reset_dut();
        // Load weight -128 (max negative)
        in = -8'sd128;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Multiply: 0 + (-128)*2 = -256, but should saturate at -128
        in = 8'd2;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'd2, -8'sd128, 1'b1, 1'b1);

        // ========================================
        // TEST 14: Accumulator Positive Overflow Saturation
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Accumulator Overflow Sat", test_num);
        reset_dut();
        // Load weight 10
        in = 8'd10;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // First: 0 + 10*12 = 120
        in = 8'd12;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        // Second: 120 (from above) + 10*12 = 240 -> saturate to 127
        in = 8'd12;
        acc_above = 8'd120;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'd12, 8'd127, 1'b1, 1'b1);

        // ========================================
        // TEST 15: Accumulator Negative Overflow Saturation
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Accumulator Underflow Sat", test_num);
        reset_dut();
        // Load weight -10
        in = -8'sd10;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // First: 0 + (-10)*12 = -120
        in = 8'd12;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        // Second: -120 (from above) + (-10)*12 = -240 -> saturate to -128
        in = 8'd12;
        acc_above = -8'sd120;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'd12, -8'sd128, 1'b1, 1'b1);

        // ========================================
        // TEST 16: Zero Multiplication
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Zero Multiplication", test_num);
        reset_dut();
        // Load weight 0
        in = 8'd0;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Multiply with non-zero input
        in = 8'd50;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'd50, 8'd0, 1'b1, 1'b1);

        // ========================================
        // TEST 17: Input Zero Multiplication
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Input Zero Multiplication", test_num);
        reset_dut();
        // Load non-zero weight
        in = 8'd25;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Multiply with zero input
        in = 8'd0;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'd0, 8'd0, 1'b1, 1'b1);

        // ========================================
        // TEST 18: Sequential Weight Loading (Pipeline)
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Sequential Weight Load", test_num);
        reset_dut();
        // Load first weight
        in = 8'd1;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Load second weight (shifts previous)
        in = 8'd2;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'd2, 8'd0, 1'b1, 1'b1);
        // Load third weight
        in = 8'd3;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 8'd3, 8'd0, 1'b1, 1'b1);

        // ========================================
        // TEST 19: Inference After Reset
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Inference After Reset", test_num);
        // Load weight
        in = 8'd7;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Perform multiply
        in = 8'd9;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        // Reset
        reset_dut();
        // Check that accumulator cleared
        check_output(status, 8'd0, 8'd0, 1'b1, 1'b1);

        // ========================================
        // TEST 20: Long Vertical Accumulation Sequence
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Long Vertical Accumulation", test_num);
        reset_dut();
        // Load weight 2
        in = 8'd2;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Simulate vertical accumulation: 0+2*1=2, 2+2*2=6, 6+2*3=12, 12+2*4=20
        operate_f = 1;
        logic [7:0] running_acc = 0;
        for (int i = 1; i <= 4; i++) begin
            in = i;
            acc_above = running_acc;
            @(posedge clk);
            @(negedge clk);
            running_acc = out_acc;  // Capture for next iteration
        end
        check_output(status, 8'd4, 8'd20, 1'b1, 1'b1);

        // ========================================
        // TEST 21: Disable shift_enable During Inference
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Disabled Shift During Inference", test_num);
        reset_dut();
        // Load weight
        in = 8'd5;
        acc_above = 8'd0;
        shift_enable = 1;
        operate_f = 0;
        @(posedge clk);
        @(negedge clk);
        // Start inference
        in = 8'd3;
        acc_above = 8'd0;
        operate_f = 1;
        @(posedge clk);
        @(negedge clk);
        // Disable shift (accumulation should stop)
        shift_enable = 0;
        in = 8'd10;
        acc_above = 8'd15;
        @(posedge clk);
        @(negedge clk);
        // Accumulator should still have previous value (15)
        check_output(status, 8'd3, 8'd15, 1'b1, 1'b1);

        $display("\n===========================================");
        $display("All Systolic PE Tests Complete!");
        $display("===========================================\n");
        
        @(negedge clk);
        @(negedge clk);
        $finish;
    end

endmodule

/* verilator coverage_on */

