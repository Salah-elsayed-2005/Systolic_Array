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
        in_bus    = 64'h0101010101010101;
        repeat (8) @(posedge clk);

        operate_f = 1'b0;
        repeat (7) @(posedge clk);  // Wait for data to reach last column
        send2bias = 1'b1;
        @(posedge clk);


        $finish;
    end
endmodule

/* verilator coverage_on */
