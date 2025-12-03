`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_activation ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic [2:0] activation_mode;
    logic signed [63:0] in, out;

    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    activation #() DUT (.*);

    initial begin
        clk = 0;
        n_rst = 0;
        activation_mode = 0;
        in = 0;
        
        @(posedge clk);
        @(posedge clk);
        n_rst = 1;
        @(posedge clk);
        
        activation_mode = 3'b000;
        in = 64'sh0A0A0A0A0A0A0A0A;
        @(posedge clk);
        @(posedge clk);
        
        in = -64'sd1;
        @(posedge clk);
        @(posedge clk);
        
        activation_mode = 3'b001;
        in = 64'sh0A0A0A0A0A0A0A0A;
        @(posedge clk);
        @(posedge clk);
        
        in = -64'sd1;
        @(posedge clk);
        @(posedge clk);
        
        activation_mode = 3'b010;
        in = -64'sd10;
        @(posedge clk);
        @(posedge clk);
        
        activation_mode = 3'b011;
        in = 64'sh0808080808080808;
        @(posedge clk);
        @(posedge clk);
        
        in = -64'sd8;
        @(posedge clk);
        @(posedge clk);
        
        $finish;
    end
endmodule

/* verilator coverage_on */

