## Initial Objective

The first functional version of AURA32 will implement a small subset of the RV32I instruction set using a single-cycle datapath.

The initial supported instructions will be:

- `ADD`
- `SUB`
- `ADDI`
- `LW`
- `SW`
- `BEQ`
- `JAL`

After this version is verified, the processor will be converted into a five-stage pipeline.

## Final Pipeline Stages

1. Instruction Fetch — IF
2. Instruction Decode — ID
3. Execute — EX
4. Memory Access — MEM
5. Register Writeback — WB

## Planned Core Modules

- Arithmetic logic unit
- Register file
- Immediate generator
- Main instruction decoder
- ALU control decoder
- Program counter
- Instruction memory interface
- Data memory interface
- Single-cycle processor core
- Pipeline registers
- Forwarding unit
- Hazard detection unit
- SIMD accelerator