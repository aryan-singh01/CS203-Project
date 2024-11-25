import re

# Define gate equivalences for modules and logic gates
GATE_COUNT = {
    "fulladder": 6,
    "halfadder": 3,
    "adder_64": 381,
    "wallace": 330
}

def calculate_gate_count(file_path):
    """Parses a Verilog file and estimates the total number of gates."""
    total_gate_count = 0

    try:
        with open(file_path, 'r') as file:
            content = file.read()

            # Count occurrences of modules
            for module, gate_cost in GATE_COUNT.items():
                module_count = len(re.findall(rf"\b{module}\b", content))
                total_gate_count += module_count * gate_cost

        return total_gate_count

    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        return None

# Run the script
if __name__ == "__main__":
    # Path to your Verilog file
    verilog_file = r"CS203/CS203-Project/test.v"
    total_gates = calculate_gate_count(verilog_file)

    if total_gates is not None:
        print(f"Total Estimated Gate Count: {total_gates}")