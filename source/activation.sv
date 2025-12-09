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
    logic signed [7:0] lane [0:7];
    logic signed [7:0] lane_next [0:7];

    // Slice input into 8 lanes of 8 bits each
    always_comb begin
        for (int i = 0; i < 8; i++) begin
            lane[i] = in[i*8 +: 8];
        end
    end

    // Apply activation function to each lane
    always_comb begin
        for (int i = 0; i < 8; i++) begin
            case (activation_mode)
                3'b000: lane_next[i] = lane[i][7] ? 8'sd0 : lane[i];
                3'b001: lane_next[i] = lane[i][7] ? 8'sd0 : 8'sd1;
                3'b010: lane_next[i] = lane[i];
                3'b011: lane_next[i] = lane[i][7] ? (lane[i] >>> 1) : lane[i];
                default: lane_next[i] = lane[i];
            endcase
        end
    end

    // Concatenate
    always_comb begin
        for (int i = 0; i < 8; i++) begin
            out_next[i*8 +: 8] = lane_next[i];
        end
    end

    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst)
            out <= 64'sd0;
        else
            out <= out_next;
    end

endmodule
