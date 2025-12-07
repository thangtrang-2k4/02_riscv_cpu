`timescale 1ns/1ps
import rv32_pkg::*;   // ALUSel_t + enum ALU_* phải có trong package

module tb_alu;

  // ---------------- DUT IO ----------------
  logic [31:0] A, B;
  ALUSel_t     ALUSel;
  logic [31:0] alu;

  // ------------ Instantiate DUT -----------
  ALU dut (
    .A(A),
    .B(B),
    .ALUSel(ALUSel),
    .alu(alu)
  );

  // ---------------- Score -----------------
  integer n_pass = 0;
  integer n_fail = 0;
  integer n_total = 0;

  // --------- Coverage (đơn giản) ---------
  event sample_ev;  // <<< FIX #1: khai báo event

  // helper sign
  function automatic bit is_neg(input logic [31:0] x);
    return x[31];
  endfunction

  covergroup cg @(posedge sample_ev);
    cp_op   : coverpoint ALUSel {
               bins add   = {ALU_ADD};
               bins sub   = {ALU_SUB};
               bins slt   = {ALU_SLT};
               bins sltu  = {ALU_SLTU};
               bins band  = {ALU_AND};
               bins bor   = {ALU_OR};
               bins bxor  = {ALU_XOR};
               bins sll   = {ALU_SLL};
               bins srl   = {ALU_SRL};
               bins sra   = {ALU_SRA};
             }
    cp_shamt : coverpoint B[4:0] {
                 bins z   = {0};
                 bins one = {1};
                 bins big = {31};
                 bins mid[] = {[2:30]};
               }
    cp_A_sign : coverpoint is_neg(A);
    // Giữ coverage cơ bản, tránh cross + ignore phức tạp (gây lỗi ở tool cũ)
  endgroup

  cg cov = new();

  // ---------- Reference Model ------------
  function automatic logic [31:0] model_alu(
      input logic [31:0] A_i,
      input logic [31:0] B_i,
      input ALUSel_t     op_i
  );
    logic [31:0] y;
    logic [4:0]  shamt;
    shamt = B_i[4:0];

    unique case (op_i)
      ALU_ADD : y = A_i + B_i;
      ALU_SUB : y = A_i - B_i;

      ALU_SLT  : y = {31'b0, $signed(A_i) <  $signed(B_i)};
      ALU_SLTU : y = {31'b0, $unsigned(A_i) < $unsigned(B_i)};

      ALU_AND : y = A_i & B_i;
      ALU_OR  : y = A_i | B_i;
      ALU_XOR : y = A_i ^ B_i;

      ALU_SLL : y = A_i <<  shamt;
      ALU_SRL : y = $unsigned(A_i) >>  shamt;
      ALU_SRA : y = $signed(A_i)   >>> shamt;

      default : y = 32'd0;
    endcase
    return y;
  endfunction

  // helper: stringify enum cho log
  function automatic string op_name(ALUSel_t op);
    case (op)
      ALU_ADD:  return "ADD";
      ALU_SUB:  return "SUB";
      ALU_SLT:  return "SLT";
      ALU_SLTU: return "SLTU";
      ALU_AND:  return "AND";
      ALU_OR:   return "OR";
      ALU_XOR:  return "XOR";
      ALU_SLL:  return "SLL";
      ALU_SRL:  return "SRL";
      ALU_SRA:  return "SRA";
      default:  return "UNK";
    endcase
  endfunction

  // ------------- Check Task --------------
  task automatic run_case(
      input logic [31:0] A_i,
      input logic [31:0] B_i,
      input ALUSel_t     op_i,
      input string       tag = ""
  );
    logic [31:0] exp;
    // drive
    A      = A_i;
    B      = B_i;
    ALUSel = op_i;
    #1; // cho comb settle

    exp = model_alu(A_i, B_i, op_i);

    n_total++;
    -> sample_ev; // sample coverage

    if (alu !== exp) begin
      n_fail++;
      $error("[FAIL] %-10s op=%s A=0x%08h B=0x%08h | got=0x%08h exp=0x%08h (shamt=%0d)",
             tag, op_name(op_i), A_i, B_i, alu, exp, B_i[4:0]);
    end else begin
      n_pass++;
      //$display("[PASS] %-10s op=%s A=0x%08h B=0x%08h -> 0x%08h",
      //         tag, op_name(op_i), A_i, B_i, alu);
    end
  endtask

  // ------------- Directed Tests ----------
  task automatic run_directed();
    // Arithmetic
    run_case(32'h0000_0001, 32'h0000_0001, ALU_ADD,  "add_1+1");
    run_case(32'h7FFF_FFFF, 32'h0000_0001, ALU_ADD,  "add_wrap");
    run_case(32'h0000_0003, 32'h0000_0001, ALU_SUB,  "sub_3-1");
    run_case(32'h8000_0000, 32'h0000_0001, ALU_SUB,  "sub_wrap");

    // Compare signed vs unsigned
    run_case(32'hFFFF_FFFF, 32'h0000_0000, ALU_SLT,  "slt_-1<0");
    run_case(32'hFFFF_FFFF, 32'h0000_0000, ALU_SLTU, "sltu_-1<0");
    run_case(32'h8000_0000, 32'h7FFF_FFFF, ALU_SLT,  "slt_neg<pos");
    run_case(32'h7FFF_FFFF, 32'h8000_0000, ALU_SLTU, "sltu_pos<neg");

    // Logic
    run_case(32'hAAAA_AAAA, 32'h5555_5555, ALU_AND,  "and_alt");
    run_case(32'hAAAA_0000, 32'h0000_5555, ALU_OR,   "or_disj");
    run_case(32'hF0F0_1234, 32'h0FF0_00FF, ALU_XOR,  "xor_mix");

    // Shifts SLL
    run_case(32'h1234_5678, 32'h0000_0000, ALU_SLL,  "sll_0");
    run_case(32'h1234_5678, 32'h0000_0001, ALU_SLL,  "sll_1");
    run_case(32'h0000_0001, 32'h0000_001F, ALU_SLL,  "sll_31");
    run_case(32'h0000_0001, 32'h0000_0020, ALU_SLL,  "sll_32->0"); // mask

    // Shifts SRL
    run_case(32'h8000_0000, 32'h0000_0001, ALU_SRL,  "srl_high");
    run_case(32'hF000_000F, 32'h0000_0004, ALU_SRL,  "srl_4");
    run_case(32'hAAAA_AAAA, 32'h0000_001F, ALU_SRL,  "srl_31");
    run_case(32'hAAAA_AAAA, 32'h0000_003F, ALU_SRL,  "srl_63->31");

    // Shifts SRA
    run_case(32'h8000_0000, 32'h0000_0001, ALU_SRA,  "sra_sign1");
    run_case(32'h8000_0001, 32'h0000_001F, ALU_SRA,  "sra_31all1");
    run_case(32'h7FFF_FFFF, 32'h0000_0001, ALU_SRA,  "sra_pos");
    run_case(32'hFFFF_FFFF, 32'h0000_0004, ALU_SRA,  "sra_-1>>4");
  endtask

  // ------------- Random Tests ------------
  task automatic run_random(int N = 1000);
    for (int i = 0; i < N; i++) begin
      logic [31:0] Ar = $urandom();
      logic [31:0] Br = $urandom();
      ALUSel_t     op = ALUSel_t'($urandom_range(0, 9)); // 10 ops
      run_case(Ar, Br, op, $sformatf("rand_%0d", i));
    end
  endtask

  // --------------- Run All ---------------
  initial begin
    $display("=== ALU TB START ===");
    run_directed();
    run_random(2000);

    $display("=== SUMMARY === total=%0d pass=%0d fail=%0d", n_total, n_pass, n_fail);
    if (n_fail == 0) $display("ALL TESTS PASSED ✅");
    else             $error("TESTS FAILED ❌  (fail=%0d)", n_fail);
    #1 $finish;
  end

endmodule
