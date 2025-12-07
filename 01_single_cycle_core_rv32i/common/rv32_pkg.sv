package rv32_pkg;

  //Immediate Generator Select
  typedef enum logic [2:0] {
    Imm_I = 3'b000,
    Imm_S = 3'b001,
    Imm_B = 3'b010,
    Imm_U = 3'b011,
    Imm_J = 3'b100
  }ImmSel_t;

  // ALU Select
  typedef enum logic [3:0] {
    ALU_ADD  = 4'b0000,   // rs1 + rs2
    ALU_SUB  = 4'b0001,   // rs1 - rs2
    ALU_SLT  = 4'b0010,   // signed less-than
    ALU_SLTU = 4'b0011,   // unsigned less-than

    ALU_AND  = 4'b0100,   // bitwise AND
    ALU_OR   = 4'b0101,   // bitwise OR
    ALU_XOR  = 4'b0110,   // bitwise XOR

    ALU_SLL  = 4'b0111,   // shift left logical
    ALU_SRL  = 4'b1000,   // shift right logical
    ALU_SRA  = 4'b1001,   // shift right arithmetic

    ALU_LUI  = 4'b1010
  } ALUSel_t;

  //PCSel 
  typedef enum logic {
    PC_PC4 = 1'b0,
    PC_ALU = 1'b1
  } PCSel_t;

  // Write Back Select
  typedef enum logic [1:0] {
    WB_PC4 = 2'b10,
    WB_ALU  = 2'b01,
    WB_MEM  = 2'b00
  } WBSel_t;

  // Opcode 
  typedef enum logic [6:0] {
    OC_R         = 7'b0110011,
    OC_I_ALU     = 7'b0010011,
    OC_I_LOAD    = 7'b0000011,
    OC_S         =  7'b0100011,
    OC_B         = 7'b1100011,
    OC_U_LUI     = 7'b0110111,
    OC_U_AUIPC   = 7'b0010111,
    OC_J         = 7'b1101111,
    OC_I_JALR    = 7'b1100111
  } opcode_t;

  //Funct 3
  typedef logic [2:0] funct3_t;

  // R-type
  localparam logic [2:0]
    F3_ADD_SUB  = 3'b000,
    F3_SLL      = 3'b001,
    F3_SLT      = 3'b010,
    F3_SLTU     = 3'b011,
    F3_XOR      = 3'b100,
    F3_SRL_SRA  = 3'b101,
    F3_OR       = 3'b110,
    F3_AND      = 3'b111;

  // I-type ALU
  localparam logic [2:0]
    F3_ADDI       = 3'b000,
    F3_SLTI       = 3'b010,
    F3_SLTIU      = 3'b011,
    F3_XORI       = 3'b100,
    F3_ORI        = 3'b110,
    F3_ANDI       = 3'b111,
    F3_SLLI       = 3'b001,
    F3_SRLI_SRAI  = 3'b101;

  // LOAD / STORE (cùng mã 010)
  localparam logic [2:0]
    F3_LSW = 3'b010;

  // B-type
  localparam logic [2:0]
    F3_BEQ   = 3'b000,
    F3_BNE   = 3'b001,
    F3_BLT   = 3'b100,
    F3_BGE   = 3'b101,
    F3_BLTU  = 3'b110,
    F3_BGEU  = 3'b111;

endpackage
