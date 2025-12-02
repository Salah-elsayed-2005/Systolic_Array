`timescale 1ns/10ps



module data_buffer #(
    // parameters
) (
    input clk, n_rst,
    //input from controller
    input logic read_w_enable,
    input logic read_in_enable,
    input logic write_w_enable,
    input logic write_in_enable,
    input logic [1:0] hsize,
    input logic [2:0] weight_num,
    input logic [2:0] in_num,
    input logic [63:0] data,
    input logic out2bias,

    //input from activation
    input logic [63:0] out_actv,
    
    // output to controller
    output logic [63:0] sram_data,
    output logic [1:0] sram_state
);
    // internal signals
        logic [7:0] buffer [0:7][0:7];
        logic [3:0] num_bytes;
        logic [9:0] address_w1,address_w2,address_in1,address_in2,address_out1,address_out2;
        logic write_w1_enable,write_w2_enable,write_in1_enable,write_in2_enable, write_out1_enable,write_out2_enable;
        logic read_w1_enable,read_w2_enable,read_in1_enable,read_in2_enable,read_out1_enable,read_out2_enable;
        logic [31:0] write_w1_data,write_w2_data,write_in1_data,write_in2_data, write_out1_data,write_out2_data;
        logic [31:0] read_w1_data,read_w2_data,read_in1_data,read_in2_data;
        logic [1:0]sram_w1_state,sram_in1_state,sram_out1_state;
        

           
        sram1024x32_wrapper ram_w1 (
            .clk(clk),
            .n_rst(n_rst),
            .address (address_w1),
            .read_enable(read_w1_enable),
            .write_enable(write_w1_enable),
            .write_data(write_w1_data),
            .read_data(read_w1_data),
            .sram_state(sram_w1_state)
        );

        sram1024x32_wrapper ram_w2 (
            .clk(clk),
            .n_rst(n_rst),
            .address (address_w2),
            .read_enable(read_w2_enable),
            .write_enable(write_w2_enable),
            .write_data(write_w2_data),
            .read_data(read_w2_data),
            
            /* verilator lint_off PINCONNECTEMPTY */
            .sram_state()
            /* verilator lint_on PINCONNECTEMPTY */
        );
           


        sram1024x32_wrapper ram_in1 (
            .clk(clk),
            .n_rst(n_rst),
            .address (address_in1),
            .read_enable(read_in1_enable),
            .write_enable(write_in1_enable),
            .write_data(write_in1_data),
            .read_data(read_in1_data),
            .sram_state(sram_in1_state)
        );

    /* verilator lint_off WIDTHCONCAT */

        sram1024x32_wrapper ram_in2 (
            .clk(clk),
            .n_rst(n_rst),
            .address(address_in2),
            .read_enable(read_in2_enable),
            .write_enable(write_in2_enable),
            .write_data(write_in2_data),
            .read_data(read_in2_data),
            
            /* verilator lint_off PINCONNECTEMPTY */
            .sram_state()
            /* verilator lint_on PINCONNECTEMPTY */
        );

         /* verilator lint_on WIDTHCONCAT */
        
        sram1024x32_wrapper ram_out1 (
            .clk(clk),
            .n_rst(n_rst),
            .address (address_out1),
            
            .read_enable(read_out1_enable),
            
            .write_enable(write_out1_enable),
            .write_data(write_out1_data),
                
            
            
            /* verilator lint_off PINCONNECTEMPTY */
            .read_data(),
            /* verilator lint_on PINCONNECTEMPTY */

            .sram_state(sram_out1_state)
        );

    /* verilator lint_off WIDTHCONCAT */

        sram1024x32_wrapper ram_out2 (
            .clk(clk),
            .n_rst(n_rst),
            .address(address_out2),
            
            
            .read_enable(read_out2_enable),
            
            .write_enable(write_out2_enable),
            .write_data(write_out2_data),
            
            /* verilator lint_off PINCONNECTEMPTY */
            .read_data(),
            /* verilator lint_on PINCONNECTEMPTY */



            /* verilator lint_off PINCONNECTEMPTY */
            .sram_state()
            /* verilator lint_on PINCONNECTEMPTY */
        );

         /* verilator lint_on WIDTHCONCAT */
        

        logic  out2bias_d1, out2bias_d2;

        always_ff @(posedge clk or negedge n_rst) begin
              if (!n_rst) begin
                 out2bias_d1 <= 1'b0;
                 out2bias_d2 <= 1'b0;
            end else begin
                  out2bias_d1 <= out2bias;
                  out2bias_d2 <= out2bias_d1;
             end
        end


        always_comb begin
            write_in1_data = 32'h00000000;
            write_in2_data = 32'h00000000;
            write_w1_data = 32'h00000000;
            write_w2_data = 32'h00000000;
            write_out1_data = 32'h00000000;
            write_out2_data = 32'h00000000;

            write_w1_enable = 0;
            write_w2_enable = 0;
            write_in1_enable = 0;
            write_in2_enable = 0;
            write_out1_enable = 0;
            write_out2_enable = 0;

            read_w1_enable = 0;
            read_w2_enable = 0;
            read_in1_enable = 0;
            read_in2_enable = 0;
            read_out1_enable = 0;
            read_out2_enable = 0;

            address_w1 = 10'h0;
            address_w2 = 10'h0;
            address_in1 = 10'h0;
            address_in2 = 10'h0;
            address_out1 = 10'h0;
            address_out2 = 10'h0;
            

            sram_state = 2'b00;
            num_bytes = 4'h0;
            buffer[0][0] = 8'h00;
            sram_data = 64'h0000000000000000;

        

        if(write_w_enable) begin
            num_bytes = 1<<hsize;
            for(int j=0; j<8; j=j+1) begin
                buffer[weight_num][j] = 8'h00;
            end
            for(int i=0; i<num_bytes; i=i+1) begin
                buffer[weight_num][i] = data[i*8 +: 8];
            end
            write_w1_data = {buffer[weight_num][3],buffer[weight_num][2]
            ,buffer[weight_num][1],buffer[weight_num][0]};
            address_w1[2:0] = weight_num;
            write_w1_enable = 1;

            write_w2_data = {buffer[weight_num][7],buffer[weight_num][6]
            ,buffer[weight_num][5],buffer[weight_num][4]};
            address_w2[2:0] = weight_num;
            write_w2_enable = 1;
            sram_state = sram_w1_state;

        end
        if(write_in_enable) begin
            num_bytes = 1<<hsize;

            for(int j=0; j<8; j=j+1) begin
                buffer[in_num][j] = 8'h00;
            end

            for(int i=0; i<num_bytes; i=i+1) begin
                buffer[in_num][i] = data[i*8 +: 8];
            end

            write_in1_data = {buffer[in_num][3],buffer[in_num][2]
            ,buffer[in_num][1],buffer[in_num][0]};
            address_in1[2:0] = in_num;
            write_in1_enable = 1;

            write_in2_data = {buffer[in_num][7],buffer[in_num][6]
            ,buffer[in_num][5],buffer[in_num][4]};
            address_in2[2:0] = in_num;
            write_in2_enable = 1;
            sram_state = sram_in1_state;
        end
        if(read_w_enable) begin
            address_w1[2:0] = weight_num;
            read_w1_enable = 1;
            address_w2[2:0] = weight_num;
            read_w2_enable = 1;
            sram_state = sram_w1_state;
            sram_data = {read_w2_data,read_w1_data};
        end
        if(read_in_enable) begin
            address_in1[2:0] = in_num;
            read_in1_enable = 1;
            address_in2[2:0] = in_num;
            read_in2_enable = 1;
            sram_state = sram_in1_state;
            sram_data = {read_in2_data,read_in1_data};
        end

        if(out2bias_d2)begin 
            
           
            write_out1_data = out_actv[31:0];
            address_out1[0] = 0;
            write_out1_enable = 1;

            write_out2_data = out_actv[63:32];
            address_out2[0] = 0;
            write_out2_enable = 1;

            sram_state = sram_out1_state;
            sram_data = out_actv;
        end
        end
        
endmodule



