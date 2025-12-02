`timescale 1ns / 10ps

module bias_adder #(
) (
    input  logic        clk,
    input  logic        n_rst,
    input  logic [63:0] out_acc,
    input  logic [63:0] bias,
    output logic [63:0] out_b
);

    logic signed [7:0] acc_lane  [0:7];
    logic signed [7:0] bias_lane [0:7];
    logic signed [8:0] sum_lane  [0:7];
    logic signed [7:0] sat_lane  [0:7];

    integer i;

    always_comb begin
        for (i = 0; i < 8; i++) begin
            acc_lane[i]  = out_acc[8*i +: 8];
            bias_lane[i] = bias   [8*i +: 8];
            sum_lane[i]  = acc_lane[i] + bias_lane[i];

            if (sum_lane[i] > 9'sd127)
                sat_lane[i] = 8'sd127;
            else if (sum_lane[i] < -9'sd128)
                sat_lane[i] = -8'sd128;
            else
                sat_lane[i] = sum_lane[i][7:0];
        end
    end

    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst)
            out_b <= 64'b0;
        else
            for (i = 0; i < 8; i++)
                out_b[8*i +: 8] <= sat_lane[i];
    end

endmodule
