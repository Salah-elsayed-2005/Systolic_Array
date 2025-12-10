`timescale 1ns / 10ps




module controller_cdl #(
    // parameters
) (
    input clk, n_rst,
    // input from ahb
    input logic start_inference,
    input logic load_weights,
    input logic store_weights, store_inputs,
    input logic [63:0] weights,inputs,
    // inputs from sram
    input logic [1:0]sram_state,
    input logic [63:0] sram_data,

    // output to ahb
    output logic data_ready,
    output logic buffer_busy,design_busy,
    output logic [63:0] systolic_out,
    output logic weight_ready,
    // output to sys
    output logic [63:0] in_bus,
    //output logic [63:0] weight,
    output logic shift_enable,operate_f,out2bias,
    // output to sram_buffer
    output logic [63:0] data,
    output logic read_w_enable,read_in_enable,
    output logic [2:0] weight_num,in_num,
    output logic [1:0] hsize,
    output logic write_in_enable,write_w_enable,
    output logic store_output

);
   logic [63:0] in_bus_r;
   
    typedef enum logic [5:0] {
        IDLE      = 0,
        LOAD_weight =1,   
        LOAD_input =2,
        LOAD_C1 = 3,
        Wait_c1 = 4,
        LOAD_C2 =5,
        Wait_c2 = 6,
        LOAD_C3 = 7,
        Wait_c3 = 8,
        LOAD_C4 =9,
        Wait_c4 = 10,
        LOAD_C5 = 11,
        Wait_c5 = 12,
        LOAD_C6 =13,
        Wait_c6 = 14,
        LOAD_C7 =15,
        Wait_c7 = 16,
        LOAD_C8 =17,
        Weights_loaded=18,
        Read_i1 =19,
        Operate_D1 =20,
        Operate_D2 =21,
        Operate_D3 =22,
        Operate_D4 =23,
        Operate_D5 =24,
        Operate_D6 =25,
        Operate_D7 =26,
        Operate_D8 =27,
        Wait_1 = 28,
        Wait_2 = 29,
        Wait_3 = 30,
        Wait_4 = 31,
        Wait_5 = 32,
        Wait_6 = 33,
        Wait_7 = 34,
        Wait_8 = 35,
        Send2Bias = 36,
        Send2ACTV = 37,
        Store_out =38,
        DONE =39,
        Wait_data_ready =40
    } state_t;
    state_t current_state,next_state;

    always_ff @(posedge clk , negedge n_rst) begin
        if(!n_rst)
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end

        always_ff @(posedge clk or negedge n_rst) begin
            if (!n_rst)
                in_bus_r <= 64'd0;
            else if (current_state == Read_i1)
                in_bus_r <= sram_data;   // capture the SRAM data only in this state
            else
                in_bus_r <= in_bus_r;    // hold previous value (no latch because it's FF)
        end


    always_comb begin 
        next_state = current_state;
        case(current_state)
            IDLE : begin
                if(store_inputs)
                    next_state = LOAD_input;
                else if(store_weights)
                    next_state = LOAD_weight;
                else if(load_weights)
                    next_state = LOAD_C1;
                else if(start_inference)
                    next_state = Read_i1;
                else
                    next_state = IDLE;

            end
            LOAD_weight : begin
                if( sram_state==2)
                    next_state = IDLE;
                else
                    next_state = LOAD_weight; 
            end
            LOAD_input: begin
                if( sram_state==2)
                    next_state = IDLE;
                else
                    next_state = LOAD_input;
            end
            LOAD_C1:begin
                if(sram_state==2)
                    next_state = Wait_c1;
                else
                    next_state = LOAD_C1;
            end
            Wait_c1:begin
                    next_state = LOAD_C2;
            end
            LOAD_C2:begin
                if(sram_state==2)
                    next_state = Wait_c2;
                else
                    next_state = LOAD_C2;
            end
            Wait_c2:begin
                    next_state = LOAD_C3;
            end
            LOAD_C3:begin
                if(sram_state==2)
                    next_state = Wait_c3;
                else
                    next_state = LOAD_C3;
            end
            Wait_c3:begin
                    next_state = LOAD_C4;
            end
            LOAD_C4:begin
                if(sram_state==2)
                    next_state = Wait_c4;
                else
                    next_state = LOAD_C4;
            end
            Wait_c4:begin
                    next_state = LOAD_C5;
            end
            LOAD_C5:begin
                if(sram_state==2)
                    next_state = Wait_c5;
                else
                    next_state = LOAD_C5;
            end
            Wait_c5:begin
                    next_state = LOAD_C6;
            end
            LOAD_C6:begin
                if(sram_state==2)
                    next_state = Wait_c6;
                else
                    next_state = LOAD_C6;
            end
            Wait_c6:begin
                    next_state = LOAD_C7;
            end
            LOAD_C7:begin
                if(sram_state==2)
                    next_state = Wait_c7;
                else
                    next_state = LOAD_C7;
            end
            Wait_c7:begin
                    next_state = LOAD_C8;
            end
            LOAD_C8:begin
                if(sram_state==2)
                    next_state = Weights_loaded;
                else
                    next_state = LOAD_C8;
            end
            Weights_loaded: begin
                next_state = IDLE;
            end
            Read_i1: begin
                if(sram_state==2)
                    next_state = Operate_D1;
                else
                    next_state = Read_i1;
            end
            Operate_D1: begin
                next_state = Operate_D2;
            end
            
            Operate_D2: begin  
                next_state = Operate_D3;             
            end
            
            Operate_D3: begin
                next_state = Operate_D4;
            end
            
            Operate_D4: begin
                next_state = Operate_D5;
            end
            
            Operate_D5: begin
                next_state = Operate_D6;
            end
            
            Operate_D6: begin
                next_state = Operate_D7;
            end
           
            Operate_D7: begin
                next_state = Operate_D8;
            end
            
            Operate_D8: begin
                next_state = Wait_1;
            end
            Wait_1: begin
                next_state = Wait_2;
            end
            Wait_2: begin
                next_state = Wait_3;
            end
            Wait_3: begin
                next_state = Wait_4;
            end
            Wait_4: begin
                next_state = Wait_5;
            end
            Wait_5: begin
                next_state = Wait_6;
            end
            Wait_6: begin
                next_state = Wait_7;
            end
            Wait_7: begin
                next_state = Wait_8;
            end
            Wait_8: begin
                next_state = Send2Bias;
            end
            Send2Bias: begin
                next_state = Send2ACTV;
            end
            Send2ACTV: begin
                next_state = Store_out;
            end
            Store_out: begin
                if(sram_state==2)
                    next_state = DONE;
            end
            DONE: begin
                next_state = Wait_data_ready;
            end
                Wait_data_ready: begin
                 next_state = IDLE;
                end
            default: begin
                 next_state = IDLE; // safe recovery
    end
    endcase
    end

    logic [2:0] weight_count_r;
    //weight_count_n;
    // //logic [2:0] in_count_r, in_count_n;
    // always_ff @(posedge clk, negedge n_rst) begin
    //      if (!n_rst) begin
    //         weight_count_r <= 0;
    //         //in_count_r <= 0;
    //     end else begin
    //         weight_count_r <= weight_count_n;
    //         //in_count_r <= in_count_n;
    //     end
    // end


    flex_counter_cdl #(
        .SIZE(3)
    ) weight_counter (
        .clk(clk),
        .n_rst(n_rst),
        .rollover_val(3'd7),
        .count_enable((sram_state==2) && (write_w_enable || read_w_enable)),
        .clear(!n_rst),
        .count_out(weight_count_r),
        /* verilator lint_off PINCONNECTEMPTY */
         .rollover_flag() 
        /* verilator lint_on PINCONNECTEMPTY */
    );
    // always_comb begin
    //     weight_count_n = weight_count_r;
    //     //in_count_n     = in_count_r;

    // // ----- weight counter -----
    //     if (sram_state==2 && (write_w_enable||read_w_enable)) begin
    //         if (weight_count_r == 7)
    //             weight_count_n = 0;
    //         else
    //             weight_count_n = weight_count_r + 1;
    //     end

    // // ----- input counter -----
    // //    if (sram_state==2 && (write_in_enable||read_in_enable)) begin
    // //        if (in_count_r == 7)
    // //            in_count_n = 0;
    // //        else
    // //            in_count_n = in_count_r + 1;
    // //    end
    // end

    

    always_comb begin
        // default outputs
        data_ready = 0;
        buffer_busy = 0;
        design_busy = 0;
        systolic_out = 64'b0;
        weight_ready = 0;
        in_bus = 64'b0;
        data = 64'b0;
        shift_enable = 0;
        operate_f = 0;
        read_w_enable = 0;
        read_in_enable = 0;
        hsize = 2'b11;
        store_output = 0;
        //hsize = 2'b00;
        write_in_enable = 0;
        write_w_enable = 0;
        out2bias = 0;

    

        case(current_state)
            IDLE: begin
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
                design_busy = 0;
                buffer_busy = 0;
            end
            LOAD_weight: begin
                data = weights;
                buffer_busy = 1;
                design_busy = 1;
                write_w_enable = 1;
                weight_num = 7-weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            LOAD_input: begin
                data = inputs;
                buffer_busy = 1;
                design_busy = 1;
                write_in_enable = 1;
                //in_num = in_count_r;
                in_num = 0;
                weight_num = weight_count_r;
            
            end
            LOAD_C1, LOAD_C2, LOAD_C3, LOAD_C4,
            LOAD_C5, LOAD_C6, LOAD_C7, LOAD_C8: begin
                in_bus = sram_data;
                read_w_enable = 1;
                buffer_busy = 1;
                design_busy = 1;
                if(sram_state==2) shift_enable = 1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Wait_c1, Wait_c2, Wait_c3, Wait_c4, Wait_c5, Wait_c6, Wait_c7: begin
                in_bus = sram_data;
                design_busy = 1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Weights_loaded: begin
                design_busy = 0;
                buffer_busy = 0;
                read_w_enable = 0;  
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
                weight_ready = 1;
            end
            Read_i1: begin
                read_in_enable = 1;
                buffer_busy = 1;
                design_busy = 1;
                in_bus = sram_data;
                //in_num = in_count_r;
                in_num = 0;
                weight_num = weight_count_r;
                
            end
            Operate_D1: begin
                in_bus=64'h0;
                in_bus[7:0] = in_bus_r[7:0];
                operate_f = 1;
                shift_enable = 1;
                design_busy = 1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Operate_D2: begin
                in_bus=64'h0;
                in_bus[15:8] = in_bus_r[15:8];
                operate_f = 1;
                shift_enable = 1;
                design_busy = 1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Operate_D3: begin
                in_bus=64'h0;
                in_bus[23:16] = in_bus_r[23:16];
                operate_f = 1;
                shift_enable = 1;
                design_busy = 1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Operate_D4: begin
                in_bus=64'h0;
                in_bus[31:24] = in_bus_r[31:24];
                operate_f = 1;
                shift_enable = 1;
                design_busy = 1;
                weight_num = weight_count_r;  
                //in_num = in_count_r;
                in_num = 0;      
            end 
            Operate_D5: begin
                in_bus=64'h0;
                in_bus[39:32] = in_bus_r[39:32];
                operate_f = 1;
                shift_enable = 1;
                design_busy = 1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Operate_D6: begin
                in_bus=64'h0;
                in_bus[47:40] = in_bus_r[47:40];
                operate_f = 1;
                shift_enable = 1;
                design_busy = 1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Operate_D7: begin
                in_bus=64'h0;
                in_bus[55:48] = in_bus_r[55:48];
                operate_f = 1;
                shift_enable = 1;
                design_busy = 1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Operate_D8: begin
                in_bus=64'h0;
                in_bus[63:56] = in_bus_r[63:56];
                operate_f = 1;
                shift_enable = 1;
                design_busy = 1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Wait_1, Wait_2, Wait_3, Wait_4, Wait_5, Wait_6,Wait_7,Wait_8: begin
                design_busy = 1;
                operate_f=1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Send2Bias: begin
                design_busy = 1;
                out2bias =1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Send2ACTV: begin
                design_busy = 1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            Store_out: begin
                design_busy = 1;
                store_output=1;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
            DONE: begin
                data_ready =1;
                systolic_out = sram_data;
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
            end
                Wait_data_ready: begin
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
                systolic_out = sram_data;
                data_ready =1;
            end
            default: begin
                weight_num = weight_count_r;
                //in_num = in_count_r;
                in_num = 0;
                design_busy = 0;
                buffer_busy = 0;
            end
        endcase
    end

endmodule

