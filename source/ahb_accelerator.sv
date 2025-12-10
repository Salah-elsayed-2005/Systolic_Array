`timescale 1ns / 10ps

module ahb_accelerator #(
    // parameters
) (
    input clk, n_rst,
    input logic hsel,
    input logic [9:0] haddr,
    input logic [1:0] htrans,
    input logic [1:0] hsize,
    input logic hwrite,
    input logic [63:0] hwdata,
    input logic [2:0] hburst,
    output logic [63:0] hrdata,
    output logic hready,
    output logic hresp
);


    // internal signals

    //contr & AHB
    logic store_weights;
    logic store_inputs;
    logic data_ready;
    logic buffer_busy;
    logic design_busy;
    logic [63:0] systolic_out;
    logic weight_ready;
    logic [63:0] weights;
    logic [63:0] inputs;
    logic start_inference;
    logic load_weights;

    //contr & data_buffer
    logic read_w_enable;
    logic read_in_enable;
    logic write_w_enable;
    logic write_in_enable;
    logic [2:0] weight_num;
    logic [2:0] in_num;
    logic [63:0] data;
    logic store_output;
    logic [63:0] sram_data;
    logic [1:0] sram_state;


    //contr & sys_array
    logic [63:0] in_bus;
    //logic [63:0] weight;
    logic operate_f;
    logic shift_enable;
    logic out2bias;

    //actv & data_buffer
    logic [63:0] out_actv;

    // sys_array & bias_adder
    logic [63:0] out_acc;

    //bias_adder & actv
    logic [63:0] out_b;

    //AHB & bias_adder
    logic [63:0] bias;

    //AHB & actv
    logic [2:0] activation_mode;

    
    ahb_subordinate_cdl ahb_sub_cdl (
        .clk(clk),
        .n_rst(n_rst),
        .hsel(hsel),
        .haddr(haddr[7:0]),
        .htrans(htrans),
        .hsize(hsize),
        .hwrite(hwrite),
        .hwdata(hwdata),
        .hburst(hburst),
        .hrdata(hrdata),
        .hready(hready),
        .hresp(hresp),
        .store_weights(store_weights),
        .store_inputs(store_inputs),
        .data_ready(data_ready),
        .buffer_busy(buffer_busy),
        .design_busy(design_busy),
        .systolic_out(systolic_out),
        .weight_ready(weight_ready),
        .weights(weights),
        .inputs(inputs),
        .start_inference(start_inference),
        .load_weights(load_weights), 
        .bias(bias),
        .actv_mode(activation_mode)
    );
    
    
    
   

    controller_cdl ctrl (
        .clk(clk),
        .n_rst(n_rst),
        .start_inference(start_inference),
        .load_weights(load_weights),
        .store_weights(store_weights),
        .store_inputs(store_inputs),
        .weights(weights),
        .inputs(inputs),
        .sram_state(sram_state),
        .sram_data(sram_data),
        .data_ready(data_ready),
        .buffer_busy(buffer_busy),
        .design_busy(design_busy),
        .systolic_out(systolic_out),
        .weight_ready(weight_ready),
        .in_bus(in_bus),
        //.weight(weight),
        .shift_enable(shift_enable),
        .operate_f(operate_f),
        .out2bias(out2bias),
        .data(data),
        .read_w_enable(read_w_enable),
        .read_in_enable(read_in_enable),
        .weight_num(weight_num),
        .in_num(in_num),
        /* verilator lint_off PINCONNECTEMPTY */
        .hsize(),
        /* verilator lint_on PINCONNECTEMPTY */
        .write_in_enable(write_in_enable),
        .write_w_enable(write_w_enable),
        .store_output(store_output)
        
    );

    data_buffer data_buf (
        .clk(clk),
        .n_rst(n_rst),
        .read_w_enable(read_w_enable),
        .read_in_enable(read_in_enable),
        .write_w_enable(write_w_enable),
        .write_in_enable(write_in_enable),
        .weight_num(weight_num),
        .in_num(in_num),
        .data(data),
        .store_output(store_output),
        .out_actv(out_actv),
        .sram_data(sram_data),
        .sram_state(sram_state)
    );


    systolic_array sys_array (
        .clk(clk),
        .n_rst(n_rst),
        .send2bias(out2bias),
        .in_bus(in_bus),                                  // handle it later from sys_array
        .shift_enable(shift_enable),
        .sum_to_bias(out_acc),
        .operate_f(operate_f),
        .float_in(0),
        /* verilator lint_off PINCONNECTEMPTY */
        .col_sums()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    bias_adder bias_add (
        .clk(clk),
        .n_rst(n_rst),
        .out_acc(out_acc),
        .bias(bias),
        .out_b(out_b),
        .float_in(0)
    );

    activation actv (
        .clk(clk),
        .n_rst(n_rst),
        .activation_mode(activation_mode),
        .in(out_b),
        .out(out_actv),
        .float_in(0)
    );



endmodule

