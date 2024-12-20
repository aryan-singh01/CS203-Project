module Adder8Bit (
    input [7:0] a,
    input [7:0] b,
    input cin,           // Carry-in
    output [7:0] sum,
    output cout          // Carry-out
);
    wire [7:0] carry;
    // Full adders for each bit
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: FULL_ADDER
            wire axorb, aandb, canda;
            if (i == 0) begin
                // First bit (use cin as carry-in)
               xor (axorb, a[i], b[i]);       // axorb = a[i] ^ b[i];
                and (aandb, a[i], b[i]);       // aandb = a[i] & b[i];
                and (canda, axorb, cin);       // canda = axorb & cin;
                xor (sum[i], axorb, cin);      // sum[i] = axorb ^ cin;
                or  (carry[i], aandb, canda);  // carry[i] = aandb | canda;
                            end else begin
                // Remaining bits
               // Gate-level modeling for the given expressions
                xor (axorb, a[i], b[i]);              // axorb = a[i] ^ b[i];
                and (aandb, a[i], b[i]);              // aandb = a[i] & b[i];
                and (canda, axorb, carry[i-1]);       // canda = axorb & carry[i-1];
                xor (sum[i], axorb, carry[i-1]);      // sum[i] = axorb ^ carry[i-1];
                or  (carry[i], aandb, canda);         // carry[i] = aandb | canda;
            end
        end
    endgenerate

    //assign {cout, sum} = a + b + cin;
endmodule

module Subtractor8Bit (
    input [7:0] a,
    input [7:0] b,
    input bin,           // Borrow-in
    output [7:0] diff,
    output bout          // Borrow-out
);
    
     wire [7:0] b_neg;
    wire [7:0] sum;
    wire cout;

    // Negate b (two's complement)
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: NEGATE_B
            not (b_neg[i], b[i]);  // b_neg[i] = ~b[i];

        end
    endgenerate

    // Add a, ~b, and bin
    Adder8Bit subtractor (
        .a(a),
        .b(b_neg),
        .cin(bin),
        .sum(diff),
        .cout(bout)
    );
    
   
endmodule

module ExponentCalculation (
    input [7:0] exp_a,
    input [7:0] exp_b,
    output [7:0] result_exp,
    output overflow,
    output underflow
);
    wire [7:0] exp_sum;
    wire cout, bout;

    // Instantiate Adder8Bit for exponent addition
    Adder8Bit adder (
        .a(exp_a),
        .b(exp_b),
        .cin(1'b0),
        .sum(exp_sum),
        .cout(cout)
    );

    // Subtract the bias (127) using Subtractor8Bit
    wire [7:0] bias = 8'd127;
    wire [7:0] adjusted_exp;
    Subtractor8Bit subtractor (
        .a(exp_sum),
        .b(bias),
        .bin(1'b0),
        .diff(adjusted_exp),
        .bout(bout)
    );

    // Handle overflow and underflow cases
    assign overflow = (adjusted_exp > 8'd254);
    assign underflow = (adjusted_exp == 8'd0);
    assign result_exp = (overflow) ? 8'd255 :
                        (underflow) ? 8'd0 : adjusted_exp;
endmodule


// WallaceTreeMultiplier Module
module WallaceTreeMultiplier (
    input [23:0] a,  // Input operand A (24 bits)
    input [23:0] b,  // Input operand B (24 bits)
    output [47:0] product // Final product (48 bits)
);

    // Partial Product Generation
    wire [47:0] pp [23:0]; // Partial products (extended to 48 bits)
    genvar i, j;
    generate
        for (i = 0; i < 24; i = i + 1) begin: PP_GEN
            for (j = 0; j < 24; j = j + 1) begin: PP_BITS
                and(pp[i][j + i], a[i], b[j]); // Align based on i
            end
            assign pp[i][47:i + 24] = 24'b0; // Extend to 48 bits with zeros
        end
    endgenerate

    // Wallace Tree Reduction
    wire [47:0] sum [15:0];  // Sum for each stage
    wire [47:0] carry [15:0]; // Carry for each stage

    generate
        // First stage: reduce partial products
        for (i = 0; i < 24; i = i + 1) begin: REDUCE_STAGE0
            assign sum[0][i] = pp[i][i];
            and(carry[0][i], pp[i][i], pp[i][i + 1]);
        end

        // Further stages (example for general reduction)
        for (i = 1; i < 15; i = i + 1) begin: REDUCE_STAGE
            assign sum[i] = sum[i - 1] ^ carry[i - 1]; // XOR for sum
            assign carry[i] = sum[i - 1] & carry[i - 1]; // AND for carry
        end
    endgenerate

    // Final Stage Addition
    assign product = sum[14] + carry[14];

endmodule


module Normalize (
    input [47:0] mantissa,
    input [7:0] exponent,
    output reg [23:0] normalized_mantissa,
    output reg [8:0] normalized_exponent
);
    wire [7:0] incremented_exp, decremented_exp;
    wire cout_inc, cout_dec;

    // Increment exponent
    Adder8Bit increment (
        .a(exponent),
        .b(8'b1),
        .cin(1'b0),
        .sum(incremented_exp),
        .cout(cout_inc)
    );

    // Decrement exponent
    Subtractor8Bit decrement (
        .a(exponent),
        .b(8'b1),
        .bin(1'b0),
        .diff(decremented_exp),
        .bout(cout_dec)
    );

    always @(*) begin
        if (mantissa[47]) begin
            normalized_mantissa = mantissa[46:23];
            normalized_exponent = incremented_exp;
        end else begin
            normalized_mantissa = mantissa[45:22];
            normalized_exponent = decremented_exp;
        end
    end
endmodule


// Rounding Module
module Rounding (
    input [23:0] mantissa,   // Input mantissa (23 bits)
    input [8:0] exponent,    // Input exponent (9 bits)
    output [23:0] rounded_mantissa, // Rounded mantissa
    output [7:0] rounded_exponent   // Rounded exponent
);

    wire [23:0] mantissa_incremented;
    wire [8:0] exponent_incremented;
    wire carry_out, carry_to_exponent;
    wire msb; // MSB of mantissa for rounding decision

    // Determine the MSB of the mantissa for rounding decision
    assign msb = mantissa[23];

    // Perform bit-wise increment of mantissa (mimicking a ripple carry adder for 24-bit)
    // Increments the mantissa if the MSB is 1
    genvar i;
    generate
        for (i = 0; i < 23; i = i + 1) begin: INCREMENT_MANTISSA
            // XOR for sum and AND for carry for each bit
            assign mantissa_incremented[i] = mantissa[i] ^ msb;
            assign carry_out = mantissa[i] & msb; // Propagate carry
        end
    endgenerate

    // Handle the exponent increment if there's a carry-out from mantissa increment
    assign carry_to_exponent = carry_out;
    
    // Logic to adjust exponent if there is a carry-out from the mantissa increment
    assign exponent_incremented[7:0] = exponent[7:0] + carry_to_exponent;

    // Final rounding logic: if the MSB was set, round up the mantissa, else no change
    assign rounded_mantissa = (msb) ? mantissa_incremented : mantissa;
    assign rounded_exponent = (msb) ? exponent_incremented : exponent[7:0];

endmodule

module TestFloatingPointMultiplier;

    // Inputs
    reg [31:0] a, b;

    // Output
    wire [31:0] result;

    // Instantiate the FloatingPointMultiplier module
    FloatingPointMultiplier uut (
        .a(a),
        .b(b),
        .result(result)
    );

    // Test procedure
    initial begin
        $monitor("Time: %0t | A: %h | B: %h | Result: %h", $time, a, b, result);

        // Test Case 1: Normal multiplication
        a = 32'h3FC00000; // 1.5
        b = 32'h40200000; // 2.5
        #10;

        // Test Case 2: Positive and negative multiplication
        a = 32'hBFC00000; // -1.5
        b = 32'h40000000; // 2.0
        #10;

        // Test Case 3: Multiplying with zero
        a = 32'h00000000; // 0.0
        b = 32'h40400000; // 3.0
        #10;

        // Test Case 4: Infinity multiplication
        a = 32'h7F800000; // Infinity
        b = 32'h3F800000; // 1.0
        #10;

        // Test Case 5: Subnormal numbers
        a = 32'h00000001; // Small subnormal
        b = 32'h00000002; // Another subnormal
        #10;

        // Test Case 6: Overflow
        a = 32'h7F7FFFFF; // Largest finite positive
        b = 32'h3F800000; // 1.0
        #10;

        // Test Case 7: NaN propagation
        a = 32'h7FC00000; // NaN
        b = 32'h40400000; // 3.0
        #10;

        // Test Case 8: Negative infinity
        a = 32'hFF800000; // -Infinity
        b = 32'h40000000; // 2.0
        #10;

        // Test Case 9: Maximum value multiplication
        a = 32'h7F7FFFFF; // Max finite positive
        b = 32'h7F7FFFFF; // Same value
        #10;

        // Test Case 10: Negative max multiplication
        a = 32'hFF7FFFFF; // Max finite negative
        b = 32'hFF7FFFFF; // Same value
        #10;

        // New Test Cases with 3-digit values
        // Test Case 11: Multiplication of 3-digit values
        a = 32'h447A0000; // 1000.0
        b = 32'h42C80000; // 100.0
        #10;

        // Test Case 12: Large 3-digit multiplication
        a = 32'h44FA0000; // 2000.0
        b = 32'h43480000; // 200.0
        #10;

        // Test Case 13: Negative and positive 3-digit multiplication
        a = 32'hC4E00000; // -1800.0
        b = 32'h42F00000; // 120.0
        #10;

        // Test Case 14: Subnormal and 3-digit multiplication
        a = 32'h00000123; // Small subnormal
        b = 32'h42F00000; // 120.0
        #10;

        // Test Case 15: 3-digit multiplication resulting in overflow
        a = 32'h47800000; // Large value (65536.0)
        b = 32'h47800000; // Same value (65536.0)
        #10;
        
         a = 32'h00000001; b = 32'h00000000; #10;

        $finish;
    end

endmodule

module FloatingPointMultiplier (
    input [31:0] a,       // 32-bit floating-point number A
    input [31:0] b,       // 32-bit floating-point number B
    output [31:0] result  // 32-bit floating-point result
);

    // Extracting the sign, exponent, and mantissa
    wire sign_a, sign_b, sign_result;
    wire [7:0] exp_a, exp_b, exp_result;
    wire [23:0] mant_a, mant_b;
    wire [47:0] mant_mult;
    wire overflow, underflow;

    assign sign_a = a[31];
    assign sign_b = b[31];
    assign exp_a = a[30:23];
    assign exp_b = b[30:23];
    
    // Detect subnormals and normalize mantissas
    
    wire is_subnormal_a = (exp_a == 8'b0);
    wire is_subnormal_b = (exp_b == 8'b0);

    assign mant_a = is_subnormal_a ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
    wire [47:0] mant_multi;
    assign mant_b = is_subnormal_b ? {1'b0, b[22:0]} : {1'b1, b[22:0]};

    // XOR for the result's sign
    xor(sign_result, sign_a, sign_b);

    // Exponent addition and bias adjustment
    
    wire [8:0] exp_sum = exp_a + exp_b - 8'd127;

    // Multiplication of mantissas
    WallaceTreeMultiplier mant_mult_module (
        .a(mant_a), 
        .b(mant_b), 
        .product(mant_multi)
    );
    assign mant_mult = mant_a * mant_b;
    // Normalization
    wire [7:0] normalized_exp;
    wire [23:0] normalized_mant;
    assign normalized_exp = mant_mult[47] ? exp_sum + 1 : exp_sum;
    assign normalized_mant = mant_mult[47] ? mant_mult[46:24] : mant_mult[45:23];

    // Overflow and underflow checks
    assign overflow = (normalized_exp >= 8'd255);
    assign underflow = (normalized_exp <= 8'd0);

    // Handling special cases: NaN, Infinity, and Zero
    wire is_nan = (exp_a == 8'b11111111 && a[22:0] != 0) || 
                  (exp_b == 8'b11111111 && b[22:0] != 0);
    wire is_inf = (exp_a == 8'b11111111 && a[22:0] == 0) || 
                  (exp_b == 8'b11111111 && b[22:0] == 0);

    // Handle denormal (subnormal) numbers
    wire is_subnormal_result = is_subnormal_a || is_subnormal_b;
    assign result = is_nan ? {1'b0, 8'b11111111, 23'b1} :        // NaN
                    is_inf ? {sign_result, 8'b11111111, 23'b0} : // Infinity
                    underflow ? {sign_result, 31'b0} :           // Zero
                    overflow ? {sign_result, 8'b11111111, 23'b0} : // Overflow to infinity
                    (is_subnormal_result) ? {sign_result, 8'b0, normalized_mant[22:0]} : // Subnormal result
                    {sign_result, normalized_exp[7:0], normalized_mant[22:0]}; // Normal result

endmodule