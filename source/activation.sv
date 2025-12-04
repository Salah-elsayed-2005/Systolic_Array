`timescale 1ns / 10ps

module activation #(
) (
    input  logic        clk,
    input  logic        n_rst,
    input  logic [2:0]  activation_mode,
    input  logic signed [63:0] in,
    output logic signed [63:0] out
);

    logic signed [63:0] out_next;

    always_comb begin
        case (activation_mode)
            3'b000: out_next = in[63] ? 64'sd0 : in;
            3'b001: out_next = in[63] ? 64'sd0 : 64'sd1;
            3'b010: out_next = in;
            3'b011: out_next = in[63] ? (in >>> 1) : in;
            default: out_next = in;
        endcase
    end

    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst)
            out <= 64'sd0;
        else
            out <= out_next;
    end

endmodule
