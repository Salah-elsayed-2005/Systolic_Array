`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_data_buffer ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    //input from controller
    logic read_w_enable;
    logic read_in_enable;
    logic write_w_enable;
    logic write_in_enable;
    logic [1:0] hsize;
    logic [2:0] weight_num;
    logic [2:0] in_num;
    logic [63:0] data;
    logic out2bias;

    //input from activation
    logic [63:0] out_actv;

    // output to controller
    logic [63:0] sram_data;
    logic [1:0] sram_state;

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

    data_buffer #() DUT (.*);

    initial begin
        n_rst = 1;

        reset_dut;

        hsize = 3;
        write_w_enable = 0;
        write_in_enable = 0;
        read_w_enable = 0;
        read_in_enable = 0;
        weight_num = 0;
        in_num = 0;
        //write first 4 weights
        repeat (4)begin
        write_w_enable = 1;
        data = 64'hA7A6A5A4A3A2A1A0;
        repeat (5) @(negedge clk);
        write_w_enable = 0;
        weight_num = weight_num + 1;
        repeat (2) @(negedge clk);
        end
        
        

        //write second 4 weights
        repeat (4)begin
        write_w_enable = 1;
        data = 64'hB7B6B5B4B3B2B1B0;
        repeat (5) @(negedge clk);
        write_w_enable = 0;
        weight_num = weight_num + 1;
        repeat (2) @(negedge clk);
        end
    
    //write first 4 inputs
        repeat (4)begin;
        write_in_enable = 1;
        data = 64'hC7C6C5C4C3C2C1C0;
        repeat (5) @(negedge clk);
        in_num = in_num + 1;
        write_in_enable = 0;
        repeat (2) @(negedge clk);
        end

    //write second 4 inputs
        repeat (4)begin
        write_in_enable = 1;
        data = 64'hD7D6D5D4D3D2D1D0;
        repeat (5) @(negedge clk);
            write_in_enable = 0;
        in_num = in_num + 1;
        repeat (2) @(negedge clk);
        end

        
    /*
        //read first 4 weights
        weight_num = 0;
        repeat (4) begin
            
            read_w_enable = 1;
        repeat (7) @(negedge clk);
            read_w_enable = 0;
            weight_num = weight_num + 1;
            repeat (2) @(negedge clk);
        end
    */

        //read first 4 inputs
       in_num = 0;
        repeat (4) begin
            read_in_enable = 1;
        repeat (5) @(negedge clk);
            read_in_enable = 0;
            in_num = in_num + 1;
            repeat (2) @(negedge clk);
        end

        //read second 4 inputs
       in_num = 4;
        repeat (4) begin
            read_in_enable = 1;
        repeat (5) @(negedge clk);
            read_in_enable = 0;
            in_num = in_num + 1;
            repeat (2) @(negedge clk);
        end
        out_actv = 64'hE7E6E5E4E3E2E1E0;
        out2bias = 1;
        repeat (10) @(negedge clk);

        $finish;
    end
endmodule

/* verilator coverage_on */

