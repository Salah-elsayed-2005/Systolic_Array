`timescale 1ns / 10ps

module ahb_subordinate #(
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
    output logic start_inference,
    output logic load_weights,
    output logic [63:0] weights,
    output logic [63:0] inputs,
    output logic [63:0] bias,
    output logic [2:0] actv_mode,
    outptu logic [63:0] systolic_out
);

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
        actv_mode = activation_reg[1:0];
    end

    logic hresp_next, hresp_next1;
    always_comb begin : HRESP_LOGIC
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
        hready = 0;
        if (hsel) begin
            if (((htrans != 0 || htrans_reg != 0) && !hresp) || ((htrans == 0) && hresp)) begin
                hready = 1;
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

        if(hsel_reg) begin
            if (htrans_reg == 2) begin // NON-SEQ
                if (hwrite_reg) begin
                    if (hsize_reg == 3) begin // 8-byte
                        case(haddr_reg)
                            8'h00: begin weight_next = hwdata;
                                         store_weights = 1;
                            end
                            8'h08: begin input_next = hwdata;
                                         store_inputs = 8'hFF;
                            end
                            8'h10: bias_next = hwdata;
                        endcase
                    end
                    else if (hsize_reg == 2) begin // 4-byte
                        case(haddr_reg)
                            8'h00: begin weight_next[31:0] = hwdata[31:0];
                                         store_weights = 1;
                            end
                            8'h04: begin weight_next[63:32] = hwdata[63:32];
                                         store_weights = 1;
                            end
                            8'h08: begin input_next[31:0] = hwdata[31:0];
                                         store_inputs = 8'hFF;
                            end
                            8'h0C: begin input_next[63:32] = hwdata[63:32];
                                         store_inputs = 8'hFF;
                            end
                            8'h10: bias_next[31:0] = hwdata[31:0];
                            8'h14: bias_next[63:32] = hwdata[63:32];
                        endcase
                    end
                    else if (hsize_reg == 1) begin  // 2-byte
                        case(haddr_reg)
                            8'h00, 8'h02: begin weight_next[15:0] = hwdata[15:0];
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
            end
        end
    end
endmodule

