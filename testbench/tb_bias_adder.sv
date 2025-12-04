`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_bias_adder ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic [63:0] out_acc, bias, out_b;

    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    bias_adder #() DUT (.*);

    initial begin
        clk = 0;
        n_rst = 0;
        out_acc = 0;
        bias = 0;
        
        @(posedge clk);
        @(posedge clk);
        n_rst = 1;
        @(posedge clk);
        
        out_acc = 64'h0808080808080808;
        bias = 64'h0202020202020202;
        @(posedge clk);
        @(posedge clk);
        
        out_acc = 64'h7F7F7F7F7F7F7F7F;
        bias = 64'h0101010101010101;
        @(posedge clk);
        @(posedge clk);
        
        out_acc = 64'hFEFEFEFEFEFEFEFE;
        bias = 64'hFEFEFEFEFEFEFEFE;
        @(posedge clk);
        @(posedge clk);
        
        $finish;
    end
endmodule

/* verilator coverage_on */

