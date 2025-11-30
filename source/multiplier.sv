`timescale 1ns / 10ps

module multiplier (
    input  logic        clk,
    input  logic        n_rst,
    input  logic [7:0]  A,
    input  logic [7:0]  B,
    output logic [7:0]  product
);

logic signed [15:0] PaddedA;
logic signed [15:0] PaddedB;
logic signed [31:0] PartialS [15:0];
logic signed [33:0] sumPartial;

assign PaddedA = {{8{A[7]}}, A};
assign PaddedB = {{8{B[7]}}, B};

genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin
        assign PartialS[i] = PaddedA[i] ? (PaddedB <<< i) : 32'sd0;
    end
endgenerate

always_comb begin
    sumPartial = 34'sd0;
    for (int j = 0; j < 16; j = j + 1)
        sumPartial = sumPartial + PartialS[j];

    if (sumPartial > 34'sd127)
        sumPartial = 34'sd127;
    else if (sumPartial < -34'sd128)
        sumPartial = -34'sd128;

    product = sumPartial[7:0];
end

endmodule
