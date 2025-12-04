`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_ahb_accelerator ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;

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

    logic hsel;
    logic [9:0] haddr;
    logic [1:0] htrans;
    logic [1:0] hsize;
    logic hwrite;
    logic [63:0] hwdata;
    logic [2:0] hburst;
    logic [63:0] hrdata;
    logic hready;
    logic hresp;
    ahb_accelerator #() DUT (.*);

    initial begin
        n_rst = 1;

        reset_dut;

        $finish;
    end
endmodule

/* verilator coverage_on */

