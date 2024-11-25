`timescale 1ns / 1ps

module FixedPointMultiplier_Wallace_tb;

    reg [31:0] a, b; // Fixed-point operands
    wire [31:0] result; // Fixed-point result
    wire overflow; // Overflow flag

    // Instantiate the Fixed-Point Multiplier
    FixedPointMultiplier_Wallace uut (
        .a(a),
        .b(b),
        .result(result),
        .overflow(overflow)
    );

    initial begin
        $display("Time\t\tA\t\t\tB\t\t\tResult\t\tOverflow");
        $monitor("%0d\t%h\t%h\t%h\t%b", $time, a, b, result, overflow);

        // Test Case 1: Multiplying small positive numbers
        #10 a = 32'h00018000; // 1.5 in Q16
            b = 32'h0000C000; // 0.75 in Q16

        // Test Case 2: Multiplying positive and negative numbers
        #10 a = 32'hFFFF8000; // -1.5 in Q16
            b = 32'h0000C000; // 0.75 in Q16

        // Test Case 3: Multiplying large numbers (possible overflow)
        #10 a = 32'h7FFF0000; // Max positive value in Q16
            b = 32'h7FFF0000; // Max positive value in Q16

        // Test Case 4: Multiplying with zero
        #10 a = 32'h00000000; // 0.0 in Q16
            b = 32'h7FFF0000; // Max positive value in Q16

        // Test Case 5: Multiplying fractional numbers
        #10 a = 32'h0000A000; // 0.625 in Q16
            b = 32'h0000A000; // 0.625 in Q16

        // Finish simulation
        #10 $stop;
    end

endmodule
