`timescale 1ns / 10ps

module multiplier (
    input  logic        clk,
    input  logic        n_rst,
    input  logic [7:0]  A,
    input  logic [7:0]  B,
    input  logic        float_in,  // FP8 mode enable
    output logic [7:0]  product
);

always_comb begin
    logic signed [15:0] A_extended, B_extended;
    logic signed [15:0] partial_products [7:0];
    logic signed [16:0] sum;
    
    // Sign-extend both inputs to 16 bits
    A_extended = $signed({A[7], A[7], A[7], A[7], A[7], A[7], A[7], A[7], A});
    B_extended = $signed({B[7], B[7], B[7], B[7], B[7], B[7], B[7], B[7], B});
    // A_extended = {8{A[7]}, A};
    // B_extended = {8{B[7]}, B};
    
    // Generate partial products - multiply B by each bit of A, then shift
    // For bits 0-6: normal multiplication
    for (int i = 0; i < 7; i++) begin
        if (A[i])
            partial_products[i] = B_extended <<< i;
        else
            partial_products[i] = 16'sd0;
    end
    
    // For bit 7 (sign bit): negate the partial product (subtract instead of add)
    if (A[7])
        partial_products[7] = -(B_extended <<< 7);
    else
        partial_products[7] = 16'sd0;
    
    // Sum all partial products
    sum = 17'sd0;
    for (int i = 0; i < 8; i++) begin
        sum = sum + $signed({partial_products[i][15], partial_products[i]});
    end
    
    // FP8 mode with scale=4: divide result by 4 to prevent overflow accumulation
    // When inputs are scaled by 4, their product is scaled by 16, so divide by 4
    // to keep intermediate results in reasonable range
    if (float_in) begin
        sum = sum >>> 2;  // Arithmetic right shift by 2 (divide by 4)
    end
    
    // Saturate 
    if (sum > 17'sd127)
        product = 8'h7F;
    else if (sum < -17'sd128)
        product = 8'h80;
    else
        product = sum[7:0];
end

endmodule
