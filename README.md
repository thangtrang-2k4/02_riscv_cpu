RV32I RISC-V CPU Project
Single-Cycle Core & 5-Stage Pipeline Core Implementation

Overview
    This project implements two CPU architectures based on the RISC-V RV32I instruction set:
    Single-Cycle Core — each instruction completes in a single clock cycle.
    5-Stage Pipeline Core (IF–ID–EX–MEM–WB) — improved performance with instruction-level parallelism.
    The project includes RTL design, testbench, simulation scripts, verification programs (assembly), and FPGA build files (Quartus + DE2-115).

Directory Structure
    02_riscv_cpu/
    │
    ├── common/ # Shared modules (ALU control, imm-gen, decoder…)
    │
    ├── 01_single_cycle_core_rv32i/
    │ ├── rtl/ # RTL: register file, ALU, decoder, datapath, control…
    │ ├── tb/ # Testbench for single-cycle core
    │ ├── sw/ # Assembly programs + .hex output
    │ ├── sim/ # compile.f, run.do, wave.do
    │ ├── fpga/ # FPGA top-level + LED/SW mapping
    │ ├── quartus/ # Quartus project files
    │ └── Makefile
    │
    ├── 02_pipeline_core_rv32i/
    │ ├── rtl/ # RTL separated by stage + hazard + forwarding units
    │ ├── tb/
    │ ├── sw/
    │ ├── sim/
    │ ├── fpga/
    │ ├── quartus/
    │ ├── img/ # Waveform and diagrams
    │ └── Makefile
    │
    └── README.md

Key Features
    Single-Cycle Core
        Supports RV32I ISA
        32-bit ALU
        Immediate generator
        32×32 Register File
        Branch comparator
        Instruction Memory + Data Memory
        Load/Store instructions (LW, SW)
    5-Stage Pipeline Core
        Classic pipeline: IF → ID → EX → MEM → WB
        Forwarding unit (EX→EX, MEM→EX)
        Hazard Detection Unit (load-use stall)
        Pipeline registers: IF/ID, ID/EX, EX/MEM, MEM/WB
        Branch decision in EX stage
        Flush logic for branch misprediction

Running Simulation (QuestaSim)
    make clear
    make gui UNIT/BARE/BOARD = ***
    Refer to the Makefile for detailed options.
    Viewing Waveform
    Waveforms are automatically loaded via wave.do

Test Programs
    Located in sw/out/:
    counter.hex — up/down counter
    hazard_test.hex — induces load-use hazard
    branch_test.hex — BEQ/BNE/BLT/BGE verification

FPGA Build & Execution (DE2-115)
    50 MHz input clock from the board
    Clock divider generates ~1 Hz for LED visualization
    LEDs display register or program output values
    Switches control CPU mode (counter mode, reset, etc.)
    Open the Quartus project in quartus/:
    RV32I_FPGA.qpf
    RV32I_FPGA.qsf
    Then: Synthesis → Place & Route → Program Device

Performance Summary

    Architecture	CPI	  Notes
    Single-Cycle	1 CPI	  Lower clock frequency due to long critical path
    Pipeline 5-stage	≈1.4 CPI  (except stalls) Higher frequency, increased throughput
    
    Load-use hazard → 1 stall cycle
    Branch misprediction → flush 2 stages (design dependent)

References
    Computer Organization and Design — RISC-V Edition (Patterson & Hennessy)
    The RISC-V Reader — Patterson & Waterman
    Digital Design & Computer Architecture — RISC-V Edition

Author
    Trang Dang Vi Thang
    Electronics & Telecommunications Engineering Student — HCMUTE
    Focus areas: RTL Design, Functional Verification, RISC-V CPU, FPGA, UVM

