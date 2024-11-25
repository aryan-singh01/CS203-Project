import re

# Define gate equivalences and delays for modules and logic gates
GATE_DATA = {
    "and": {"gates": 1, "delay": 1},               #we have consider delay for 1 gate as 1 unit
    "or": {"gates": 1, "delay": 1},
    "xor": {"gates": 2, "delay": 2},
    "not": {"gates": 1, "delay": 1},
    "FullAdder": {"gates": 6, "delay": 3},          # XOR (2), AND (3), OR (1)
    "HalfAdder": {"gates": 3, "delay": 2},          # XOR (1), AND (1)
    "Adder8Bit": {"gates": 48, "delay": 12},        # 8 Full Adders
    "Subtractor8Bit": {"gates": 56, "delay": 12},   # 8 Full Adders + 8 XOR gates for inversion
    "Multiplier24x24": {"gates": 3016, "delay": 40}, # Approx. for Wallace Tree Multiplier
    "Normalize": {"gates": 546, "delay": 15},       # Normalization logic
    "Rounding": {"gates": 20, "delay": 5},          # Rounding logic
    "SpecialCases": {"gates": 50, "delay": 8},      # NaN, Infinity, Zero handling
    "ExponentCalculation": {"gates": 3000, "delay": 20}  # Adder + Subtractor
}

def calculate_gate_count_and_delay(file_path):
    """Parses a Verilog file and estimates the total number of gates and delay."""
    total_gate_count = 0
    total_delay = 0

    try:
        with open(file_path, 'r') as file:
            content = file.read()

            # Count basic logic gates
            for gate_type in ["and", "or", "xor", "not"]:
                count = len(re.findall(rf"\b{gate_type}\b", content))
                total_gate_count += count * GATE_DATA[gate_type]["gates"]
                total_delay += count * GATE_DATA[gate_type]["delay"]

            # Count occurrences of modules
            for module, data in GATE_DATA.items():
                count = len(re.findall(rf"\b{module}\b", content))
                total_gate_count += count * data["gates"]
                total_delay += count * data["delay"]

            # Approximation for assign statements with arithmetic operations
            inline_arithmetic = len(re.findall(r"assign\s+.[+\-].*;", content))
            total_gate_count += inline_arithmetic * GATE_DATA["FullAdder"]["gates"]  # Assume FullAdder complexity
            total_delay += inline_arithmetic * GATE_DATA["FullAdder"]["delay"]

        return total_gate_count, total_delay

    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        return None, None


# Run the script
if __name__ == "_main_":
    # Path to your Verilog file
    verilog_file = r"c:\Users\asus\OneDrive\Documents\Project_CS203\problem1\FloatingPointMultiplier.v"
    total_gates, total_delay = calculate_gate_count_and_delay(verilog_file)

    if total_gates is not None:
        print(f"Total Estimated Gate Count: {total_gates}")
        print(f"Total Estimated Delay: {total_delay}")