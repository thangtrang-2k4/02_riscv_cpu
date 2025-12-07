`timescale 1ns/1ps

module tb_forwarding_unit;

  import rv32_pkg::*;

  logic             RegWEn_MEM;
  logic             RegWEn_WB;
  logic             MemRW_MEM;
  WBSel_t           WBSel_MEM;
  logic [31:0]      inst_EX;
  logic [31:0]      inst_MEM;
  logic [31:0]      inst_WB;
  logic [1:0]       forwardA;
  logic [1:0]       forwardB;

  // DUT
  Forwarding_Unit dut (
    .RegWEn_MEM,
    .RegWEn_WB,
    .MemRW_MEM,
    .WBSel_MEM,
    .inst_EX,
    .inst_MEM,
    .inst_WB,
    .forwardA,
    .forwardB
  );

  // ===== Hàm tạo lệnh RISC-V R-type thật =====
  function automatic logic [31:0] make_add(input logic [4:0] rd,
                                           input logic [4:0] rs1,
                                           input logic [4:0] rs2);
    // add rd, rs1, rs2
    return {7'b0000000, rs2, rs1, 3'b000, rd, 7'b0110011};
  endfunction

  // Task apply 1 test case
  task automatic apply_case(
    input string name,
    input logic RegWEn_MEM_i,
    input logic RegWEn_WB_i,
    input WBSel_t WBSel_MEM_i,
    input logic [4:0] rs1_EX, rs2_EX,
    input logic [4:0] rd_MEM_i,
    input logic [4:0] rd_WB_i
  );
    begin
      RegWEn_MEM = RegWEn_MEM_i;
      RegWEn_WB  = RegWEn_WB_i;
      WBSel_MEM  = WBSel_MEM_i;
      MemRW_MEM  = 1'b0; // không dùng trong logic này

      // Lệnh đang ở EX, MEM, WB
      inst_EX  = make_add(5'd10, rs1_EX, rs2_EX);   // rd_EX tùy, không ảnh hưởng
      inst_MEM = make_add(rd_MEM_i, 5'd0,  5'd0 );
      inst_WB  = make_add(rd_WB_i , 5'd0,  5'd0 );

      #1; // cho mạch tổ hợp ổn định

      $display("[%s] rs1=%0d rs2=%0d rd_MEM=%0d rd_WB=%0d -> fA=%b fB=%b",
               name, rs1_EX, rs2_EX, rd_MEM_i, rd_WB_i, forwardA, forwardB);
    end
  endtask

  initial begin
    $display("=== TEST FORWARDING UNIT (USING REAL ADD INSTRUCTIONS) ===");

    // TC1: Không có forwarding (2'b00)
    apply_case("No forwarding",
               0, 0, WB_ALU,
               5'd1, 5'd2,
               5'd0, 5'd0);

    // TC2: ForwardA = 2'b10 (EX/MEM)  -> trường hợp 1 trong báo cáo
    apply_case("ForwardA from EX/MEM",
               1, 0, WB_ALU,
               5'd3, 5'd0,   // rs1_EX = 3
               5'd3, 5'd0);  // rd_MEM = 3

    // TC3: ForwardA = 2'b01 (MEM/WB)  -> trường hợp 2 trong báo cáo
    apply_case("ForwardA from MEM/WB",
               0, 1, WB_ALU,
               5'd4, 5'd0,   // rs1_EX = 4
               5'd0, 5'd4);  // rd_WB  = 4

    // TC4: ForwardB = 2'b10 (EX/MEM)
    apply_case("ForwardB from EX/MEM",
               1, 0, WB_ALU,
               5'd0, 5'd5,   // rs2_EX = 5
               5'd5, 5'd0);

    // TC5: ForwardB = 2'b01 (MEM/WB)
    apply_case("ForwardB from MEM/WB",
               0, 1, WB_ALU,
               5'd0, 5'd6,
               5'd0, 5'd6);

    // TC6: Cả EX/MEM và MEM/WB cùng match -> phải ưu tiên EX/MEM (2'b10)
    apply_case("Priority EX/MEM over MEM/WB (A & B)",
               1, 1, WB_ALU,
               5'd7, 5'd8,
               5'd7, 5'd7);

    // TC7: rd_MEM = x0 -> không được forward
    apply_case("rd_MEM = x0 must not forward",
               1, 0, WB_ALU,
               5'd9, 5'd0,
               5'd0, 5'd0);

    // TC8: WBSel_MEM != WB_ALU -> không allow_exmem_fwd
    apply_case("WBSel_MEM != WB_ALU -> no EX/MEM forward",
               1, 0, WB_MEM,  // WB_MEM, WB_PC4, v.v.
               5'd10, 5'd0,
               5'd10, 5'd0);

    $display("=== DONE ===");
    #10 $finish;
  end

endmodule
