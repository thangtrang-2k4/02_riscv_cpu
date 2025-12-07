module ALU (
  input  logic [31:0]               A,
  input  logic [31:0]               B,
  input  rv32_pkg::ALUSel_t         ALUSel,
  output logic [31:0]               alu
);
  import rv32_pkg::*;

  logic [4:0] shamt;                 // chỉ lấy 5 bit thấp như RV32I
  assign shamt = B[4:0];

  always_comb begin
    alu = 32'd0;                     // giá trị mặc định an toàn
    unique case (ALUSel)
      ALU_ADD : alu = A + B;
      ALU_SUB : alu = A - B;

      ALU_SLT  : alu = {31'b0, $signed(A) <  $signed(B)};   // signed compare
      ALU_SLTU : alu = {31'b0, $unsigned(A) < $unsigned(B)}; // unsigned compare

      ALU_AND : alu = A & B;
      ALU_OR  : alu = A | B;
      ALU_XOR : alu = A ^ B;

      ALU_SLL : alu = A <<  shamt;
      ALU_SRL : alu = $unsigned(A) >>  shamt;  // logical right
      ALU_SRA : alu = $signed(A)   >>> shamt;  // arithmetic right

      ALU_LUI : alu = B;

      ALU_JALR : alu = (A + B) & 32'hFFFF_FFFE;
      
      default :  alu = 32'd0;

    endcase
  end
endmodule
