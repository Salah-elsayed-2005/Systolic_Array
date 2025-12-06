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
        hsel = 0;
        haddr = 10'b0;
        htrans = 2'b0;
        hsize = 2'b0;
        hwrite = 0;
        hwdata = 64'b0;
        hburst = 3'b0;

        reset_dut;

        // Write weight 1
        hsel = 1;
        haddr = 10'b0000000000;
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE
        hwdata = 64'h0101010101010101;
        repeat (11) @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);

        // Write weight 2
        hsel = 1;
        haddr = 10'b0000000000;
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE
        hwdata = 64'h0101010101010101;
        repeat (11) @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);

        // Write weight 3
        hsel = 1;
        haddr = 10'b0000000000;
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE
        hwdata = 64'h0101010101010101;
        repeat (11) @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);

        // Write weight 4
        hsel = 1;
        haddr = 10'b0000000000;
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE
        hwdata = 64'h0101010101010101;
        repeat (11) @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);

        // Write weight 5
        hsel = 1;
        haddr = 10'b0000000000;
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE
        hwdata = 64'h0101010101010101;
        repeat (11) @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);

        // Write weight 6
        hsel = 1;
        haddr = 10'b0000000000;
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE
        hwdata = 64'h0101010101010101;
        repeat (11) @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);

        // write weight 7
        hsel = 1;
        haddr = 10'b0000000000;
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE
        hwdata = 64'h0101010101010101;
        repeat (11) @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);

        // write weight 8
        hsel = 1;
        haddr = 10'b0000000000;     
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE
        hwdata = 64'h0101010101010101;
        repeat (11) @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);

        //write inputs 
        hsel = 1;
        haddr = 10'b0000001000;     
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE
        hwdata = 64'h0807060504030201;
        repeat (11) @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);
        
        // start inference
        hsel = 1;
        haddr = 22;    
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE
        hwdata = 2;
        repeat (60) @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);

        hsel = 1;
        haddr = 24;    
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE  
        hwdata = 0;
        @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);


        hsel = 1;
        haddr = 22;    
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 1;
        hburst = 3'b000; // SINGLE  
        hwdata = 1;
        repeat (28) @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);


        hsel = 1;
        haddr = 18;    
        htrans = 2'b10; // NONSEQ
        hsize = 2'b11; // 64-bit
        hwrite = 0;
        hburst = 3'b000; // SINGLE  
        @(negedge clk);
        hsel = 0;
        hwrite = 0;
        @(negedge clk);
        


        

        $finish;
    end
endmodule

/* verilator coverage_on */

