`timescale 1ns / 10ps
module systolic_array #(     
) (
    input  logic              clk,
    input  logic              n_rst,       
    input  logic              shift_enable,
    input  logic              operate_f,
    // input data: 8 values per cycle, 8 bits each = 64 bits
    // in_bus[7:0]   -> row 0 PE(0,0).in
    // ...
    // in_bus[63:56] -> row 7 PE(7,0).in
    input  logic [63:0]    in_bus,
    input  logic           send2bias,
    output logic [63:0]    col_sums,    
    output logic [63:0]    sum_to_bias
);
    // 2D arrays for PE interconnects
    // pe_in     : input to each PE
    // pe_shift  : horizontal output (shifted) from each PE
    // pe_outacc : vertical output (out_acc) from each PE
    logic [7:0] pe_in     [0:7][0:7];
    logic [7:0] pe_shift  [0:7][0:7];
    logic [7:0] pe_outacc [0:7][0:7];
    genvar r, c;
    generate
        for (r = 0; r < 8; r++) begin : LEFT_INPUTS
            /
            assign pe_in[r][0] = in_bus[8*r +: 8];
        end
    endgenerate
    generate
        for (r = 0; r < 8; r++) begin : INTERNAL_INPUTS
            for (c = 1; c < 8; c++) begin : COLS
                assign pe_in[r][c] = pe_shift[r][c-1];
            end
        end
    endgenerate
    generate
        for (r = 0; r < 8; r++) begin : ROWS
            for (c = 0; c < 8; c++) begin : COLS
                systolic_pe pe_inst (
                    .clk         (clk),
                    .n_rst       (n_rst),
                    .in          (pe_in[r][c]),
                    .shift_enable(shift_enable),
                    .operate_f   (operate_f),
                    .shifted     (pe_shift[r][c]),
                    .out_acc     (pe_outacc[r][c])
                );
            end
        end
    endgenerate
    // ---------------- Column outputs (bottom row) ----------------
    // Take out_acc from the bottom row (row 8-1) as the 8 column sums.
    generate
        for (c = 0; c < 8; c++) begin : OUTPUT_PACK
            // pack bottom row out_acc into col_sums
            // col_sums[8*c +: 8] corresponds to column c
            assign col_sums[8*c +: 8] = pe_outacc[7][c];
        end
    endgenerate
    // ---------------- send2bias gating ----------------
    // When send2bias is asserted (after 15 cycles),
    // drive sum_to_bias with the current column sums; otherwise 0.
    always_comb begin
        if (send2bias)
            sum_to_bias = col_sums;
        else
            sum_to_bias = '0;
    end
endmodule