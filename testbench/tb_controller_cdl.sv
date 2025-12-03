`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_controller_cdl ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    // input from ahb
    logic start_inference;
    logic load_weights;
    logic store_weights, store_inputs;
    logic [63:0] weights,inputs;
    // inputs from sram
    logic [1:0]sram_state;
    logic [63:0] sram_data;

    // output to ahb
    logic data_ready;
    logic buffer_busy,design_busy;
    logic [63:0] systolic_out;
    logic weights_loaded;
    // output to sys
    logic [63:0] in;
    logic [63:0] weight;
    logic shift_enable,operate_f,out2bias;
    // output to sram_buffer
    logic [63:0] data;
    logic read_w_enable,read_in_enable;
    logic [2:0] weight_num,in_num;
    logic [1:0] hsize;
    logic write_in_enable,write_w_enable;
    logic store_output;

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

    controller_cdl #() DUT (.*);

    initial begin
        n_rst = 1;

        reset_dut;

        
        weights = 64'hA0A1A2A3A4A5A6A7;
        repeat (4) begin
        store_weights = 1;
        @(negedge clk);
        sram_state = 2;
        @(negedge clk);
        end

        weights = 64'hB0B1B2B3B4B5B6B7;
        repeat (4) begin
        store_weights = 1;
        @(negedge clk);
        sram_state = 2;
        @(negedge clk);
        end
        
        store_weights = 0;
        
        
        inputs = 64'hC0C1C2C3C4C5C6C7;
        repeat (4) begin
        store_inputs = 1;
        @(negedge clk);
        sram_state = 2;
        @(negedge clk);
        end

        inputs = 64'hD0D1D2D3D4D5D6D7;
        repeat (4) begin
        store_inputs = 1;
        @(negedge clk);
        sram_state = 2;
        @(negedge clk);
        end

        store_inputs = 0;

        load_weights = 1;
        repeat (5) begin 
            sram_data = 64'hA0A1A2A3A4A5A6A7;
            @(negedge clk);
        end
        repeat (5) begin 
            sram_data = 64'hB0B1B2B3B4B5B6B7;
            @(negedge clk);
        end
        load_weights = 0;
        start_inference = 1;
        sram_data = 64'hC0C1C2C3C4C5C6C7;
        repeat (2) @(negedge clk);
        start_inference = 0;
        repeat (7) begin 
            sram_data = 64'hC0C1C2C3C4C5C6C7;
            @(negedge clk);
        end
        repeat (7) begin 
            sram_data = 64'hD0D1D2D3D4D5D6D7;
            @(negedge clk);
        end

        
        repeat (10) @(negedge clk);


        $finish;
    end
endmodule

/* verilator coverage_on */

