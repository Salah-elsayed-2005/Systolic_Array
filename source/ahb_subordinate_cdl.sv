`timescale 1ns / 10ps

module ahb_subordinate_cdl #(
    // parameters
) (
    input clk, n_rst,
    input logic hsel,
    input logic [7:0] haddr,
    input logic [1:0] htrans,
    input logic [1:0] hsize,
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
    output logic [2:0] actv_mode,
    output logic store_weights,
    output logic [7:0] store_inputs
    
);
    localparam IDLE = 2'b00;
    localparam BUSY = 2'b01;
    localparam NONSEQ = 2'b10;
    localparam SEQ = 2'b11;

    logic hsel_reg;
    logic [7:0] haddr_reg;
    logic [1:0] htrans_reg;
    logic [1:0] hsize_reg;
    logic hwrite_reg;

    always_ff @(posedge clk, negedge n_rst) begin : REGISTERING_CONTROL_SIGNALS
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
        start_inference = control_reg[0];
        load_weights = control_reg[1];
        actv_mode = activation_reg[2:0];
    end

    logic hresp_next, hresp_next1;
    always_comb begin : HRESP_LOGIC
        hresp_next = 0;
        if (hsel_reg && (htrans_reg == NONSEQ || htrans_reg == SEQ)) begin
            if(~hwrite_reg) begin // read errors
                case (haddr_reg)
                    8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07,
                    8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D, 8'h0E, 8'h0F: hresp_next = 1;
                endcase
            end
            else begin  // write errors
                case (haddr_reg)
                    8'h18, 8'h19, 8'h1A, 8'h1B, 8'h1C, 8'h1D, 8'h1E, 8'h1F,
                    8'h20, 8'h21, 8'h23                                   : hresp_next = 1;
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
        if (hsel_reg && (htrans_reg == NONSEQ || htrans_reg == SEQ)) begin
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

    function automatic void base_addr_f(
    input  logic [7:0] addr,
    output logic [7:0] base
    );
        base = 8'h00;
        if      (addr <= 8'h07) begin  base = 8'h00; end
        else if (addr <= 8'h0F) begin  base = 8'h08; end
        else if (addr <= 8'h17) begin  base = 8'h10; end
        else if (addr <= 8'h1F) begin  base = 8'h18; end
        else if (addr <= 8'h21) begin  base = 8'h20; end
        else if (addr == 8'h22) begin  base = 8'h22; end
        else if (addr == 8'h23) begin  base = 8'h23; end
        else if (addr == 8'h24) begin  base = 8'h24; end
    endfunction

    logic [7:0] low, high;
    logic [7:0] byte_offset;
    logic [7:0] num_bytes;
    logic [7:0] base_addr;

   always_comb begin : WRITE_LOGIC
        weight_next = weight_reg;
        input_next = input_reg;
        bias_next = bias_reg;
        control_next = control_reg;
        activation_next = activation_reg;

        store_weights = 0;
        store_inputs = 8'h00;
        w_hready = 1;

        if(hsel_reg) begin
            if (htrans_reg == NONSEQ) begin // NON-SEQ
                if (hwrite_reg) begin
                    base_addr_f(haddr_reg, base_addr);
                    byte_offset = haddr_reg - base_addr;
                    low = {byte_offset, 3'b000};
                    num_bytes = 8'b1 << hsize_reg; // 1,2,4,8
                    case(base_addr)
                        8'h00: begin
                            case (hsize_reg)
                                2'd0: weight_next[low +: 8]   = hwdata[low +: 8];
                                2'd1: weight_next[low +: 16]  = hwdata[low +: 16];
                                2'd2: weight_next[low +: 32]  = hwdata[low +: 32];
                                2'd3: weight_next[0   +: 64]  = hwdata[0   +: 64];
                            endcase
                            if(buffer_busy) w_hready = 0;
                            store_weights = 1;
                        end
                               
                        8'h08: begin
                            case (hsize_reg)
                                2'd0: begin input_next[low +: 8]   = hwdata[low +: 8];   store_inputs[byte_offset] = 1'b1; end
                                2'd1: begin input_next[low +: 16]  = hwdata[low +: 16];  store_inputs[byte_offset +: 2] = 2'b11; end
                                2'd2: begin input_next[low +: 32]  = hwdata[low +: 32];  store_inputs[byte_offset +: 4] = 4'b1111; end
                                2'd3: begin input_next[0   +: 64]  = hwdata[0   +: 64];  store_inputs = 8'hFF; end
                            endcase
                            if(buffer_busy) w_hready = 0;
                        end   
                        8'h10: begin
                            case (hsize_reg)
                                2'd0: bias_next[low +: 8]   = hwdata[low +: 8];
                                2'd1: bias_next[low +: 16]  = hwdata[low +: 16];
                                2'd2: bias_next[low +: 32]  = hwdata[low +: 32];
                                2'd3: bias_next[0   +: 64]  = hwdata[0   +: 64];
                            endcase
                        end
                        8'h22: if (hsize_reg == 2'd0 && byte_offset == 0) begin
                                   control_next = hwdata[23:16];
                               end
                        8'h24: if (hsize_reg == 2'd0 && byte_offset == 0) begin
                                   activation_next = hwdata[39:32];
                               end
                    endcase
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
    logic [7:0] write_end, read_end;
    logic [7:0] base_addr_r, byte_offset_r, num_bytes_r, low_r;

    always_comb begin : READ_LOGIC
        hrdata_next = 64'h0;
        r_hready = 1;
        write_end = haddr_reg + (8'b1 << hsize_reg) - 1;
        read_end  = haddr     + (8'b1 << hsize)     - 1;
        is_raw = hwrite_reg && ~hwrite && !((read_end < haddr_reg) || (haddr > write_end)) && hready;

        if (hsel && !hresp) begin
            if (htrans == NONSEQ) begin
                if(!hwrite) begin  // READ
                    base_addr_f(haddr, base_addr_r);
                    byte_offset_r = haddr - base_addr_r;
                    low_r = {byte_offset_r, 3'b000};
                    num_bytes_r = 8'b1 << hsize; // 1,2,4,8
                    
                    case (base_addr_r)
                        // Bias (RW)
                        8'h10: begin
                            case (hsize)
                                2'd0: hrdata_next[low_r +: 8]   = is_raw ? bias_next[low_r +: 8] : bias_reg[low_r +: 8];
                                2'd1: hrdata_next[low_r +: 16]  = is_raw ? bias_next[low_r +: 16] : bias_reg[low_r +: 16];
                                2'd2: hrdata_next[low_r +: 32]  = is_raw ? bias_next[low_r +: 32] : bias_reg[low_r +: 32];
                                2'd3: hrdata_next[0     +: 64]  = is_raw ? bias_next[0     +: 64] : bias_reg[0     +: 64]; // offset must be 0
                            endcase
                        end

                        // Output (RO)
                        8'h18: begin
                            case (hsize)
                                2'd0: hrdata_next[low_r +: 8]   = output_reg[low_r +: 8];
                                2'd1: hrdata_next[low_r +: 16]  = output_reg[low_r +: 16];
                                2'd2: hrdata_next[low_r +: 32]  = output_reg[low_r +: 32];
                                2'd3: hrdata_next[0     +: 64]  = output_reg[0     +: 64];
                            endcase
                            if (buffer_busy) r_hready = 0;
                        end

                        // Error (16-bit RO at 0x20-0x21)
                        8'h20: begin
                            case (hsize)
                                2'd1: if (byte_offset_r == 0) hrdata_next[15:0] = error_reg;
                                2'd0: hrdata_next[low_r +: 8] = (byte_offset_r == 0) ? error_reg[7:0] : error_reg[15:8];
                                default: ; // other sizes ignored
                            endcase
                        end

                        8'h22: begin
                            if (hsize == 2'd0 && byte_offset_r == 0)
                                hrdata_next[23:16] = is_raw ? control_next : control_reg;
                        end

                        8'h23: begin
                            if (hsize == 2'd0 && byte_offset_r == 0)
                                hrdata_next[31:24] = status_reg;
                        end

                        8'h24: begin
                            if (hsize == 2'd0 && byte_offset_r == 0)
                                hrdata_next[39:32] = is_raw ? activation_next : activation_reg;
                        end

                        default: begin
                        end
                    endcase
                end
            end
        end
    end

endmodule