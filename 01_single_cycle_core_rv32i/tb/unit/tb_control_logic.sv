`timescale 1ns/1ps
module tb_control_logic;
  import rv32_pkg::*;

  // DUT I/O
  opcode_t   opcode;
  funct3_t   funct3;
  logic [6:0] funct7;
  logic       BrEq, BrLT;

  PCSel_t     PCSel;
  ImmSel_t    ImmSel;
  logic       BrUn, ASel, BSel;
  ALUSel_t    ALUSel;
  logic       MemRW, RegWEn;
  WBSel_t     WBSel;

  // Instantiate DUT
  Control_Logic dut (
    .opcode, .funct3, .funct7, .BrEq, .BrLT,
    .PCSel, .ImmSel, .BrUn, .ASel, .BSel, .ALUSel, .MemRW, .RegWEn, .WBSel
  );

  // ------------- Helpers -------------
  int errors = 0;

  task automatic CEQ_s(string tag, string exp, string got);
    if (exp != got) begin
      $display("[FAIL] %s exp=%s got=%s", tag, exp, got);
      errors++;
    end
  endtask

  task automatic CEQ_b(string tag, bit exp, bit got);
    if (exp !== got) begin
      $display("[FAIL] %s exp=%0b got=%0b", tag, exp, got);
      errors++;
    end
  endtask

  // Drive & check all outputs for one vector
  task automatic do_check(
    string    name,
    opcode_t  in_opcode,
    funct3_t  in_f3,
    logic [6:0] in_f7,
    bit       in_BrEq, in_BrLT,

    PCSel_t   exp_PCSel,
    ImmSel_t  exp_ImmSel,
    bit       exp_BrUn,
    bit       exp_ASel, exp_BSel,
    ALUSel_t  exp_ALUSel,
    bit       exp_MemRW, exp_RegWEn,
    WBSel_t   exp_WBSel
  );
    opcode = in_opcode;  funct3 = in_f3;  funct7 = in_f7;
    BrEq   = in_BrEq;    BrLT   = in_BrLT;
    #1; // settle

    $display("\n[TEST] %s", name);
    CEQ_s("PCSel",  exp_PCSel.name(),  PCSel.name());
    CEQ_s("ImmSel", exp_ImmSel.name(), ImmSel.name());
    CEQ_b("BrUn",   exp_BrUn,  BrUn);
    CEQ_b("ASel",   exp_ASel,  ASel);
    CEQ_b("BSel",   exp_BSel,  BSel);
    CEQ_s("ALUSel", exp_ALUSel.name(), ALUSel.name());
    CEQ_b("MemRW",  exp_MemRW, MemRW);
    CEQ_b("RegWEn", exp_RegWEn, RegWEn);
    CEQ_s("WBSel",  exp_WBSel.name(), WBSel.name());
  endtask

  // ------------- Test vectors -------------
  initial begin
    $display("=== Control_Logic – full table coverage ===");

    // R-type: ADD / SUB / R-R Op (dùng OR làm đại diện)
    do_check("R: ADD",
      OC_R, F3_ADD_SUB, 7'h00, 0,0,
      PC_PC4, Imm_I, 0, 0,0, ALU_ADD, 0,1, WB_ALU);

    do_check("R: SUB",
      OC_R, F3_ADD_SUB, 7'h20, 0,0,         // funct7[5]=1
      PC_PC4, Imm_I, 0, 0,0, ALU_SUB, 0,1, WB_ALU);

    do_check("R: OR (R-R Op)",
      OC_R, F3_OR, 7'h00, 0,0,
      PC_PC4, Imm_I, 0, 0,0, ALU_OR, 0,1, WB_ALU);

    // I-type ALU: ADDI / I-Op (dùng ANDI làm đại diện)
    do_check("I-ALU: ADDI",
      OC_I_ALU, F3_ADDI, 7'h00, 0,0,
      PC_PC4, Imm_I, 0, 0,1, ALU_ADD, 0,1, WB_ALU);

    do_check("I-ALU: ANDI (I-Op)",
      OC_I_ALU, F3_ANDI, 7'h00, 0,0,
      PC_PC4, Imm_I, 0, 0,1, ALU_AND, 0,1, WB_ALU);

    // LOAD / STORE
    do_check("LOAD: LW",
      OC_I_LOAD, F3_LSW, 7'h00, 0,0,
      PC_PC4, Imm_I, 0, 0,1, ALU_ADD, 0,1, WB_MEM);

    do_check("STORE: SW",
      OC_S, F3_LSW, 7'h00, 0,0,
      PC_PC4, Imm_S, 0, 0,1, ALU_ADD, 1,0, WB_ALU /*don't care*/);

    // BRANCH – BEQ (not-taken / taken)
    do_check("BEQ not-taken (BrEq=0)",
      OC_B, F3_BEQ, 7'h00, 0,0,
      PC_PC4, Imm_B, 0, 0,1, ALU_ADD, 0,0, WB_ALU);
    do_check("BEQ taken (BrEq=1)",
      OC_B, F3_BEQ, 7'h00, 1,0,
      PC_ALU, Imm_B, 0, 0,1, ALU_ADD, 0,0, WB_ALU);

    // BRANCH – BNE (taken / not-taken)
    do_check("BNE taken (BrEq=0)",
      OC_B, F3_BNE, 7'h00, 0,0,
      PC_ALU, Imm_B, 0, 0,1, ALU_ADD, 0,0, WB_ALU);
    do_check("BNE not-taken (BrEq=1)",
      OC_B, F3_BNE, 7'h00, 1,0,
      PC_PC4, Imm_B, 0, 0,1, ALU_ADD, 0,0, WB_ALU);

    // BRANCH – BLT/BGE (signed)
    do_check("BLT signed taken (BrLT=1)",
      OC_B, F3_BLT, 7'h00, 0,1,
      PC_ALU, Imm_B, 0, 0,1, ALU_ADD, 0,0, WB_ALU);
    do_check("BLT signed not-taken (BrLT=0)",
      OC_B, F3_BLT, 7'h00, 0,0,
      PC_PC4, Imm_B, 0, 0,1, ALU_ADD, 0,0, WB_ALU);

    do_check("BGE signed taken (BrLT=0)",
      OC_B, F3_BGE, 7'h00, 0,0,
      PC_ALU, Imm_B, 0, 0,1, ALU_ADD, 0,0, WB_ALU);
    do_check("BGE signed not-taken (BrLT=1,BrEq=0)",
      OC_B, F3_BGE, 7'h00, 0,1,
      PC_PC4, Imm_B, 0, 0,1, ALU_ADD, 0,0, WB_ALU);

    // BRANCH – BLTU/BGEU (unsigned)
    do_check("BLTU taken (BrLT=1)",
      OC_B, F3_BLTU, 7'h00, 0,1,
      PC_ALU, Imm_B, 1, 0,1, ALU_ADD, 0,0, WB_ALU);
    do_check("BLTU not-taken (BrLT=0)",
      OC_B, F3_BLTU, 7'h00, 0,0,
      PC_PC4, Imm_B, 1, 0,1, ALU_ADD, 0,0, WB_ALU);

    do_check("BGEU taken (BrEq=1)",
      OC_B, F3_BGEU, 7'h00, 1,0,
      PC_ALU, Imm_B, 1, 0,1, ALU_ADD, 0,0, WB_ALU);
    do_check("BGEU not-taken (BrEq=0,BrLT=1)",
      OC_B, F3_BGEU, 7'h00, 0,1,
      PC_PC4, Imm_B, 1, 0,1, ALU_ADD, 0,0, WB_ALU);

    // Jumps
    do_check("JALR",
      OC_I_JALR, F3_ADDI, 7'h00, 0,0,
      PC_ALU, Imm_I, 0, 0,1, ALU_ADD, 0,1, WB_PC4);

    do_check("JAL",
      OC_J, F3_ADDI, 7'h00, 0,0,
      PC_ALU, Imm_J, 0, 1,1, ALU_ADD, 0,1, WB_PC4);

    // U-type
    do_check("LUI",
      OC_U_LUI, F3_ADDI, 7'h00, 0,0,
      PC_PC4, Imm_U, 0, 0,1, ALU_LUI, 0,1, WB_ALU);

    do_check("AUIPC",
      OC_U_AUIPC, F3_ADDI, 7'h00, 0,0,
      PC_PC4, Imm_U, 0, 1,1, ALU_ADD, 0,1, WB_ALU);

    // Summary
    if (errors == 0) begin
      $display("\n=== ALL TESTS PASSED ✅ ===");
    end else begin
      $display("\n=== TESTS FAILED: %0d error(s) ❌ ===", errors);
      $fatal(1);
    end
    $finish;
  end
endmodule
