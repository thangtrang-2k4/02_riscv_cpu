# 🧠 RV32I RISC-V CPU Project  
### Single-Cycle Core & 5-Stage Pipeline Core Implementation

This project implements two CPU architectures following the RISC-V **RV32I** instruction set:

- **Single-Cycle Core** — each instruction finishes in a single clock cycle.
- **5-Stage Pipeline Core (IF → ID → EX → MEM → WB)** — improved throughput through instruction-level parallelism.

The repository includes RTL design, testbench, simulation scripts, assembly verification programs, and FPGA build files (Quartus + DE2-115).

---

## 📁 Directory Structure

```text
02_riscv_cpu/
│
├── common/                          # Shared modules (decoder, imm-gen, ALU control…)
│
├── 01_single_cycle_core_rv32i/
│   ├── rtl/                         # ALU, register file, control, datapath…
│   ├── tb/                          # Testbench
│   ├── sw/                          # Assembly programs + .hex output
│   ├── sim/                         # compile.f, run.do, wave.do
│   ├── fpga/                        # FPGA top-level + LED/SW mapping
│   ├── quartus/                     # Quartus project files
│   └── Makefile
│
├── 02_pipeline_core_rv32i/
│   ├── rtl/                         # IF/ID/EX/MEM/WB + hazard + forwarding
│   ├── tb/
│   ├── sw/
│   ├── sim/
│   ├── fpga/
│   ├── quartus/
│   ├── img/                         # Waveforms, diagrams
│   └── Makefile
│
└── README.md
```

---

## ⚙️ System Overview

### 🔹 Single-Cycle Core
A simple CPU where each instruction completes in one cycle.

Features:
- RV32I ISA  
- 32-bit ALU  
- Immediate generator  
- 32×32 Register File  
- Branch comparator  
- Instruction & Data Memory  
- Supports LW, SW  

---

### 🔹 5-Stage Pipeline Core
Implements classic RISC pipeline stages:

**IF → ID → EX → MEM → WB**

Includes:
- Forwarding paths (EX→EX, MEM→EX)  
- Hazard Detection Unit (load-use stall)  
- Pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB)  
- Branch decision in EX stage  
- Flush logic on misprediction  

---

## 🧪 Running Simulation (QuestaSim)

```bash
make clear
make gui UNIT=<single/pipeline> BARE=<yes/no> BOARD=<fpga>
```

Waveforms load automatically through `wave.do`.

---

## 📝 Test Programs

Located in `sw/out/`:

- `counter.hex` — up/down counter  
- `hazard_test.hex` — load-use hazard  
- `branch_test.hex` — BEQ/BNE/BLT/BGE tests  

---

## 🖥️ FPGA Build (DE2-115)

Steps:
1. Open Quartus project:
    ```
    RV32I_FPGA.qpf
    RV32I_FPGA.qsf
    ```
2. Run:
   - Analysis & Synthesis  
   - Place & Route  
   - Program Device  

Hardware behavior:
- Input clock: 50 MHz  
- Clock divider generates ~1 Hz  
- LED outputs show program state  
- Switches control input modes  

---

## 📊 Performance Summary

| Architecture        | CPI         | Notes |
|---------------------|-------------|-------------------------------------------|
| Single-Cycle        | 1.0 CPI     | Long critical path → lower frequency      |
| Pipeline (5-stage)  | ≈1.4 CPI    | Stalls from hazards but higher frequency  |

Hazards:
- Load-use → 1 stall  
- Branch mispredict → 2-stage flush  

---

## 📚 References

- *Computer Organization and Design — RISC-V Edition*  
- *The RISC-V Reader* — Patterson & Waterman  
- *Digital Design & Computer Architecture — RISC-V Edition*  

---

## 👤 Author

**Trang Dang Vi Thang**  
Electronics & Telecommunications Engineering — HCMUTE  
Focus: RTL Design, Functional Verification, RISC-V CPU, FPGA, UVM  
