`timescale 1ns / 10ps

module cdl_ahb_subordinate #(
    // parameters
) (
    input clk, n_rst,
    input logic hsel,
    input logic [7:0] haddr,
    input logic [1:0] htrans,
    input logic [2:0] hsize,
    input logic hwrite,
    input logic [63:0] hwdata,
    input logic hburst,
    output logic [63:0] hrdata,
    output logic hresp,
    output logic hready,

    input logic data_ready,
    input logic buffer_busy,
    input logic design_busy,
    input logic [63:0] systolic_out,
    output logic start_inference,
    output logic load_weights,
    output logic [63:0] weights,
    output logic [63:0] inputs,
    output logic [63:0] bias,
    output logic [2:0] actv_mode
    
);
    localparam IDLE = 0;
    localparam BUSY = 1;
    localparam NONSEQ = 2;
    localparam SEQ = 3;

    logic hsel_reg;
    logic [7:0] haddr_reg;
    logic [1:0] htrans_reg;
    logic [2:0] hsize_reg;
    logic hwrite_reg;

    always_ff @(posedge clk, negedge n_rst) begin : REGISTERING_WRITE_LOGIC
        if(!n_rst) begin
            hsel_reg <= '0;
            haddr_reg <= '0;
            htrans_reg <= '0;
            hsize_reg <= '0;
            hwrite_reg <= '0;
        end
        else begin
            hsel_reg <= hsel;
            haddr_reg <= haddr;
            htrans_reg <= htrans;
            hsize_reg <= hsize;
            hwrite_reg <= hwrite;
        end
    end

    logic [63:0] weight_next, weight_reg;
    logic [63:0] input_next, input_reg;
    logic [63:0] bias_next, bias_reg;
    logic [63:0] output_next, output_reg;
    logic [15:0] error_next, error_reg;
    logic [7:0] control_next, control_reg;
    logic [7:0] status_next, status_reg;
    logic [7:0] activation_next, activation_reg;

    logic w_hready, r_hready;

    always_ff @(posedge clk, negedge n_rst) begin : REGISTER_BANK
        if(!n_rst) begin
            weight_reg <= '0; 
            input_reg <= '0; 
            bias_reg <= '0;
            output_reg <= '0;
            error_reg <= '0;
            control_reg <= '0;
            status_reg <= '0;
            activation_reg <= '0;
        end
        else begin
            weight_reg <= weight_next;
            input_reg <= input_next;
            bias_reg <= bias_next;
            output_reg <= output_next;
            error_reg <= error_next;
            control_reg <= control_next;
            status_reg <= status_next;
            activation_reg <= activation_next;
        end
    end

    always_comb begin : REGISTER_BANK_ASSIGNMENTS
        output_next = systolic_out;
        weights = weight_reg;
        inputs = input_reg;
        bias = bias_reg;
        start_inference = status_reg[0];
        load_weights = status_reg[1];
        actv_mode = activation_reg[1:0];
    end

    logic hresp_next, hresp_next1;
    always_comb begin : HRESP_LOGIC
        hresp_next = 0;
        if (hsel_reg) begin
            if(~hwrite_reg) begin
                case (haddr_reg)
                    8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07,
                    8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D, 8'h0E, 8'h0F: hresp_next = 1;
                    default: hresp_next = 0;
                endcase
            end
            else begin
                case (haddr_reg)
                    8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07,
                    8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D, 8'h0E, 8'h0F: hresp_next = 0;
                    default: hresp_next = 1;
                endcase
            end
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin : HRESP_REG
        if(!n_rst) begin
            hresp_next1 <= 0;
        end
        else begin
            hresp_next1 <= hresp_next;
        end
    end

    assign hresp = hresp_next | hresp_next1;

    always_comb begin : HREADY_LOGIC
        hready = 1;
        if (hsel) begin
            if (hresp_next || !w_hready || !r_hready) begin
                hready = 0;
            end
        end
    end

    always_comb begin : ERROR_LOGIC
        error_next = 16'h0000;
        if (buffer_busy)
            error_next[0] = 1'b1;
        
        if (design_busy || buffer_busy)
            error_next[8] = 1'b1;
        
    end

    always_comb begin : STATUS_LOGIC
        status_next = 0;
        if (data_ready)
            status_next[0] = 1'b1;
        
        if (design_busy)
            status_next[1] = 1'b1;
    end


    logic store_weights;
    logic [7:0] store_inputs;

    always_comb begin : WRITE_LOGIC
        weight_next = weight_reg;
        input_next = input_reg;
        bias_next = bias_reg;
        control_next = control_reg;
        activation_next = activation_reg;

        store_weights = 0;
        store_inputs = 0;
        w_hready = 1;

        if(hsel_reg) begin
            if (htrans_reg == NONSEQ) begin // NON-SEQ
                if (hwrite_reg) begin
                    if (hsize_reg == 3) begin // 8-byte
                        case(haddr_reg)
                            8'h00: begin weight_next = hwdata;
                                         w_hready = 0;
                                         store_weights = 1;
                            end
                            8'h08: begin input_next = hwdata;
                                         w_hready = 0;
                                         store_inputs = 8'hFF;
                            end
                            8'h10: bias_next = hwdata;
                        endcase
                    end
                    else if (hsize_reg == 2) begin // 4-byte
                        case(haddr_reg)
                            8'h00: begin weight_next[31:0] = hwdata[31:0];
                                         w_hready = 0;
                                         store_weights = 1;
                            end
                            8'h04: begin weight_next[63:32] = hwdata[63:32];
                                         w_hready = 0;
                                         store_weights = 1;
                            end
                            8'h08: begin input_next[31:0] = hwdata[31:0];
                                         w_hready = 0;
                                         store_inputs = 8'hFF;
                            end
                            8'h0C: begin input_next[63:32] = hwdata[63:32];
                                         w_hready = 0;
                                         store_inputs = 8'hFF;
                            end
                            8'h10: bias_next[31:0] = hwdata[31:0];
                            8'h14: bias_next[63:32] = hwdata[63:32];
                        endcase
                    end
                    else if (hsize_reg == 1) begin  // 2-byte
                        case(haddr_reg)
                        //////////// NEED TO COME UP WITH DIFFERENT LOGIC
                            8'h00: begin weight_next[15:0] = hwdata[15:0];
                                         store_weights = 1;
                            end
                            8'h02: begin weight_next[31:16] = hwdata[31:16];
                                         store_weights = 1;
                            end
                            8'h04: begin weight_next[47:32] = hwdata[47:32];
                                         store_weights = 1;
                            end
                            8'h06: begin weight_next[63:48] = hwdata[63:48];
                                         store_weights = 1;
                            end
                        endcase
                    end
                    else if (hsize_reg == 0) begin // 1-byte
                        case(haddr_reg)
                            8'h00: weight_next[7:0] = hwdata[7:0];
                            8'h01: weight_next[15:8] = hwdata[15:8];
                            8'h02: weight_next[23:16] = hwdata[23:16];
                            8'h03: weight_next[31:24] = hwdata[31:24];
                            8'h04: weight_next[39:32] = hwdata[39:32];
                            8'h05: weight_next[47:40] = hwdata[47:40];
                            8'h06: weight_next[55:48] = hwdata[55:48];
                            8'h07: weight_next[63:56] = hwdata[63:56];

                            8'h08: input_next[7:0] = hwdata[7:0];
                            8'h09: input_next[15:8] = hwdata[15:8];
                            8'h0A: input_next[23:16] = hwdata[23:16];
                            8'h0B: input_next[31:24] = hwdata[31:24];
                            8'h0C: input_next[39:32] = hwdata[39:32];
                            8'h0D: input_next[47:40] = hwdata[47:40];
                            8'h0E: input_next[55:48] = hwdata[55:48];
                            8'h0F: input_next[63:56] = hwdata[63:56];

                            8'h10: bias_next[7:0] = hwdata[7:0];
                            8'h11: bias_next[15:8] = hwdata[15:8];
                            8'h12: bias_next[23:16] = hwdata[23:16];
                            8'h13: bias_next[31:24] = hwdata[31:24];
                            8'h14: bias_next[39:32] = hwdata[39:32];
                            8'h15: bias_next[47:40] = hwdata[47:40];
                            8'h16: bias_next[55:48] = hwdata[55:48];
                            8'h17: bias_next[63:56] = hwdata[63:56];

                            8'h22: control_next = hwdata[7:0];
                            8'h24: activation_next = hwdata[7:0];
                        endcase

                    end
                end
            end
        end
    end

    logic [63:0] hrdata_next;
    always_ff @(posedge clk, negedge n_rst) begin : HRDATA_REGISTERING
        if(!n_rst) begin
            hrdata <= '0;
        end
        else begin
            hrdata <= hrdata_next;
        end
    end

    logic is_raw;
    logic _8byte_raw;
    logic _2byte_raw;
    logic _1byte_raw;
    always_comb begin : READ_LOGIC
        hrdata_next = 64'h0000000000000000;
        _8byte_raw = (hsize == 3 && ((haddr == haddr_reg) || ((haddr_reg + 7) - haddr) >= 0));
        _2byte_raw = (hsize == 1) && (((haddr == haddr_reg) || ((haddr_reg + 1) - haddr) >= 0));
        _1byte_raw = (hsize == 0) && (haddr == haddr_reg);
        is_raw = (hwrite_reg) && (~hwrite) && ((_8byte_raw) || (_2byte_raw) || (_1byte_raw));
        r_hready = 1;
        
        if (hsel) begin
            if (htrans == NONSEQ) begin
                if(!hwrite) begin  // READ
                    if (hsize == 3) begin // 8-byte
                        case (haddr)
                            8'h10: hrdata_next = is_raw ? bias_next : bias_reg;
                            8'h18: begin
                                hrdata_next = output_reg;
                                if(buffer_busy) r_hready = 0;
                            end
                        endcase
                    end
                    else if (hsize == 2) begin // 4-byte
                        case(haddr)
                            8'h10: hrdata_next[31:0] = is_raw ? bias_next[31:0] : bias_reg[31:0];
                            8'h14: hrdata_next[63:32] = is_raw ? bias_next[63:32] : bias_reg[63:32];
                            8'h18: begin hrdata_next[31:0] = output_reg[31:0];   if(buffer_busy)  r_hready = 0; end
                            8'h1C: begin hrdata_next[63:32] = output_reg[63:32];  if(buffer_busy)  r_hready = 0; end
                        endcase
                    end
                    else if (hsize == 1) begin // 2-byte
                    //////////// NEED TO COME UP WITH DIFFERENT LOGIC
                        case(haddr)
                            8'h10: hrdata_next[15:0]  = is_raw ? bias_next[15:0] : bias_reg[15:0];
                            8'h12: hrdata_next[31:16] = is_raw ? bias_next[31:16] : bias_reg[31:16];
                            8'h14: hrdata_next[47:32] = is_raw ? bias_next[47:32] : bias_reg[47:32];
                            8'h16: hrdata_next[63:48] = is_raw ? bias_next[63:48] : bias_reg[63:48];

                            8'h18: hrdata_next[15:0]  = output_reg[15:0];
                            8'h1A: hrdata_next[31:16] = output_reg[31:16];
                            8'h1C: hrdata_next[47:32] = output_reg[47:32];
                            8'h1E: hrdata_next[63:48] = output_reg[63:48];

                            8'h20: hrdata_next[15:0] = error_reg;


                        endcase
                    end
                    else if(hsize == 0) begin // 1-byte
                        case (haddr)
                            8'h10: hrdata_next[7:0]   = is_raw ? bias_next[7:0]   : bias_reg[7:0];
                            8'h11: hrdata_next[15:8]  = is_raw ? bias_next[15:8]  : bias_reg[15:8];
                            8'h12: hrdata_next[23:16] = is_raw ? bias_next[23:16] : bias_reg[23:16];
                            8'h13: hrdata_next[31:24] = is_raw ? bias_next[31:24] : bias_reg[31:24];
                            8'h14: hrdata_next[39:32] = is_raw ? bias_next[39:32] : bias_reg[39:32];
                            8'h15: hrdata_next[47:40] = is_raw ? bias_next[47:40] : bias_reg[47:40];
                            8'h16: hrdata_next[55:48] = is_raw ? bias_next[55:48] : bias_reg[55:48];
                            8'h17: hrdata_next[63:56] = is_raw ? bias_next[63:56] : bias_reg[63:56];
                        
                            8'h18: hrdata_next[7:0]   = output_reg[7:0];
                            8'h19: hrdata_next[15:8]  = output_reg[15:8];
                            8'h1A: hrdata_next[23:16] = output_reg[23:16];
                            8'h1B: hrdata_next[31:24] = output_reg[31:24];
                            8'h1C: hrdata_next[39:32] = output_reg[39:32];
                            8'h1D: hrdata_next[47:40] = output_reg[47:40];
                            8'h1E: hrdata_next[55:48] = output_reg[55:48];
                            8'h1F: hrdata_next[63:56] = output_reg[63:56];

                            8'h20: hrdata_next[7:0] = error_reg[7:0];
                            8'h21: hrdata_next[15:8] = error_reg[15:8];

                            8'h22: hrdata_next[7:0] = is_raw ? control_next[7:0] : control_reg[7:0];
                            8'h23: hrdata_next[7:0] = status_reg[7:0];
                            8'h24: hrdata_next[7:0] = is_raw ? activation_next[7:0] : activation_reg[7:0];
                        endcase
                    end
                end
            end
        end
    end


endmodule

