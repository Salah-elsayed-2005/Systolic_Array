`timescale 1ns / 10ps

module systolic_pe #(
    // parameters
) (
    input  logic       clk,
    input  logic       n_rst,          // active-low reset
    input  logic [7:0] in,             // input data (weight or activation)
    input  logic       shift_enable,   // used to drive load_w (see below)
    input  logic       operate_f,      // 1 = inference mode
    output logic [7:0] shifted,        // horizontal output
    output logic [7:0] out_acc         // vertical output (accumulated)
);

    // internal state
    logic [7:0] w_reg,    w_next;
    logic [7:0] shift_reg, shift_next;
    logic [7:0] acc_reg,  acc_next;

    // derive load_w from your controls (weight-load phase when !operate_f)
    logic load_w;
    assign load_w = shift_enable & ~operate_f;

    // ---------------- weight register ----------------
    always_ff @(posedge clk or negedge n_rst) begin : weight_reg
        if (!n_rst)
            w_reg <= 8'b0;      // async clear on active-low reset
        else
            w_reg <= w_next;
    end

    // ---------------- accumulator register ----------------
    always_ff @(posedge clk or negedge n_rst) begin : accumalator_reg
        if (!n_rst)
            acc_reg <= 8'b0;    // clear accumulator
        else
            acc_reg <= acc_next;
    end

    // ---------------- shift register ----------------
    always_ff @(posedge clk or negedge n_rst) begin : shift_reg
        if (!n_rst)
            shift_reg <= 8'b0;
        else
            shift_reg <= shift_next;
    end

    // ---------------- weight next-state logic ----------------
    always_comb begin : weight_block
        w_next = w_reg;         // hold by default
        if (load_w)
            w_next = in;        // load new weight during weight-load phase
    end

    // ---------------- horizontal data path logic ----------------
    always_comb begin : shift_block
        // default: hold previous value
        shift_next = shift_reg;

        if (load_w && !operate_f) begin
            // during weight-load: pass weights horizontally
            shift_next = w_next;
        end
        else if (operate_f) begin
            // during inference: pass inputs horizontally
            shift_next = in;
        end
    end

    assign shifted = shift_reg;

    // ---------------- multiplier ----------------
    logic [7:0] product;
    multiplier m (
        .A(w_reg),
        .B(in),
        .product(product)
    );

    // ---------------- accumulator next-state logic ----------------
    always_comb begin : accumalator_logic
        acc_next = acc_reg;          // hold by default
        if (operate_f)               // accumulate only in inference mode
            acc_next = acc_reg + product;
        
        if (acc_next > 34'sd127)
        acc_next = 34'sd127;
    else if (acc_next < -34'sd128)
        acc_next = -34'sd128;
    end

    assign out_acc = acc_reg;

endmodule
