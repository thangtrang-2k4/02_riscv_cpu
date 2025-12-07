// ================================================================
// RV32I Pipline CPU (datapath + control) - top level
// 
// 
// 
// 
// ================================================================
`timescale 1ns/1ps
module RV32I_Pipline #(
  parameter int    DEPTH_WORDS = 2048
)(
  input  logic clk,
  input  logic rst_n,
  
  input  logic [7:0] sw,
  output logic [7:0] led

  // single_cycle.sv: khai báo port
  //output logic [31:0] a0_out

);

  import rv32_pkg::*;

  // Adder
  logic [31:0] pc_plus4;

  // MUX ALU / PC + 4
  logic [31:0] pc_next;

  // Program Counter
  logic [31:0] pc;
  
  // Control Logic       
  ctrl_t ctrl;

  // Instruction Memory
  logic [31:0] inst;

  // Immediate Generator
  logic [31:0] imm;
  
  // Register File
  logic [31:0] dataR1, dataR2;

  // Branch Comparator
  logic BrEq, BrLT;

  // Branch Control
  logic PCSel;

  // Forwarding Control Logic
  logic [1:0] forwardA, forwardB;

  // MUX Forwarding 
  logic [31:0] dataR1_fwd, dataR2_fwd;

  // MUX A / B
  logic [31:0] A, B;

  // ALU
  logic [31:0] alu;

  // Data Memory
  logic [31:0] mem;

  // MUX Write Back
  logic [31:0] WBdata;

  // Hazards Detect
  logic stall;

  // PC_EX, rs1_EX, rs2_EX, imm_EX, rd_EX, inst_EX
  logic [31:0] pc_EX, dataR1_EX, dataR2_EX, imm_EX, inst_EX;

  // giữ control tới EX
  ctrl_t ctrl_EX;


  // PC4_MEM, alu_MEM, rs2_MEM + branch info cho MEM
  logic [31:0] pc_MEM, alu_MEM, dataR2_MEM, inst_MEM;

  // Control sang MEM
  ctrl_t ctrl_MEM;

  // PC4_WB, alu_WB, mem_WB + control tới WB
  logic [31:0] pc_plus4_mem_WB, alu_WB, mem_WB, inst_WB;

  // Control sang WB
  ctrl_t ctrl_WB;



  // IF

  // ------------------------------
  // MUX ALU / PC + 4
  // ------------------------------
  //assign pc_next = (ctrl.PCSel == PC_PC4) ? pc_plus4 : alu;

  logic [31:0] pc_next_raw;
  
  assign pc_next_raw   = (PCSel ) ? alu : pc_plus4;
  assign pc_next = stall ? pc : pc_next_raw;

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
  Adder u_add1 (
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

  // ---------- IF/ID pipeline registers ----------
  // PC_ID, inst_ID
  logic [31:0] pc_ID, inst_ID;

  // baseline: luôn en=1, flush=0 (chưa có stall/flush)
  pipe_reg #(.W(32)) u_pc_ID (
    .clk(clk), .rst_n(rst_n), .en(!stall), .flush(PCSel),
    .d(pc), .bubble(32'b0), .q(pc_ID)
  );

  pipe_reg #(.W(32)) u_inst_ID (
    .clk(clk), .rst_n(rst_n), .en(!stall), .flush(PCSel),
    .d(inst), .bubble(32'h00000013), // NOP = ADDI x0,x0,0
    .q(inst_ID)
  );

  // ID

  // ------------------------------
  // Control Logic
  // ------------------------------
  Control_Logic u_ctrl (
    .opcode (rv32_pkg::opcode_t'(inst_ID[6:0])),
    .funct3 (rv32_pkg::funct3_t'(inst_ID[14:12])),
    .funct7 (inst_ID[31:25]),
    //.BrEq   (BrEq),
    //.BrLT   (BrLT),     // LƯU Ý: dùng đúng tên cổng đã sửa trong Control_Logic
    //.PCSel  (ctrl.PCSel),
    .ImmSel (ctrl.ImmSel),
    .BrUn   (ctrl.BrUn),
    .ASel   (ctrl.ASel),
    .BSel   (ctrl.BSel),
    .ALUSel (ctrl.ALUSel),
    .MemRW  (ctrl.MemRW),
    .RegWEn (ctrl.RegWEn),
    .WBSel  (ctrl.WBSel)
  );

  // ------------------------------
  // Immediate Generator
  // ------------------------------
  ImmGen u_immgen (
    .inst   (inst_ID[31:7]),
    .ImmSel (ctrl.ImmSel),
    .imm    (imm)
  );

  // ------------------------------
  // Register File
  // ------------------------------
  RegFile #(.WRITE_THROUGH(1'b1)) u_regfile (
    .clk   (clk),
    .rst_n (rst_n),
    .rsR1  (inst_ID[19:15]),
    .rsR2  (inst_ID[24:20]),
    .rsW   (inst_WB[11:7]),
    .dataW (WBdata),
    .RegWEn(ctrl_WB.RegWEn),
    .dataR1(dataR1),
    .dataR2(dataR2)
  );

  // ---------- ID/EX pipeline registers ----------


  // baseline: en=1, flush=0
  pipe_reg #(.W(32)) u_pc_EX     (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall), .d(pc_ID),        .bubble(32'b0),         .q(pc_EX));
  pipe_reg #(.W(32)) u_dataR1_EX (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall), .d(dataR1),  .bubble(32'b0),         .q(dataR1_EX));
  pipe_reg #(.W(32)) u_dataR2_EX (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall), .d(dataR2),  .bubble(32'b0),         .q(dataR2_EX));
  pipe_reg #(.W(32)) u_imm_EX    (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall), .d(imm),       .bubble(32'b0),         .q(imm_EX));
  pipe_reg #(.W(32)) u_inst_EX   (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(inst_ID),      .bubble(32'h00000013),  .q(inst_EX));

  // control -> EX
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_EX   (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(stall | PCSel), .d(ctrl),      .bubble(CTRL_NOP),  .q(ctrl_EX));
  // EX

  // ------------------------------
  // Forwarding Control Logic
  // ------------------------------
  Forwarding_Unit u_fwd_ctrl (
    .RegWEn_MEM(ctrl_MEM.RegWEn),
    .RegWEn_WB(ctrl_WB.RegWEn),
    .MemRW_MEM(ctrl_MEM.MemRW),
    .WBSel_MEM(ctrl_MEM.WBSel),
    .inst_EX(inst_EX),
    .inst_MEM(inst_MEM),
    .inst_WB(inst_WB),
    .forwardA(forwardA),
    .forwardB(forwardB)
  );
  // ------------------------------
  // Branch Comparator
  // ------------------------------
  Branch_Comparator #(.WIDTH(32)) u_branch_comp (
    .rs1 (dataR1_fwd),
    .rs2 (dataR2_fwd),
    .BrUn(ctrl_EX.BrUn),
    .BrEq(BrEq),
    .BrLT(BrLT)
  );


  // ------------------------------
  // MUX A/B
  // ------------------------------
  always_comb begin
    unique case (forwardA)  // 00 RF, 10 EX/MEM, 01 MEM/WB
      2'b10: dataR1_fwd = alu_MEM;
      2'b01: dataR1_fwd = WBdata;
      default: dataR1_fwd = dataR1_EX;
    endcase
  end
  // ASel MUX: 0 -> rs1; 1 -> PC
  assign A = (ctrl_EX.ASel) ? pc_EX : dataR1_fwd;

  
  always_comb begin
    unique case (forwardB)
      2'b10: dataR2_fwd = alu_MEM;
      2'b01: dataR2_fwd = WBdata;
      default: dataR2_fwd = dataR2_EX;
    endcase
  end
  // BSel MUX: 0 -> rs2; 1 -> imm
  assign B = (ctrl_EX.BSel) ? imm_EX : dataR2_fwd;

  // ------------------------------
  // ALU
  // ------------------------------
  ALU u_alu (
    .A      (A),
    .B      (B),
    .ALUSel (ctrl_EX.ALUSel),
    .alu    (alu)
  );

  // ------------------------------
  // Branch Control
  // ------------------------------
  Branch_Control u_branch_ctrl (
    .opcode_EX(rv32_pkg::opcode_t'(inst_EX[6:0])),
    .funct3_EX(rv32_pkg::funct3_t'(inst_EX[14:12])),
    .BrEq(BrEq),
    .BrLT(BrLT),
    .PCSel(PCSel)
  );

  // ---------- EX/MEM pipeline registers ----------


  pipe_reg #(.W(32)) u_pc_MEM     (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(pc_EX), .bubble(32'b0), .q(pc_MEM));
  pipe_reg #(.W(32)) u_alu_MEM    (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(alu), .bubble(32'b0), .q(alu_MEM));
  pipe_reg #(.W(32)) u_dataR2_MEM (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(dataR2_fwd), .bubble(32'b0), .q(dataR2_MEM));
  pipe_reg #(.W(32)) u_inst_MEM   (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(inst_EX), .bubble(32'h00000013), .q(inst_MEM));
  // Control
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_MEM   (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(ctrl_EX),      .bubble(CTRL_NOP),  .q(ctrl_MEM));
  // MEM

  // ------------------------------
  // Data Memory (LW/SW 32-bit)
  // ------------------------------
  Data_Memory #(
    .DEPTH_WORDS(DEPTH_WORDS)
  ) u_dmem (
    .clk   (clk),
    .rst_n (rst_n),
    .addr  (alu_MEM),        // address từ ALU
    .dataW (dataR2_MEM),     // store dữ liệu từ rs2
    .MemRW (ctrl_MEM.MemRW),      // 1: write, 0: read
    .dataR (mem),  // read data
	 
	 .sw    (sw),
    .led   (led)
  );

  // ------------------------------
  // Adder PC + 4
  // ------------------------------
  logic [31:0] pc_plus4_mem;
  Adder u_add2 (
    .a (pc_MEM),
    .b (32'd4),
    .c (pc_plus4_mem)
  );

  // ---------- MEM/WB pipeline registers ----------


  pipe_reg #(.W(32)) u_pc4_WB  (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(pc_plus4_mem), .bubble(32'b0), .q(pc_plus4_mem_WB));
  pipe_reg #(.W(32)) u_alu_WB  (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(alu_MEM), .bubble(32'b0), .q(alu_WB));
  pipe_reg #(.W(32)) u_mem_WB  (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(mem), .bubble(32'b0), .q(mem_WB));
  pipe_reg #(.W(32)) u_inst_WB (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(inst_MEM), .bubble(32'h00000013), .q(inst_WB));
  // Control
  pipe_reg #(.W($bits(ctrl_t))) u_ctrl_WB   (.clk(clk), .rst_n(rst_n), .en(1'b1), .flush(1'b0), .d(ctrl_MEM),      .bubble(CTRL_NOP),  .q(ctrl_WB));
  // ------------------------------
  // Write-Back MUX
  // WBSel: 00->MEM, 01->ALU, 10->PC+4
  // ------------------------------
  always_comb begin
    unique case (ctrl_WB.WBSel)
      WB_MEM: WBdata = mem_WB;
      WB_ALU: WBdata = alu_WB;
      WB_PC4: WBdata = pc_plus4_mem_WB;
      default: WBdata = 32'h0;
    endcase
  end

  // ------------------------------
  // Hazards Detect
  // ------------------------------
  Hazard_Detection u_hazard (
    .inst_ID(inst_ID),
    .inst_EX(inst_EX),
    .stall(stall)
  );


//  // Mirror a0 (x10) mỗi khi ghi WB vào x10
//  always_ff @(posedge clk or negedge rst_n) begin
//    if (!rst_n) a0_out <= 32'd0;
//    else if (RegWEn && (inst[11:7] == 5'd10))  // rd == x10
//      a0_out <= WBdata;
//  end


endmodule
