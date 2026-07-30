.PHONY: help tools tree lint-alu test-alu clean

help:
	@echo "RV32 Development Commands"
	@echo ""
	@echo "  make tools  Check required development tools"
	@echo "  make tree   Display the project structure"
	@echo "  make clean  Remove generated build files"

tools:
	@echo "Checking RV32 development tools..."
	@echo ""
	@git --version
	@gcc --version | head -n 1
	@python3 --version
	@verilator --version
	@yosys -V
	@iverilog -V 2>&1 | head -n 1
	@echo ""
	@echo "All required tools were found."

tree:
	@tree -a -I ".git|obj_dir"

lint-alu:
	@verilator --lint-only -Wall rtl/core/alu.sv
	@echo "ALU lint passed."

test-alu: lint-alu
	@mkdir -p build
	@iverilog -g2012 -Wall \
		-s tb_alu \
		-o build/tb_alu.vvp \
		rtl/core/alu.sv \
		sim/testbench/tb_alu.sv
	@vvp build/tb_alu.vvp

lint-regfile:
	@verilator --lint-only -Wall rtl/core/register_file.sv
	@echo "Register file lint passed."

test-regfile: lint-regfile
	@mkdir -p build
	@iverilog -g2012 -Wall \
		-s tb_register_file \
		-o build/tb_register_file.vvp \
		rtl/core/register_file.sv \
		sim/testbench/tb_register_file.sv
	@vvp build/tb_register_file.vvp

lint-immgen:
	@verilator --lint-only -Wall rtl/core/immediate_generator.sv
	@echo "Immediate generator lint passed."

test-immgen: lint-immgen
	@mkdir -p build
	@iverilog -g2012 -Wall \
		-s tb_immediate_generator \
		-o build/tb_immediate_generator.vvp \
		rtl/core/immediate_generator.sv \
		sim/testbench/tb_immediate_generator.sv
	@vvp build/tb_immediate_generator.vvp

clean:
	@find build -mindepth 1 ! -name '.gitkeep' -delete
	@rm -rf obj_dir
	@find . -type f \( -name "*.vcd" -o -name "*.fst" -o -name "*.vvp" \) -delete
	@echo "Generated files removed."
