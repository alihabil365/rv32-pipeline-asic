.PHONY: help tools tree clean

help:
	@echo "AURA32 Development Commands"
	@echo ""
	@echo "  make tools  Check required development tools"
	@echo "  make tree   Display the project structure"
	@echo "  make clean  Remove generated build files"

tools:
	@echo "Checking AURA32 development tools..."
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

clean:
	@find build -mindepth 1 ! -name '.gitkeep' -delete
	@rm -rf obj_dir
	@find . -type f \( -name "*.vcd" -o -name "*.fst" -o -name "*.vvp" \) -delete
	@echo "Generated files removed."