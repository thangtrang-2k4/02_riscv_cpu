//`timescale 1ns/1ps
//
//module tb_hazard_detection;
//
//  import rv32_pkg::*;
//
//  logic [31:0] inst_ID;
//  logic [31:0] inst_EX;
//  logic        stall;
//
//  //================ DUT ==================
//  Hazard_Detection dut (
//    .inst_ID(inst_ID),
//    .inst_EX(inst_EX),
//    .stall (stall)
//  );
//
//  //============== Helper functions ==============
//  // chỉ cần đúng opcode + vị trí rs1, rs2, rd là đủ
//
//  // I-type LOAD: lw rd, imm(rs1)
//  function automatic logic [31:0] make_load(input logic [4:0] rd,
//                                            input logic [4:0] rs1);
//    logic [31:0] inst;
//    inst        = '0;
//    inst[6:0]   = OC_I_LOAD;   // opcode LOAD
//    inst[11:7]  = rd;          // rd
//    inst[19:15] = rs1;         // base rs1
//    // imm[31:20], funct3 không ảnh hưởng tới hazard
//    return inst;
//  endfunction
//
//  // I-type ALU: addi rd, rs1, imm
//  function automatic logic [31:0] make_i_alu(input logic [4:0] rd,
//                                             input logic [4:0] rs1);
//    logic [31:0] inst;
//    inst        = '0;
//    inst[6:0]   = OC_I_ALU;
//    inst[11:7]  = rd;
//    inst[19:15] = rs1;
//    return inst;
//  endfunction
//
//  // R-type: dùng cho các lệnh cần cả rs1 & rs2 (ADD, SUB, ...)
//  function automatic logic [31:0] make_r_type(input logic [4:0] rd,
//                                              input logic [4:0] rs1,
//                                              input logic [4:0] rs2);
//    logic [31:0] inst;
//    inst        = '0;
//    inst[6:0]   = OC_R;      // R-type
//    inst[11:7]  = rd;
//    inst[19:15] = rs1;
//    inst[24:20] = rs2;
//    return inst;
//  endfunction
//
//  // LUI – không dùng rs1, rs2 (use_rs1=0, use_rs2=0)
//  function automatic logic [31:0] make_lui(input logic [4:0] rd);
//    logic [31:0] inst;
//    inst       = '0;
//    inst[6:0]  = OC_U_LUI;
//    inst[11:7] = rd;
//    return inst;
//  endfunction
//
//  //============== Task áp dụng 1 test case ==============
//  task automatic apply_case(
//    input string name,
//    input logic [31:0] ex_inst,
//    input logic [31:0] id_inst
//  );
//    begin
//      inst_EX = ex_inst;
//      inst_ID = id_inst;
//      #1; // cho mạch tổ hợp ổn định
//      $display("[%s] opcode_EX=%b rd_EX=%0d rs1_ID=%0d rs2_ID=%0d -> stall=%0b",
//               name,
//               inst_EX[6:0],
//               inst_EX[11:7],
//               inst_ID[19:15],
//               inst_ID[24:20],
//               stall);
//    end
//  endtask
//
//  //================== TEST =====================
//  initial begin
//    $display("=== TEST HAZARD DETECTION (LOAD-USE) ===");
//
//    // TC1: EX là LOAD, rd_EX != 0, lệnh ID dùng rs1 = rd_EX -> phải stall
//    // tương ứng dòng: OC_I_LOAD, rd≠0, use_rs1=1,use_rs2=0 -> stall=1
//    apply_case("TC1: LOAD-USE via rs1",
//               make_load(5'd5, 5'd1),      // EX: lw x5, 0(x1)
//               make_i_alu(5'd2, 5'd5));    // ID: addi x2, x5, imm
//
//    // TC2: EX là LOAD, rd_EX != 0, lệnh ID dùng rs2 = rd_EX -> stall
//    // dùng R-type với rs2=rd_EX (use_rs2_ID=1)
//    apply_case("TC2: LOAD-USE via rs2",
//               make_load(5'd6, 5'd1),             // EX: lw x6, 0(x1)
//               make_r_type(5'd3, 5'd0, 5'd6));    // ID: add x3, x0, x6
//
//    // TC3: EX là LOAD, rd_EX != 0, ID dùng cả rs1 & rs2 trùng/1 trong 2 trùng -> stall
//    // (use_rs1_ID=1, use_rs2_ID=1)
//    apply_case("TC3: LOAD-USE via rs1 & rs2 (R-type)",
//               make_load(5'd7, 5'd1),             // EX: lw x7, 0(x1)
//               make_r_type(5'd4, 5'd7, 5'd8));    // ID: add x4, x7, x8
//
//    // TC4: EX là LOAD nhưng rd_EX = x0 -> KHÔNG stall
//    apply_case("TC4: LOAD rd=x0 must NOT stall",
//               make_load(5'd0, 5'd1),             // EX: lw x0, 0(x1) (vô nghĩa)
//               make_i_alu(5'd2, 5'd0));           // ID: addi x2, x0, imm
//
//    // TC5: EX là LOAD, rd_EX!=0 nhưng ID là LUI/JAL (không dùng rs) -> KHÔNG stall
//    // tương ứng dòng: OC_I_LOAD, rd≠0, use_rs1=0,use_rs2=0 -> stall=0
//    apply_case("TC5: Following instr does NOT use rs -> no stall",
//               make_load(5'd5, 5'd1),             // EX: lw x5, 0(x1)
//               make_lui(5'd10));                  // ID: lui x10, imm
//
//    // TC6: EX KHÔNG phải LOAD (R-type) -> luôn stall=0 dù ID phụ thuộc hay không
//    apply_case("TC6: EX not LOAD -> no stall even with dependency",
//               make_r_type(5'd5, 5'd1, 5'd2),     // EX: add x5, x1, x2
//               make_i_alu(5'd3, 5'd5));           // ID: addi x3, x5, imm
//
//    $display("=== DONE ===");
//    #10 $finish;
//  end
//
//endmodule


`timescale 1ns/1ps

module tb_hazard_detection;

  import rv32_pkg::*;

  logic [31:0] inst_ID;
  logic [31:0] inst_EX;
  logic        stall;

  //========= CÁC TÍN HIỆU GIẢI THÍCH THÊM TRÊN WAVE =========
  opcode_t     opcode_EX;          // opcode của lệnh EX
  logic [4:0]  rd_EX;              // rd của lệnh EX
  logic [4:0]  rs1_ID, rs2_ID;     // rs1, rs2 của lệnh ID
  logic        use_rs1_ID;         // ID có thực sự dùng rs1?
  logic        use_rs2_ID;         // ID có thực sự dùng rs2?

  //================ DUT ==================
  Hazard_Detection dut (
    .inst_ID(inst_ID),
    .inst_EX(inst_EX),
    .stall  (stall)
  );

  //=========== GIẢI MÃ PHỤ ĐỂ QUAN SÁT TRÊN WAVE ============
  always_comb begin
    // decode các trường cơ bản
    opcode_EX = opcode_t'(inst_EX[6:0]);
    rd_EX     = inst_EX[11:7];

    rs1_ID    = inst_ID[19:15];
    rs2_ID    = inst_ID[24:20];

    // decode use_rs1_ID / use_rs2_ID giống trong Hazard_Detection
    unique case (opcode_t'(inst_ID[6:0]))
      OC_R, OC_S, OC_B: begin
        use_rs1_ID = 1'b1;
        use_rs2_ID = 1'b1;
      end

      OC_I_ALU, OC_I_LOAD: begin
        use_rs1_ID = 1'b1;
        use_rs2_ID = 1'b0;
      end

      default: begin
        use_rs1_ID = 1'b0;
        use_rs2_ID = 1'b0;
      end
    endcase
  end

  //============== Helper functions ==============
  // chỉ cần đúng opcode + vị trí rs1, rs2, rd là đủ

  // I-type LOAD: lw rd, imm(rs1)
  function automatic logic [31:0] make_load(input logic [4:0] rd,
                                            input logic [4:0] rs1);
    logic [31:0] inst;
    inst        = '0;
    inst[6:0]   = OC_I_LOAD;   // opcode LOAD
    inst[11:7]  = rd;          // rd
    inst[19:15] = rs1;         // base rs1
    return inst;
  endfunction

  // I-type ALU: addi rd, rs1, imm
  function automatic logic [31:0] make_i_alu(input logic [4:0] rd,
                                             input logic [4:0] rs1);
    logic [31:0] inst;
    inst        = '0;
    inst[6:0]   = OC_I_ALU;
    inst[11:7]  = rd;
    inst[19:15] = rs1;
    return inst;
  endfunction

  // R-type: dùng cho các lệnh cần cả rs1 & rs2 (ADD, SUB, ...)
  function automatic logic [31:0] make_r_type(input logic [4:0] rd,
                                              input logic [4:0] rs1,
                                              input logic [4:0] rs2);
    logic [31:0] inst;
    inst        = '0;
    inst[6:0]   = OC_R;      // R-type
    inst[11:7]  = rd;
    inst[19:15] = rs1;
    inst[24:20] = rs2;
    return inst;
  endfunction

  // LUI – không dùng rs1, rs2 (use_rs1=0, use_rs2=0)
  function automatic logic [31:0] make_lui(input logic [4:0] rd);
    logic [31:0] inst;
    inst       = '0;
    inst[6:0]  = OC_U_LUI;
    inst[11:7] = rd;
    return inst;
  endfunction

  //============== Task áp dụng 1 test case ==============
  task automatic apply_case(
    input string        name,
    input logic [31:0]  ex_inst,
    input logic [31:0]  id_inst
  );
    begin
      inst_EX = ex_inst;
      inst_ID = id_inst;
      #1; // cho mạch tổ hợp ổn định
      $display("[%s] opcode_EX=%b rd_EX=%0d rs1_ID=%0d rs2_ID=%0d -> stall=%0b",
               name,
               inst_EX[6:0],
               inst_EX[11:7],
               inst_ID[19:15],
               inst_ID[24:20],
               stall);
    end
  endtask

  //================== TEST =====================
  initial begin
    $display("=== TEST HAZARD DETECTION (LOAD-USE) ===");

    // TC1: EX là LOAD, rd_EX != 0, lệnh ID dùng rs1 = rd_EX -> phải stall
    apply_case("TC1: LOAD-USE via rs1",
               make_load(5'd5, 5'd1),
               make_i_alu(5'd2, 5'd5));

    // TC2: EX là LOAD, rd_EX != 0, lệnh ID dùng rs2 = rd_EX -> stall
    apply_case("TC2: LOAD-USE via rs2",
               make_load(5'd6, 5'd1),
               make_r_type(5'd3, 5'd0, 5'd6));

    // TC3: EX là LOAD, rd_EX != 0, ID dùng cả rs1 & rs2 trùng/1 trong 2 -> stall
    apply_case("TC3: LOAD-USE via rs1 &/or rs2",
               make_load(5'd7, 5'd1),
               make_r_type(5'd4, 5'd7, 5'd8));

    // TC4: EX là LOAD nhưng rd_EX = x0 -> KHÔNG stall
    apply_case("TC4: LOAD rd=x0 must NOT stall",
               make_load(5'd0, 5'd1),
               make_i_alu(5'd2, 5'd0));

    // TC5: EX là LOAD, rd_EX!=0 nhưng ID là LUI (không dùng rs) -> KHÔNG stall
    apply_case("TC5: Following instr does NOT use rs -> no stall",
               make_load(5'd5, 5'd1),
               make_lui(5'd10));

    // TC6: EX KHÔNG phải LOAD (R-type) -> luôn stall=0 dù ID phụ thuộc
    apply_case("TC6: EX not LOAD -> no stall even with dependency",
               make_r_type(5'd5, 5'd1, 5'd2),
               make_i_alu(5'd3, 5'd5));

    $display("=== DONE ===");
    #10 $finish;
  end

endmodule
