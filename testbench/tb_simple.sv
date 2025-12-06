`timescale 1ns / 10ps

module tb_simple ();
    localparam CLK_PERIOD = 10ns;
    
    logic clk, n_rst;
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
    
    // Clock generation
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end
    
    ahb_accelerator #() DUT (.*);
    
    initial begin
        // Initialize
        n_rst = 0;
        hsel = 0;
        haddr = 10'b0;
        htrans = 2'b0;
        hsize = 2'b0;
        hwrite = 0;
        hwdata = 64'b0;
        hburst = 3'b0;
        
        // Reset
        #(CLK_PERIOD * 2);
        n_rst = 1;
        #(CLK_PERIOD * 4);
        
        // Write weight to address 0x00
        @(negedge clk);
        hsel = 1;
        haddr = 10'h00;
        htrans = 2'b10;  // NONSEQ
        hsize = 2'b11;   // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE
        
        @(negedge clk);
        hwdata = 64'h0102030405060708;
        
        @(posedge clk);
        while(!hready) @(posedge clk);
        
        @(negedge clk);
        hsel = 0;
        htrans = 2'b00;
        hwrite = 0;
        hwdata = 64'b0;
        
        #1000ns;
        $finish;
    end
endmodule
