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
    output logic weights_loaded,
    // output to sys
    output logic [63:0] in,
    output logic [63:0] weight,
    output logic shift_enable,operate_f,out2bias,
    // output to sram_buffer
    output logic [63:0] data,
    output logic read_w_enable,read_in_enable,
    output logic [2:0] weight_num,in_num,
    output logic [1:0] hsize,
    output logic write_in_enable,write_w_enable,
    output logic store_output

);
   
   
    typedef enum logic [4:0] {
        IDLE      = 0,
        LOAD_weight =1,   
        LOAD_input =2,
        LOAD_C1 = 3,
        LOAD_C2 =4,
        LOAD_C3 = 5,
        LOAD_C4 =6,
        LOAD_C5 = 7,
        LOAD_C6 =8,
        LOAD_C7 =9,
        LOAD_C8 =10,
        Weights_loaded=11,
        Read_i1 =12,
        Operate_D1 =13,
        Read_i2 =14,
        Operate_D2 =15,
        Read_i3 =16,
        Operate_D3 =17,
        Read_i4 =18,
        Operate_D4 =19,
        Read_i5 =20,
        Operate_D5 =21,
        Read_i6 =22,
        Operate_D6 =23,
        Read_i7 =24,
        Operate_D7 =25,
        Read_i8 =26,
        Operate_D8 =27,
        Send2Bias = 28,
        Send2ACTV = 29,
        Store_out =30,
        DONE =31
    } state_t;
    state_t current_state,next_state;

    always_ff @(posedge clk , negedge n_rst) begin
        if(!n_rst)
            current_state <= IDLE;
        else 
            current_state <= next_state;
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
                    next_state = LOAD_C2;
                else
                    next_state = LOAD_C1;
            end
            LOAD_C2:begin
                if(sram_state==2)
                    next_state = LOAD_C3;
                else
                    next_state = LOAD_C2;
            end
            LOAD_C3:begin
                if(sram_state==2)
                    next_state = LOAD_C4;
                else
                    next_state = LOAD_C3;
            end
            LOAD_C4:begin
                if(sram_state==2)
                    next_state = LOAD_C5;
                else
                    next_state = LOAD_C4;
            end
            LOAD_C5:begin
                if(sram_state==2)
                    next_state = LOAD_C6;
                else
                    next_state = LOAD_C5;
            end
            LOAD_C6:begin
                if(sram_state==2)
                    next_state = LOAD_C7;
                else
                    next_state = LOAD_C6;
            end
            LOAD_C7:begin
                if(sram_state==2)
                    next_state = LOAD_C8;
                else
                    next_state = LOAD_C7;
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
                next_state = Read_i2;
            end
            Read_i2: begin
                if(sram_state==2)
                    next_state = Operate_D2;
                else
                    next_state = Read_i2;

            end
            Operate_D2: begin  
                next_state = Read_i3;             
            end
            Read_i3: begin
                if(sram_state==2)
                    next_state = Operate_D3;
                else
                    next_state = Read_i3;
            end
            Operate_D3: begin
                next_state = Read_i4;
            end
            Read_i4: begin
                if(sram_state==2)
                    next_state = Operate_D4;
                else
                    next_state = Read_i4;
            end
            Operate_D4: begin
                next_state = Read_i5;
            end
            Read_i5: begin
                if(sram_state==2)
                    next_state = Operate_D5;
                else
                    next_state = Read_i5;
            end
            Operate_D5: begin
                next_state = Read_i6;
            end
            Read_i6: begin
                if(sram_state==2)
                    next_state = Operate_D6;
                else
                    next_state = Read_i6;
            end
            Operate_D6: begin
                next_state = Read_i7;
            end
            Read_i7: begin
                if(sram_state==2)
                    next_state = Operate_D7;
                else
                    next_state = Read_i7;
            end
            Operate_D7: begin
                next_state = Read_i8;
            end
            Read_i8: begin
                if(sram_state==2)
                    next_state = Operate_D8;
                else
                    next_state = Read_i8;
            end
            Operate_D8: begin
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
                next_state = IDLE;
            end
            default: begin
                 next_state = IDLE; // safe recovery
    end
    endcase
    end

    logic [2:0] weight_count_r, weight_count_n;
    logic [2:0] in_count_r, in_count_n;
    always_ff @(posedge clk, negedge n_rst) begin
         if (!n_rst) begin
            weight_count_r <= 0;
            in_count_r <= 0;
        end else begin
            weight_count_r <= weight_count_n;
            in_count_r <= in_count_n;
        end
    end

    always_comb begin
        weight_count_n = weight_count_r;
        in_count_n     = in_count_r;

    // ----- weight counter -----
        if (sram_state==2 && (write_w_enable||read_w_enable)) begin
            if (weight_count_r == 7)
                weight_count_n = 0;
            else
                weight_count_n = weight_count_r + 1;
        end

    // ----- input counter -----
        if (sram_state==2 && (write_in_enable||read_in_enable)) begin
            if (in_count_r == 7)
                in_count_n = 0;
            else
                in_count_n = in_count_r + 1;
        end
    end



    always_comb begin
        // default outputs
        data_ready = 0;
        buffer_busy = 0;
        design_busy = 0;
        systolic_out = 64'b0;
        weights_loaded = 0;
        in = 64'b0;
        weight = 64'b0;
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
                in_num = in_count_r;
                design_busy = 0;
                buffer_busy = 0;
            end
            LOAD_weight: begin
                data = weights;
                buffer_busy = 1;
                design_busy = 1;
                write_w_enable = 1;
                weight_num = weight_count_r;
                in_num = in_count_r;
            end
            LOAD_input: begin
                data = inputs;
                buffer_busy = 1;
                design_busy = 1;
                write_in_enable = 1;
                in_num = in_count_r;
                weight_num = weight_count_r;
            
            end
            LOAD_C1, LOAD_C2, LOAD_C3, LOAD_C4,
            LOAD_C5, LOAD_C6, LOAD_C7, LOAD_C8: begin
                weight = sram_data;
                read_w_enable = 1;
                buffer_busy = 1;
                design_busy = 1;
                shift_enable = 1;
                weight_num = weight_count_r;
                in_num = in_count_r;
            end
            Weights_loaded: begin
                design_busy = 0;
                buffer_busy = 0;
                read_w_enable = 0;  
                weight_num = weight_count_r;
                in_num = in_count_r;
                weights_loaded = 1;
            end
            Read_i1, Read_i2, Read_i3, Read_i4,
            Read_i5, Read_i6, Read_i7, Read_i8: begin
                in = sram_data;
                read_in_enable = 1;
                buffer_busy = 1;
                design_busy = 1;
                in_num = in_count_r;
                weight_num = weight_count_r;
                
            end
            Operate_D1, Operate_D2, Operate_D3, Operate_D4,
            Operate_D5, Operate_D6, Operate_D7, Operate_D8: begin
                in = sram_data;
                operate_f = 1;
                design_busy = 1;
                weight_num = weight_count_r;
                in_num = in_count_r;
            end
            Send2Bias: begin
                out2bias =1;
                weight_num = weight_count_r;
                in_num = in_count_r;
                
            end
            Send2ACTV: begin
                weight_num = weight_count_r;
                in_num = in_count_r;
            end
            Store_out: begin
                store_output=1;
                weight_num = weight_count_r;
                in_num = in_count_r;
            end
            DONE: begin
                data_ready =1;
                systolic_out = sram_data;
                weight_num = weight_count_r;
                in_num = in_count_r;
            end
            default: begin
                weight_num = weight_count_r;
                in_num = in_count_r;
                design_busy = 0;
                buffer_busy = 0;
            end
        endcase
    end

endmodule

