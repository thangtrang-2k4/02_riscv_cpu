module ImmGen (
               input  logic [24:0] inst,
               input  rv32_pkg::ImmSel_t ImmSel,
               output logic [31:0] imm
              );
   import rv32_pkg::*;

   always_comb begin
      case(ImmSel)
         Imm_I : imm = { {20{inst[24]}}, inst[24:13] };
         Imm_S : imm = { {20{inst[24]}}, inst[24:18], inst[4:0] };
         Imm_B : imm = { {19{inst[24]}}, inst[24], inst[0], inst[23:18], inst[4:1], 1'b0 };
         Imm_U : imm = { inst[24:5], 12'b0 };
         Imm_J : imm = { {11{inst[24]}}, inst[24], inst[12:5], inst[13], inst[23:14], 1'b0 };
         default: imm = 32'b0;
      endcase
   end
endmodule
