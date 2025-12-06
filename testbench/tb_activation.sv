`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_activation ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.fst");
        $dumpvars;
    end

    logic clk, n_rst;
    logic [2:0] activation_mode;
    logic signed [63:0] in, out;

    string status;
    int test_num;

    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    activation DUT (
        .clk(clk),
        .n_rst(n_rst),
        .activation_mode(activation_mode),
        .in(in),
        .out(out)
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
        input logic signed [63:0] expected
    );
    begin
        if (out !== expected) begin
            $error("[%s] FAIL: Expected out=%h, Got out=%h", 
                   test_name, expected, out);
        end else begin
            $display("[%s] PASS", test_name);
        end
    end
    endtask

    initial begin
        test_num = 0;
        clk = 0;
        n_rst = 0;
        activation_mode = 0;
        in = 0;
        
        reset_dut();

        // ========================================
        // TEST 1: Reset State Verification
        // ========================================
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Reset State", test_num);
        @(negedge clk);
        check_output(status, 64'sd0);

        // ========================================
        // ReLU Tests (Mode 0)
        // ========================================
        
        // TEST 2: ReLU - Positive Input
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: ReLU Positive", test_num);
        activation_mode = 3'b000;
        in = 64'sh0A0A0A0A0A0A0A0A;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sh0A0A0A0A0A0A0A0A);

        // TEST 3: ReLU - Negative Input
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: ReLU Negative", test_num);
        activation_mode = 3'b000;
        in = -64'sd1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd0);

        // TEST 4: ReLU - Zero Input
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: ReLU Zero", test_num);
        activation_mode = 3'b000;
        in = 64'sd0;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd0);

        // TEST 5: ReLU - Large Positive
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: ReLU Large Positive", test_num);
        activation_mode = 3'b000;
        in = 64'sh7F7F7F7F7F7F7F7F;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sh7F7F7F7F7F7F7F7F);

        // TEST 6: ReLU - Large Negative
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: ReLU Large Negative", test_num);
        activation_mode = 3'b000;
        in = 64'sh8080808080808080;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd0);

        // ========================================
        // Binary Activation Tests (Mode 1)
        // ========================================

        // TEST 7: Binary - Positive Input
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Binary Positive", test_num);
        activation_mode = 3'b001;
        in = 64'sh0A0A0A0A0A0A0A0A;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd1);

        // TEST 8: Binary - Negative Input
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Binary Negative", test_num);
        activation_mode = 3'b001;
        in = -64'sd1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd0);

        // TEST 9: Binary - Zero Input
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Binary Zero", test_num);
        activation_mode = 3'b001;
        in = 64'sd0;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd1);  // Zero is positive, so output is 1

        // TEST 10: Binary - Large Positive
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Binary Large Positive", test_num);
        activation_mode = 3'b001;
        in = 64'sh7F7F7F7F7F7F7F7F;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd1);

        // TEST 11: Binary - Large Negative
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Binary Large Negative", test_num);
        activation_mode = 3'b001;
        in = 64'sh8080808080808080;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd0);

        // ========================================
        // Identity Activation Tests (Mode 2)
        // ========================================

        // TEST 12: Identity - Positive Input
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Identity Positive", test_num);
        activation_mode = 3'b010;
        in = 64'sh1234567812345678;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sh1234567812345678);

        // TEST 13: Identity - Negative Input
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Identity Negative", test_num);
        activation_mode = 3'b010;
        in = -64'sd10;
        @(posedge clk);
        @(negedge clk);
        check_output(status, -64'sd10);

        // TEST 14: Identity - Zero Input
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Identity Zero", test_num);
        activation_mode = 3'b010;
        in = 64'sd0;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd0);

        // TEST 15: Identity - All Bits Set
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Identity All Bits", test_num);
        activation_mode = 3'b010;
        in = 64'shFFFFFFFFFFFFFFFF;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'shFFFFFFFFFFFFFFFF);

        // ========================================
        // Leaky ReLU Tests (Mode 3, α=0.5)
        // ========================================

        // TEST 16: Leaky ReLU - Positive Input
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Leaky ReLU Positive", test_num);
        activation_mode = 3'b011;
        in = 64'sh0808080808080808;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sh0808080808080808);

        // TEST 17: Leaky ReLU - Negative Input (Even)
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Leaky ReLU Negative Even", test_num);
        activation_mode = 3'b011;
        in = -64'sd8;  // -8 >> 1 = -4
        @(posedge clk);
        @(negedge clk);
        check_output(status, -64'sd4);

        // TEST 18: Leaky ReLU - Negative Input (Odd)
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Leaky ReLU Negative Odd", test_num);
        activation_mode = 3'b011;
        in = -64'sd9;  // -9 >> 1 = -5 (arithmetic shift)
        @(posedge clk);
        @(negedge clk);
        check_output(status, -64'sd5);

        // TEST 19: Leaky ReLU - Zero
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Leaky ReLU Zero", test_num);
        activation_mode = 3'b011;
        in = 64'sd0;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd0);

        // TEST 20: Leaky ReLU - Large Negative
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Leaky ReLU Large Negative", test_num);
        activation_mode = 3'b011;
        in = 64'sh8080808080808080;  // -128 >> 1 = -64
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'shC0C0C0C0C0C0C0C0);

        // ========================================
        // Mode Switching Tests
        // ========================================

        // TEST 21: Switch from ReLU to Binary
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Mode Switch ReLU to Binary", test_num);
        activation_mode = 3'b000;  // ReLU
        in = 64'sh0505050505050505;
        @(posedge clk);
        @(negedge clk);
        check_output("Mode Switch Step 1", 64'sh0505050505050505);
        // Switch to binary
        activation_mode = 3'b001;  // Binary
        in = 64'sh0505050505050505;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd1);

        // TEST 22: Switch from Identity to Leaky ReLU
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Mode Switch Identity to Leaky ReLU", test_num);
        activation_mode = 3'b010;  // Identity
        in = -64'sd10;
        @(posedge clk);
        @(negedge clk);
        check_output("Mode Switch Step 2", -64'sd10);
        // Switch to leaky ReLU
        activation_mode = 3'b011;  // Leaky ReLU
        in = -64'sd10;
        @(posedge clk);
        @(negedge clk);
        check_output(status, -64'sd5);

        // ========================================
        // Edge Case Tests
        // ========================================

        // TEST 23: ReLU - Boundary (Almost Zero Positive)
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: ReLU Boundary Positive", test_num);
        activation_mode = 3'b000;
        in = 64'sd1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd1);

        // TEST 24: ReLU - Boundary (Almost Zero Negative)
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: ReLU Boundary Negative", test_num);
        activation_mode = 3'b000;
        in = -64'sd1;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd0);

        // TEST 25: Invalid Mode (Default to Identity)
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Invalid Mode", test_num);
        activation_mode = 3'b111;  // Invalid mode
        in = 64'sh1111222233334444;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sh1111222233334444);  // Should default to identity

        // TEST 26: Reset During Operation
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Reset During Operation", test_num);
        activation_mode = 3'b000;
        in = 64'sh5555555555555555;
        @(posedge clk);
        reset_dut();
        check_output(status, 64'sd0);

        // TEST 27: Sequential Different Modes
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Sequential Mode Changes", test_num);
        in = 64'sh0F0F0F0F0F0F0F0F;
        // ReLU
        activation_mode = 3'b000;
        @(posedge clk);
        @(negedge clk);
        // Binary
        activation_mode = 3'b001;
        @(posedge clk);
        @(negedge clk);
        // Identity
        activation_mode = 3'b010;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sh0F0F0F0F0F0F0F0F);

        // TEST 28: Alternating Positive/Negative with ReLU
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: ReLU Alternating Signs", test_num);
        activation_mode = 3'b000;
        in = 64'sh0A0A0A0A0A0A0A0A;
        @(posedge clk);
        @(negedge clk);
        check_output("Alternating Step 1", 64'sh0A0A0A0A0A0A0A0A);
        in = 64'shF6F6F6F6F6F6F6F6;  // Negative
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sd0);

        // TEST 29: Leaky ReLU - Small Negative Values
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: Leaky ReLU Small Negative", test_num);
        activation_mode = 3'b011;
        in = -64'sd2;
        @(posedge clk);
        @(negedge clk);
        check_output(status, -64'sd1);

        // TEST 30: All Modes with Same Input
        test_num = test_num + 1;
        status = $sformatf("TEST %0d: All Modes Same Input", test_num);
        in = 64'sh1010101010101010;
        // ReLU
        activation_mode = 3'b000;
        @(posedge clk);
        @(negedge clk);
        check_output("All Modes ReLU", 64'sh1010101010101010);
        // Binary
        activation_mode = 3'b001;
        @(posedge clk);
        @(negedge clk);
        check_output("All Modes Binary", 64'sd1);
        // Identity
        activation_mode = 3'b010;
        @(posedge clk);
        @(negedge clk);
        check_output("All Modes Identity", 64'sh1010101010101010);
        // Leaky ReLU
        activation_mode = 3'b011;
        @(posedge clk);
        @(negedge clk);
        check_output(status, 64'sh1010101010101010);

        $display("\n===========================================");
        $display("All Activation Tests Complete!");
        $display("===========================================\n");
        
        @(negedge clk);
        @(negedge clk);
        $finish;
    end
endmodule

/* verilator coverage_on */

