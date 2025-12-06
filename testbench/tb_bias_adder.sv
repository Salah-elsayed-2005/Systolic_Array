`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_bias_adder ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.fst");
        $dumpvars;
    end

    logic clk, n_rst;
    logic [63:0] out_acc, bias, out_b;

    string status;
    int test_num;

    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    bias_adder DUT (
        .clk(clk),
        .n_rst(n_rst),
        .out_acc(out_acc),
        .bias(bias),
        .out_b(out_b)
    );

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

    task check_output(
        input string test_name,
        input logic [63:0] expected
    );
    begin
        if (out_b !== expected) begin
            $error("[%s] FAIL: Expected out_b=%h, Got out_b=%h", 
                   test_name, expected, out_b);
        end else begin
            $display("[%s] PASS", test_name);
        end
    end
    endtask

    initial begin
        test_num = 0;
        clk = 0;
        n_rst = 0;
        out_acc = 0;
        bias = 0;
        
        reset_dut();

        // ========================================
        // TEST 1: Reset State Verification
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Reset State", test_num);
        @(negedge clk);
        check_output(status, 64'h0);

        // ========================================
        // TEST 2: Simple Positive Addition
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Positive Addition (8+2=10)", test_num);
        out_acc = 64'h0808080808080808;
        bias = 64'h0202020202020202;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'h0A0A0A0A0A0A0A0A);

        // ========================================
        // TEST 3: Zero Bias
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Zero Bias", test_num);
        out_acc = 64'h0505050505050505;
        bias = 64'h0000000000000000;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'h0505050505050505);

        // ========================================
        // TEST 4: Zero Accumulator
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Zero Accumulator", test_num);
        out_acc = 64'h0000000000000000;
        bias = 64'h0707070707070707;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'h0707070707070707);

        // ========================================
        // TEST 5: Positive Saturation
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Positive Saturation", test_num);
        out_acc = 64'h7F7F7F7F7F7F7F7F;  // 127
        bias = 64'h0101010101010101;     // 1
        @(posedge clk);
        @(negedge clk);
        // 127 + 1 = 128, should saturate to 127
        check_output(status, 64'h7F7F7F7F7F7F7F7F);

        // ========================================
        // TEST 6: Negative Saturation
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Negative Saturation", test_num);
        out_acc = 64'hFEFEFEFEFEFEFEFE;  // -2
        bias = 64'hFEFEFEFEFEFEFEFE;     // -2
        @(posedge clk);
        @(negedge clk);
        // -2 + -2 = -4 (no saturation in this case)
        check_output(status, 64'hFCFCFCFCFCFCFCFC);

        // ========================================
        // TEST 7: Large Negative Saturation
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Large Negative Saturation", test_num);
        out_acc = 64'h8080808080808080;  // -128
        bias = 64'hFFFFFFFFFFFFFFFF;     // -1
        @(posedge clk);
        @(negedge clk);
        // -128 + -1 = -129, should saturate to -128
        check_output(status, 64'h8080808080808080);

        // ========================================
        // TEST 8: Mixed Signs (Positive + Negative)
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Positive + Negative", test_num);
        out_acc = 64'h0A0A0A0A0A0A0A0A;  // 10
        bias = 64'hFBFBFBFBFBFBFBFB;     // -5
        @(posedge clk);
        @(negedge clk);
        // 10 + -5 = 5
        check_output(status, 64'h0505050505050505);

        // ========================================
        // TEST 9: Mixed Signs (Negative + Positive)
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Negative + Positive", test_num);
        out_acc = 64'hF6F6F6F6F6F6F6F6;  // -10
        bias = 64'h0F0F0F0F0F0F0F0F;     // 15
        @(posedge clk);
        @(negedge clk);
        // -10 + 15 = 5
        check_output(status, 64'h0505050505050505);

        // ========================================
        // TEST 10: All Lanes Different Values
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: All Lanes Different", test_num);
        out_acc = 64'h0807060504030201;
        bias = 64'h0101010101010101;
        @(posedge clk);
        @(negedge clk);
        // Each lane: acc[i] + 1
        check_output(status, 64'h0908070605040302);

        // ========================================
        // TEST 11: Boundary Value - Max Positive
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Max Positive Value", test_num);
        out_acc = 64'h7F7F7F7F7F7F7F7F;
        bias = 64'h0000000000000000;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'h7F7F7F7F7F7F7F7F);

        // ========================================
        // TEST 12: Boundary Value - Max Negative
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Max Negative Value", test_num);
        out_acc = 64'h8080808080808080;
        bias = 64'h0000000000000000;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'h8080808080808080);

        // ========================================
        // TEST 13: Near Saturation (Just Below)
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Near Positive Saturation", test_num);
        out_acc = 64'h7E7E7E7E7E7E7E7E;  // 126
        bias = 64'h0101010101010101;     // 1
        @(posedge clk);
        @(negedge clk);
        // 126 + 1 = 127 (no saturation)
        check_output(status, 64'h7F7F7F7F7F7F7F7F);

        // ========================================
        // TEST 14: Near Negative Saturation (Just Above)
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Near Negative Saturation", test_num);
        out_acc = 64'h8181818181818181;  // -127
        bias = 64'hFFFFFFFFFFFFFFFF;     // -1
        @(posedge clk);
        @(negedge clk);
        // -127 + -1 = -128 (no saturation)
        check_output(status, 64'h8080808080808080);

        // ========================================
        // TEST 15: Large Positive Overflow
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Large Positive Overflow", test_num);
        out_acc = 64'h7F7F7F7F7F7F7F7F;  // 127
        bias = 64'h7F7F7F7F7F7F7F7F;     // 127
        @(posedge clk);
        @(negedge clk);
        // 127 + 127 = 254, should saturate to 127
        check_output(status, 64'h7F7F7F7F7F7F7F7F);

        // ========================================
        // TEST 16: Large Negative Overflow
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Large Negative Overflow", test_num);
        out_acc = 64'h8080808080808080;  // -128
        bias = 64'h8080808080808080;     // -128
        @(posedge clk);
        @(negedge clk);
        // -128 + -128 = -256, should saturate to -128
        check_output(status, 64'h8080808080808080);

        // ========================================
        // TEST 17: Alternating Lane Values
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Alternating Lane Values", test_num);
        out_acc = 64'hF60AF60AF60AF60A;  // -10, 10, -10, 10, ...
        bias = 64'h0505050505050505;     // 5, 5, 5, 5, ...
        @(posedge clk);
        @(negedge clk);
        // -10+5=-5(FB), 10+5=15(0F), ...
        check_output(status, 64'hFB0FFB0FFB0FFB0F);

        // ========================================
        // TEST 18: Reset During Operation
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Reset During Operation", test_num);
        out_acc = 64'h1010101010101010;
        bias = 64'h2020202020202020;
        @(posedge clk);
        reset_dut();
        check_output(status, 64'h0);

        // ========================================
        // TEST 19: Sequential Different Inputs
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Sequential Inputs", test_num);
        // First input
        out_acc = 64'h0101010101010101;
        bias = 64'h0101010101010101;
        @(posedge clk);
        @(negedge clk);
        check_output("Sequential Step 1", 64'h0202020202020202);
        // Second input
        out_acc = 64'h0505050505050505;
        bias = 64'h0A0A0A0A0A0A0A0A;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'h0F0F0F0F0F0F0F0F);

        // ========================================
        // TEST 20: One Lane Saturates, Others Don't
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Partial Saturation", test_num);
        out_acc = 64'h7F0A050302010101;  // 127, 10, 5, 3, 2, 1, 1, 1
        bias = 64'h0101010101010101;     // All 1
        @(posedge clk);
        @(negedge clk);
        // Lane 7: 127+1=sat to 127, others add normally
        check_output(status, 64'h7F0B060403020202);

        $display("\n===========================================");
        $display("All Bias Adder Tests Complete!");
        $display("===========================================\n");
        
        @(negedge clk);
        @(negedge clk);
        $finish;
    end
endmodule

/* verilator coverage_on */

