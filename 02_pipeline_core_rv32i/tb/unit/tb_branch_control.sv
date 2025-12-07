`timescale 1ns/1ps

module tb_branch_control;

  import rv32_pkg::*;

  // DUT signals
  opcode_t  opcode_EX;
  funct3_t  funct3_EX;
  logic     BrEq;
  logic     BrLT;
  logic     PCSel;

  // Instantiate DUT
  Branch_Control dut (
    .opcode_EX(opcode_EX),
    .funct3_EX(funct3_EX),
    .BrEq(BrEq),
    .BrLT(BrLT),
    .PCSel(PCSel)
  );

  // Task helper
  task automatic apply_case(
    input string name,
    input opcode_t opc,
    input funct3_t f3,
    input logic br_eq,
    input logic br_lt
  );
    begin
      opcode_EX = opc;
      funct3_EX = f3;
      BrEq      = br_eq;
      BrLT      = br_lt;
      #1;
      $display("[%s] opcode=%b funct3=%b BrEq=%b BrLT=%b -> PCSel=%b",
               name, opcode_EX, funct3_EX, BrEq, BrLT, PCSel);
    end
  endtask

  initial begin
    $display("===== TEST BRANCH CONTROL =====");

    // --------------------------------------------------
    // 1. Test nhóm lệnh JAL / JALR -> PCSel = 1
    // --------------------------------------------------
    apply_case("JAL",    OC_J,       F3_BEQ, 0, 0);
    apply_case("JALR",   OC_I_JALR,  F3_BEQ, 0, 0);

    // --------------------------------------------------
    // 7. Trường hợp mặc định -> không nhảy
    // --------------------------------------------------
    apply_case("Default: arithmetic op", OC_R, F3_BEQ, 0, 0);
    apply_case("Default: load",          OC_I_LOAD, F3_BEQ, 0, 0);
    apply_case("Default: store",         OC_S, F3_BEQ, 0, 0);

    // --------------------------------------------------
    // 2. Test BEQ: PCSel = BrEq
    // --------------------------------------------------
    apply_case("BEQ: BrEq=1",  OC_B, F3_BEQ, 1, 0);
    apply_case("BEQ: BrEq=0",  OC_B, F3_BEQ, 0, 0);

    // --------------------------------------------------
    // 3. Test BNE: PCSel = ~BrEq
    // --------------------------------------------------
    apply_case("BNE: BrEq=1",  OC_B, F3_BNE, 1, 0);
    apply_case("BNE: BrEq=0",  OC_B, F3_BNE, 0, 0);

    // --------------------------------------------------
    // 4. Test BLT:  PCSel = BrLT
    // --------------------------------------------------
    apply_case("BLT: BrLT=1", OC_B, F3_BLT, 0, 1);
    apply_case("BLT: BrLT=0", OC_B, F3_BLT, 0, 0);

    // --------------------------------------------------
    // 5. Test BGE: PCSel = (~BrLT | BrEq)
    // --------------------------------------------------
    apply_case("BGE: (BrLT=0)", OC_B, F3_BGE, 0, 0);  // ~0=1 → PCSel=1
    apply_case("BGE: (BrEq=1)", OC_B, F3_BGE, 1, 1);  // BrEq=1 → PCSel=1
    apply_case("BGE: no branch", OC_B, F3_BGE, 0, 1); // BrEq=0 & BrLT=1 → no branch → 0

    // --------------------------------------------------
    // 6. Test BLTU và BGEU (unsigned)
    // --------------------------------------------------
    apply_case("BLTU: BrLT=1", OC_B, F3_BLTU, 0, 1);
    apply_case("BLTU: BrLT=0", OC_B, F3_BLTU, 0, 0);

    apply_case("BGEU: (BrLT=0)", OC_B, F3_BGEU, 0, 0); // ~0=1 → PCSel=1
    apply_case("BGEU: (BrEq=1)", OC_B, F3_BGEU, 1, 1); // BrEq=1 → PCSel=1
    apply_case("BGEU: no branch", OC_B, F3_BGEU, 0, 1);



    $display("===== DONE =====");
    #10 $finish;
  end

endmodule
