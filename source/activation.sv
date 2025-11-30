`timescale 1ns / 10ps

module activation #(
) (
    input  logic        clk,
    input  logic        n_rst,
    input  logic [2:0]  activation_mode,
    input  logic signed [63:0] in,
    output logic signed [63:0] out
);

always_comb begin
    case (activation_mode)
        3'b000: out = in[63] ? 64'sd0 : in; // relu
        3'b001: out = in[63] ? 64'sd0 : 64'sd1; // binary
        3'b010: out = in; // identity
        3'b011: out = in[63] ? (in >>> 1) : in; // leaky
        default: out = in;
    endcase
end

endmodule
