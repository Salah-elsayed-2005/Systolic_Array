`timescale 1ns / 10ps
module systolic_array #(     
) (
    input  logic              clk,
    input  logic              n_rst,       
    input  logic              shift_enable,
    input  logic              operate_f,
    // input data: 8 values per cycle, 8 bits each = 64 bits
    // During operate_f (STAGGERED INPUT):
    //   Cycle 0: in_bus[7:0]   = x1, rest = 0 (row 0 gets x1)
    //   Cycle 1: in_bus[15:8]  = x2, rest = 0 (row 1 gets x2)
    //   ...
    //   Cycle 7: in_bus[63:56] = x8, rest = 0 (row 7 gets x8)
    //   Cycle 8+: in_bus = 0 (drain/propagate through columns)
    input  logic [63:0]    in_bus,
    input  logic           send2bias,
    output logic [63:0]    col_sums,    
    output logic [63:0]    sum_to_bias
);
    // 2D arrays for PE interconnects
    // pe_in      : horizontal input to each PE
    // pe_shift   : horizontal output (shifted) from each PE
    // pe_acc_in  : vertical input (acc_above) to each PE
    // pe_outacc  : vertical output (out_acc) from each PE
    logic [7:0] pe_in      [0:7][0:7];
    logic [7:0] pe_shift   [0:7][0:7];
    logic [7:0] pe_acc_in  [0:7][0:7];
    logic [7:0] pe_outacc  [0:7][0:7];
    
    genvar r, c;
    
    // ---------------- Horizontal connections (left inputs from in_bus or shifted) ----------------
    // During operate_f: each row gets its corresponding slice from in_bus
    // During weight load: all rows get the same weight column from in_bus (column by column loading)
    generate
        for (r = 0; r < 8; r++) begin : LEFT_INPUTS
            // Leftmost PE in each row: gets from in_bus
            // During operate_f: row r gets in_bus[8*r +: 8]
            // During weight load: row r gets in_bus[8*r +: 8] for column-by-column weight loading
            assign pe_in[r][0] = in_bus[8*r +: 8];
        end
    endgenerate
    
    generate
        for (r = 0; r < 8; r++) begin : HORIZONTAL_SHIFT
            for (c = 1; c < 8; c++) begin : COLS
                // Each PE gets shifted data from the PE to its left
                assign pe_in[r][c] = pe_shift[r][c-1];
            end
        end
    endgenerate
    
    // ---------------- Vertical connections (acc_above) ----------------
    generate
        // Top row: acc_above = 0
        for (c = 0; c < 8; c++) begin : TOP_ROW_ACC
            assign pe_acc_in[0][c] = 8'b0;
        end
        
        // Other rows: acc_above comes from the PE directly above
        for (r = 1; r < 8; r++) begin : VERTICAL_ACC
            for (c = 0; c < 8; c++) begin : COLS
                assign pe_acc_in[r][c] = pe_outacc[r-1][c];
            end
        end
    endgenerate
    
    // ---------------- PE instantiations ----------------
    generate
        for (r = 0; r < 8; r++) begin : ROWS
            for (c = 0; c < 8; c++) begin : COLS
                systolic_pe pe_inst (
                    .clk         (clk),
                    .n_rst       (n_rst),
                    .in          (pe_in[r][c]),
                    .acc_above   (pe_acc_in[r][c]),
                    .shift_enable(shift_enable),
                    .operate_f   (operate_f),
                    .shifted     (pe_shift[r][c]),
                    .out_acc     (pe_outacc[r][c])
                );
            end
        end
    endgenerate
    
    // ---------------- Column outputs (bottom row only) ----------------
    // Register the column sums from the bottom row (row 7)
    // Each column completes at a different time due to staggered inputs:
    // Column 0 completes 8 cycles after operate_f starts, column 1 at 9 cycles, etc.
    
    // Track which cycle of operate_f we're in
    logic [3:0] operate_cycle_count;
    
    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst)
            operate_cycle_count <= 4'd0;
        else if (!operate_f)
            operate_cycle_count <= 4'd0;
        else if (operate_f) begin  // Count during inference regardless of shift_enable
            if (operate_cycle_count < 4'd15)
                operate_cycle_count <= operate_cycle_count + 4'd1;
        end
    end
    
    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            col_sums <= '0;
        end else if (!operate_f) begin
            col_sums <= '0;  // Clear during weight load
        end else if (operate_f) begin  // Capture during inference regardless of shift_enable
            // Capture each column when complete and never overwrite it
            // Column c completes at cycle (8 + c)
            case (operate_cycle_count)
                4'd8:  col_sums[7:0]   <= pe_outacc[7][0];
                4'd9:  col_sums[15:8]  <= pe_outacc[7][1];
                4'd10: col_sums[23:16] <= pe_outacc[7][2];
                4'd11: col_sums[31:24] <= pe_outacc[7][3];
                4'd12: col_sums[39:32] <= pe_outacc[7][4];
                4'd13: col_sums[47:40] <= pe_outacc[7][5];
                4'd14: col_sums[55:48] <= pe_outacc[7][6];
                4'd15: col_sums[63:56] <= pe_outacc[7][7];
                default: col_sums <= col_sums; // Hold all values
            endcase
        end
    end
    
    // ---------------- send2bias gating ----------------
    // When send2bias is asserted (after 15th cycle when last operation completes),
    // drive sum_to_bias with the current column sums; otherwise 0.
    always_comb begin
        if (send2bias)
            sum_to_bias = col_sums;
        else
            sum_to_bias = '0;
    end
    
endmodule 