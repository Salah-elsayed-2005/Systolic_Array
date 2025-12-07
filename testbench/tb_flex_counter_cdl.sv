`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_flex_counter_cdl ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;
    logic clear,count_enable;
    logic [3:0]rollover_val;
    logic [3:0]count_out;
    logic rollover_flag;
    flex_counter#(.SIZE(4)) DUT (.*);
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
        @(negedge clk);
        @(negedge clk);
    end
    endtask

    initial begin
        n_rst = 1;
        reset_dut;
        clear =0;
        count_enable=0;
        rollover_val=15;
        #20;
        count_enable=1;
        #20;
        #20;
        count_enable=0;
        #20;
        count_enable=1;
        #50;
        #50;
        count_enable=0;
        #20;
        count_enable=1;
        #50;
        clear=1;
        rollover_val=5;
        #20;
        clear=0;
        #20;
        #20;
        #10;
        count_enable=0;
        #20;
        $finish;
    end
endmodule

/* verilator coverage_on */

