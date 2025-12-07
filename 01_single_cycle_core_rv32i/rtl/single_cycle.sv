// ================================================================
// RV32I Single-Cycle CPU (datapath + control) - top level
// 
// 
// 
// 
// ================================================================
`timescale 1ns/1ps
module single_cycle #(
  parameter int    DEPTH_WORDS = 1024
)(
  input  logic clk,
  input  logic rst_n,

  // single_cycle.sv: khai báo port
  output logic [31:0] a0_out

);

  import rv32_pkg::*;

  // Adder
  logic [31:0] pc_plus4;

  // MUX ALU / PC + 4
  logic [31:0] pc_next;

  // Program Counter
  logic [31:0] pc;
  
  // Control Logic       
  rv32_pkg::PCSel_t  PCSel;
  rv32_pkg::ImmSel_t ImmSel;
  logic              ASel;
  logic              BSel;
  rv32_pkg::ALUSel_t ALUSel;
  logic              MemRW;
  logic              RegWEn;
  rv32_pkg::WBSel_t  WBSel;
  
  // Instruction Memory
  logic [31:0] inst;

  // Immediate Generator
  logic [31:0] imm;
  
  // Register File
  logic [31:0] dataR1, dataR2;

  // Branch Comparator
  logic BrUn, BrEq, BrLT;
  
  // MUX A / B
  logic [31:0] A, B;

  // ALU
  logic [31:0] alu;

  // Data Memory
  logic [31:0] mem;

  // MUX Write Back
  logic [31:0] WBdata;

  // ------------------------------
  // MUX ALU / PC + 4
  // ------------------------------
  assign pc_next = (PCSel == PC_PC4) ? pc_plus4 : alu;

  // ------------------------------
  // Program Counter
  // ------------------------------
  Program_Counter u_pc (
    .clk    (clk),
    .rst_n  (rst_n),
    .pc_next(pc_next),
    .pc   (pc)
  );

  // ------------------------------
  // Adder PC + 4
  // ------------------------------
  Adder u_add (
    .a (pc),
    .b (32'd4),
    .c (pc_plus4)
  );

  // ------------------------------
  // Instruction memory 
  // ------------------------------
  IMEM #(
    .DEPTH_WORDS(DEPTH_WORDS)
  )u_imem (
    .rst_n (rst_n),
    .addr  (pc),
    .inst  (inst)
  );

  // ------------------------------
  // Immediate Generator
  // ------------------------------
  ImmGen u_immgen (
    .inst   (inst[31:7]),
    .ImmSel (ImmSel),
    .imm    (imm)
  );

  // ------------------------------
  // Register File
  // ------------------------------
  RegFile #(.WRITE_THROUGH(1'b0)) u_regfile (
    .clk   (clk),
    .rst_n (rst_n),
    .rsR1  (inst[19:15]),
    .rsR2  (inst[24:20]),
    .rsW   (inst[11:7]),
    .dataW (WBdata),
    .RegWEn(RegWEn),
    .dataR1(dataR1),
    .dataR2(dataR2)
  );

  // ------------------------------
  // Branch Comparator
  // ------------------------------
  Branch_Comparator #(.WIDTH(32)) u_branch_comp (
    .rs1 (dataR1),
    .rs2 (dataR2),
    .BrUn(BrUn),
    .BrEq(BrEq),
    .BrLT(BrLT)
  );

  // ------------------------------
  // Control Logic
  // ------------------------------
  Control_Logic u_ctrl (
    .opcode (rv32_pkg::opcode_t'(inst[6:0])),
    .funct3 (rv32_pkg::funct3_t'(inst[14:12])),
    .funct7 (inst[31:25]),
    .BrEq   (BrEq),
    .BrLT   (BrLT),     // LƯU Ý: dùng đúng tên cổng đã sửa trong Control_Logic
    .PCSel  (PCSel),
    .ImmSel (ImmSel),
    .BrUn   (BrUn),
    .ASel   (ASel),
    .BSel   (BSel),
    .ALUSel (ALUSel),
    .MemRW  (MemRW),
    .RegWEn (RegWEn),
    .WBSel  (WBSel)
  );

  // ------------------------------
  // MUX A/B
  // ------------------------------
  
  // ASel MUX: 0 -> rs1; 1 -> PC
  assign A = (ASel) ? pc : dataR1;

  // BSel MUX: 0 -> rs2; 1 -> imm
  assign B = (BSel) ? imm : dataR2;

  // ------------------------------
  // ALU
  // ------------------------------
  ALU u_alu (
    .A      (A),
    .B      (B),
    .ALUSel (ALUSel),
    .alu    (alu)
  );

  // ------------------------------
  // Data Memory (LW/SW 32-bit)
  // ------------------------------
  Data_Memory #(
    .DEPTH_WORDS(DEPTH_WORDS)
  ) u_dmem (
    .clk   (clk),
    .rst_n (rst_n),
    .addr  (alu),        // address từ ALU
    .dataW (dataR2),     // store dữ liệu từ rs2
    .MemRW (MemRW),      // 1: write, 0: read
    .dataR (mem)  // read data
  );

  // ------------------------------
  // Write-Back MUX
  // WBSel: 00->MEM, 01->ALU, 10->PC+4
  // ------------------------------
  always_comb begin
    unique case (WBSel)
      WB_MEM: WBdata = mem;
      WB_ALU: WBdata = alu;
      WB_PC4: WBdata = pc_plus4;
      default: WBdata = 32'h0;
    endcase
  end


  // Mirror a0 (x10) mỗi khi ghi WB vào x10
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) a0_out <= 32'd0;
    else if (RegWEn && (inst[11:7] == 5'd10))  // rd == x10
      a0_out <= WBdata;
  end


endmodule
