`timescale 1ns / 10ps

module activation #(
) (
    input  logic        clk,
    input  logic        n_rst,
    input  logic [2:0]  activation_mode,
    input  logic        float_in,  // FP8 mode enable
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
            logic signed [7:0] lane_scaled, lane_result;
            
            // FP8 mode: divide by 4 to work in INT8 space
            if (float_in) begin
                lane_scaled = lane[i] >>> 2;
            end else begin
                lane_scaled = lane[i];
            end
            
            // Apply activation in INT8 space
            case (activation_mode)
                3'b000: lane_result = lane_scaled[7] ? 8'sd0 : lane_scaled;  // ReLU
                3'b001: lane_result = lane_scaled[7] ? 8'sd0 : 8'sd1;        // Binary step
                3'b010: lane_result = lane_scaled;                            // Linear
                3'b011: lane_result = lane_scaled[7] ? (lane_scaled >>> 1) : lane_scaled;  // Leaky ReLU
                default: lane_result = lane_scaled;
            endcase
            
            // FP8 mode: multiply by 4 to restore scale
            if (float_in) begin
                lane_next[i] = lane_result <<< 2;
            end else begin
                lane_next[i] = lane_result;
            end
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
