module Hazard_Detection (
  input  logic [31:0] inst_ID,   // instruction ở ID
  input  logic [31:0] inst_EX,   // instruction ở EX
  output logic        stall
);
  import rv32_pkg::*;

  logic use_rs1_ID, use_rs2_ID;
  always_comb begin
    unique case (opcode_t'(inst_ID[6:0]))
      OC_R      : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b1; end // R-type
      OC_S      : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b1; end // STORE
      OC_B      : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b1; end // BRANCH

      OC_I_ALU  : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b0; end // I-ALU
      OC_I_LOAD : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b0; end // LOAD (base rs1)
      OC_I_JALR : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b0; end // JALR

      OC_U_LUI  : begin use_rs1_ID = 1'b0; use_rs2_ID = 1'b0; end // LUI
      OC_U_AUIPC: begin use_rs1_ID = 1'b0; use_rs2_ID = 1'b0; end // AUIPC
      OC_J      : begin use_rs1_ID = 1'b0; use_rs2_ID = 1'b0; end // JAL

      default   : begin use_rs1_ID = 1'b1; use_rs2_ID = 1'b1; end // bảo thủ
    endcase
  end

  // ---- Điều kiện stall load-use chuẩn ----
  // Chỉ khi: EX là LOAD & rd_EX != x0 & ID thực sự đọc rs đụng rd_EX
  assign stall = (opcode_t'(inst_EX[6:0]) == OC_I_LOAD) &&
                 (inst_EX[11:7] != 5'd0) &&
                 ( (use_rs1_ID && (inst_EX[11:7] == inst_ID[19:15])) ||
                   (use_rs2_ID && (inst_EX[11:7] == inst_ID[24:20])) );

endmodule
