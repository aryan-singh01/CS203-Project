
# 32-bit Floating Point and Fixed Point Multiplier in Verilog

## Overview

This project involves the design and implementation of a 32-bit Floating Point Multiplier and a 32-bit Fixed Point Multiplier using Verilog. The floating-point implementation adheres to the IEEE 754 single-precision standard, while the fixed-point implementation uses the Q16.16 format for numerical computations. 

### Features
- **Floating Point Multiplier**
  - IEEE 754 single-precision support.
  - Handles normalization, rounding, and exceptions (e.g., NaN, infinity, zero).
- **Fixed Point Multiplier**
  - Implements 32-bit × 32-bit multiplication using Wallace Tree architecture.
  - Supports Q16.16 format.

### Applications
- Digital Signal Processing (DSP)
- Image Processing
- Scientific Computing
- Real-Time Control Systems

---

## Floating Point Multiplier

### Functional Requirements
1. **Sign Calculation**: XOR the signs of the two operands.
2. **Exponent Addition**: Add exponents with bias adjustment.
3. **Mantissa Multiplication**: Multiply mantissas using Wallace Tree structure.
4. **Normalization**: Adjust mantissa and exponent to maintain precision.
5. **Rounding**: Round result to fit IEEE 754 format.
6. **Special Cases**: Handle NaN, infinity, zero, overflow, and underflow.

### Key Components
- **Sign Calculation**: Determines the result sign using XOR gates.
- **Exponent Addition**: Uses a ripple-carry adder for bias-adjusted addition.
- **Mantissa Multiplication**: Uses a Wallace Tree Multiplier for efficient computation.
- **Normalization and Rounding**: Adjusts mantissa and exponent to fit within 23 bits.

---

## Fixed Point Multiplier

### Design Features
- Q16.16 format: 16 integer bits + 16 fractional bits.
- Wallace Tree multiplier for partial product reduction.
- Overflow detection and modular design.

### Performance Metrics
- **Speed**: Single-cycle operation.
- **Resolution**: 0.0000152587890625.
- **Range**: -32768.0 to +32767.99998474121.

---

## Testing and Validation

### Testbench Features
- Validates positive and negative multiplications.
- Tests special cases like NaN, infinity, and zero.
- Includes overflow and underflow scenarios.

### Sample Test Case
```verilog
initial begin
    $monitor("Time: %0t | A: %h | B: %h | Result: %h", $time, a, b, result);

    // Test Case 1: Multiply 1.5 and 2.5
    a = 32'h3FC00000; // 1.5
    b = 32'h40200000; // 2.5
    #10;

    // Test Case 2: Multiply by zero
    a = 32'h00000000; // 0.0
    b = 32'h40400000; // 3.0
    #10;
end
```

---

## Results and Analysis

- **Floating Point Multiplier**:
  - Adheres to IEEE 754 standards.
  - Correctly handles special cases.
- **Fixed Point Multiplier**:
  - High-performance multiplier with Q16.16 format.
  - Optimized for speed and area.

---

## Future Work

1. Pipelining for higher throughput.
2. Extending to double-precision IEEE 754 format.
3. Optimizing power consumption with clock gating.
4. Supporting configurable precision for flexible applications.

---

## Project Team
- Raman
- Kanwarveer Singh Chadha
- Divyansh Barodiya
- Divyanshu Kumar Verma
- Aryan Singh
- Ayush Tyagi

---

**Version**: 1.0  
**Date**: November 24, 2024
