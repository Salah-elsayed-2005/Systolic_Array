`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_systolic_array ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst, shift_enable, operate_f;
    logic [63:0] in_bus;
    logic send2bias;
    logic [63:0] col_sums, sum_to_bias;
    
    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    task reset_dut;
    begin
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    systolic_array #() DUT (.*);

    initial begin
        clk         = 0;
        n_rst       = 1;
        shift_enable= 0;
        operate_f   = 0;
        send2bias   = 0;
        in_bus      = '0;

        reset_dut;

        // weight load phase: all lanes = 1
        shift_enable = 1'b1;
        operate_f    = 1'b0;
        in_bus       = 64'h0101010101010101;
        repeat (8) @(posedge clk);

        shift_enable = 1'b0;
        @(posedge clk);

        operate_f = 1'b1;
        
        // Inference phase: feed one activation per row, staggered by one cycle each
        // Cycle 1: x1 = 0x01 enters row 0 (PE(0,0))
        // Cycle 2: x2 = 0x02 enters row 1 (PE(1,0))
        // ...
        // Cycle 8: x8 = 0x08 enters row 7 (PE(7,0))
        for (int cycle = 1; cycle <= 8; cycle++) begin
            // Create in_bus where only one row has a non-zero value
            // Byte for row (cycle-1) gets the value 'cycle', all others are 0
            in_bus = 64'h0000000000000000;
            in_bus[8*(cycle-1) +: 8] = 8'(cycle);
            @(posedge clk);
        end

        operate_f = 1'b0;
        in_bus    = '0;
        repeat (7) @(posedge clk);  // Wait for data to reach last column (drain phase)
        send2bias = 1'b1;
        @(posedge clk);

        $finish;
    end
endmodule

/* verilator coverage_on */
