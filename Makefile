.PHONY: help tools tree lint-alu test-alu clean
.PHONY: lint-branch test-branch
.PHONY: lint-imem test-imem
.PHONY: lint-dmem test-dmem
.PHONY: lint-single-cycle test-single-cycle test-all
.PHONY: lint-if-id test-if-id

lint-if-id:
	@verilator --lint-only -Wall rtl/pipeline/if_id_register.sv
	@echo "IF/ID pipeline register lint passed."

test-if-id: lint-if-id
	@mkdir -p build
	@iverilog -g2012 -Wall \
		-s tb_if_id_register \
		-o build/tb_if_id_register.vvp \
		rtl/pipeline/if_id_register.sv \
		sim/testbench/tb_if_id_register.sv
	@vvp build/tb_if_id_register.vvp


lint-branch:
	@verilator --lint-only -Wall rtl/core/branch_unit.sv
	@echo "Branch unit lint passed."

test-branch: lint-branch
	@mkdir -p build
	@iverilog -g2012 -Wall \
		-s tb_branch_unit \
		-o build/tb_branch_unit.vvp \
		rtl/core/branch_unit.sv \
		sim/testbench/tb_branch_unit.sv
	@vvp build/tb_branch_unit.vvp

lint-imem:
	@verilator --lint-only -Wall rtl/memory/instruction_memory.sv
	@echo "Instruction memory lint passed."

test-imem: lint-imem
	@mkdir -p build
	@iverilog -g2012 -Wall \
		-s tb_instruction_memory \
		-o build/tb_instruction_memory.vvp \
		rtl/memory/instruction_memory.sv \
		sim/testbench/tb_instruction_memory.sv
	@vvp build/tb_instruction_memory.vvp

lint-dmem:
	@verilator --lint-only -Wall rtl/memory/data_memory.sv
	@echo "Data memory lint passed."

test-dmem: lint-dmem
	@mkdir -p build
	@iverilog -g2012 -Wall \
		-s tb_data_memory \
		-o build/tb_data_memory.vvp \
		rtl/memory/data_memory.sv \
		sim/testbench/tb_data_memory.sv
	@vvp build/tb_data_memory.vvp

lint-single-cycle:
	@verilator --lint-only -Wall \
		--top-module single_cycle_core \
		rtl/core/alu.sv \
		rtl/core/register_file.sv \
		rtl/core/immediate_generator.sv \
		rtl/core/control_unit.sv \
		rtl/core/program_counter.sv \
		rtl/core/branch_unit.sv \
		rtl/memory/instruction_memory.sv \
		rtl/memory/data_memory.sv \
		rtl/top/single_cycle_core.sv
	@echo "Single-cycle core lint passed."

test-single-cycle: lint-single-cycle
	@mkdir -p build
	@iverilog -g2012 -Wall \
		-s tb_single_cycle_core \
		-o build/tb_single_cycle_core.vvp \
		rtl/core/alu.sv \
		rtl/core/register_file.sv \
		rtl/core/immediate_generator.sv \
		rtl/core/control_unit.sv \
		rtl/core/program_counter.sv \
		rtl/core/branch_unit.sv \
		rtl/memory/instruction_memory.sv \
		rtl/memory/data_memory.sv \
		rtl/top/single_cycle_core.sv \
		sim/testbench/tb_single_cycle_core.sv
	@vvp build/tb_single_cycle_core.vvp

test-all: test-alu test-regfile test-immgen test-control test-pc \
	test-branch test-imem test-dmem test-single-cycle

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

lint-control:
	@verilator --lint-only -Wall rtl/core/control_unit.sv
	@echo "Control unit lint passed."

test-control: lint-control
	@mkdir -p build
	@iverilog -g2012 -Wall \
		-s tb_control_unit \
		-o build/tb_control_unit.vvp \
		rtl/core/control_unit.sv \
		sim/testbench/tb_control_unit.sv
	@vvp build/tb_control_unit.vvp

lint-pc:
	@verilator --lint-only -Wall rtl/core/program_counter.sv
	@echo "Program counter lint passed."

test-pc: lint-pc
	@mkdir -p build
	@iverilog -g2012 -Wall \
		-s tb_program_counter \
		-o build/tb_program_counter.vvp \
		rtl/core/program_counter.sv \
		sim/testbench/tb_program_counter.sv
	@vvp build/tb_program_counter.vvp
	
clean:
	@find build -mindepth 1 ! -name '.gitkeep' -delete
	@rm -rf obj_dir
	@find . -type f \( -name "*.vcd" -o -name "*.fst" -o -name "*.vvp" \) -delete
	@echo "Generated files removed."
