32-bit RISC-V hardware-design project covering the complete development path from processor architecture and SystemVerilog RTL to verification, synthesis, and ASIC physical implementation.

## Planned Architecture

- RV32I base integer instruction set
- Functional single-cycle CPU
- Five-stage pipelined CPU
- Data forwarding and hazard detection
- Load-use pipeline stalls
- Branch and jump flushing
- Memory-mapped peripherals
- Four-lane SIMD accelerator
- Verilator-based automated verification
- Yosys synthesis
- SKY130 RTL-to-GDS implementation

## Planned Pipeline

```text
Instruction Fetch
       ↓
Instruction Decode
       ↓
Execute
       ↓
Memory
       ↓
Writeback