package hsv_core_decode_pkg;

  import hsv_core_pkg::*;

  typedef struct packed {
    common_data_t r_type;
    common_data_t i_type;
    common_data_t s_type;
    common_data_t b_type;
    common_data_t u_type;
    common_data_t j_type;
  } decode_common_t;

  typedef enum logic [6:0] {
    RV_MAJOR_LOAD      = 7'b00_000_11,
    RV_MAJOR_LOAD_FP   = 7'b00_001_11,
    RV_MAJOR_CUSTOM_0  = 7'b00_010_11,
    RV_MAJOR_MISC_MEM  = 7'b00_011_11,
    RV_MAJOR_OP_IMM    = 7'b00_100_11,
    RV_MAJOR_AUIPC     = 7'b00_101_11,
    RV_MAJOR_OP_IMM_32 = 7'b00_110_11,
    RV_MAJOR_STORE     = 7'b01_000_11,
    RV_MAJOR_STORE_FP  = 7'b01_001_11,
    RV_MAJOR_CUSTOM_1  = 7'b01_010_11,
    RV_MAJOR_AMO       = 7'b01_011_11,
    RV_MAJOR_OP        = 7'b01_100_11,
    RV_MAJOR_LUI       = 7'b01_101_11,
    RV_MAJOR_OP_32     = 7'b01_110_11,
    RV_MAJOR_MADD      = 7'b10_000_11,
    RV_MAJOR_MSUB      = 7'b10_001_11,
    RV_MAJOR_NMSUB     = 7'b10_010_11,
    RV_MAJOR_NMADD     = 7'b10_011_11,
    RV_MAJOR_OP_FP     = 7'b10_100_11,
    RV_MAJOR_OP_V      = 7'b10_101_11,
    RV_MAJOR_CUSTOM_2  = 7'b10_110_11,
    RV_MAJOR_BRANCH    = 7'b11_000_11,
    RV_MAJOR_JALR      = 7'b11_001_11,
    RV_MAJOR_JAL       = 7'b11_011_11,
    RV_MAJOR_SYSTEM    = 7'b11_100_11,
    RV_MAJOR_OP_VE     = 7'b11_101_11,
    RV_MAJOR_CUSTOM_3  = 7'b11_110_11
  } rv_major_opcode_t;

  typedef logic [2:0] rv_funct3;

  localparam rv_funct3 RvFunct3Any = 3'b???;
  localparam rv_funct3 RvFunct3Null = 3'b000;

  localparam rv_funct3 RvFunct3OpAddSub = 3'b000;
  localparam rv_funct3 RvFunct3OpSll = 3'b001;
  localparam rv_funct3 RvFunct3OpSlt = 3'b010;
  localparam rv_funct3 RvFunct3OpSltu = 3'b011;
  localparam rv_funct3 RvFunct3OpXor = 3'b100;
  localparam rv_funct3 RvFunct3OpSrlSra = 3'b101;
  localparam rv_funct3 RvFunct3OpOr = 3'b110;
  localparam rv_funct3 RvFunct3OpAnd = 3'b111;

  localparam rv_funct3 RvFunct3LoadStoreByteSigned = 3'b000;
  localparam rv_funct3 RvFunct3LoadStoreHalfSigned = 3'b001;
  localparam rv_funct3 RvFunct3LoadStoreWord = 3'b010;
  localparam rv_funct3 RvFunct3LoadStoreByteUnsigned = 3'b100;
  localparam rv_funct3 RvFunct3LoadStoreHalfUnsigned = 3'b101;

  localparam rv_funct3 RvFunct3BranchBeq = 3'b000;
  localparam rv_funct3 RvFunct3BranchBne = 3'b001;
  localparam rv_funct3 RvFunct3BranchBlt = 3'b100;
  localparam rv_funct3 RvFunct3BranchBge = 3'b101;
  localparam rv_funct3 RvFunct3BranchBltu = 3'b110;
  localparam rv_funct3 RvFunct3BranchBgeu = 3'b111;

  localparam rv_funct3 RvFunct3SystemCsrrw = 3'b001;
  localparam rv_funct3 RvFunct3SystemCsrrs = 3'b010;
  localparam rv_funct3 RvFunct3SystemCsrrc = 3'b011;
  localparam rv_funct3 RvFunct3SystemCsrrwi = 3'b101;
  localparam rv_funct3 RvFunct3SystemCsrrsi = 3'b110;
  localparam rv_funct3 RvFunct3SystemCsrrci = 3'b111;

  typedef logic [6:0] rv_funct7;

  localparam rv_funct7 RvFunct7Any = 7'b???????;
  localparam rv_funct7 RvFunct7Null = 7'b0000000;

  localparam rv_funct7 RvFunct7OpSubSra = 7'b0100000;

  function automatic rv_major_opcode_t rv_major_op(word insn);
    return rv_major_opcode_t'(insn[6:0]);
  endfunction

  function automatic rv_funct3 rv_funct3_op(word insn);
    return insn[14:12];
  endfunction

  function automatic rv_funct7 rv_funct7_op(word insn);
    return insn[31:25];
  endfunction

  function automatic reg_addr rv_rd(word insn);
    return insn[11:7];
  endfunction

  function automatic reg_addr rv_rs1(word insn);
    return insn[19:15];
  endfunction

  function automatic reg_addr rv_rs2(word insn);
    return insn[24:20];
  endfunction

  function automatic word rv_r_type_immediate(word insn);
    return 'x;
  endfunction

  function automatic word rv_i_type_immediate(word insn);
    return {{20{insn[31]}}, insn[31:20]};
  endfunction

  function automatic word rv_s_type_immediate(word insn);
    return {{20{insn[31]}}, insn[31:25], insn[11:7]};
  endfunction


  function automatic word rv_b_type_immediate(word insn);
    return {{19{insn[31]}}, insn[31], insn[7], insn[30:25], insn[11:8], 1'b0};
  endfunction

  function automatic word rv_u_type_immediate(word insn);
    return {insn[31:12], 12'd0};
  endfunction

  function automatic word rv_j_type_immediate(word insn);
    return {{11{insn[31]}}, insn[31], insn[19:12], insn[20], insn[30:21], 1'b0};
  endfunction

endpackage
