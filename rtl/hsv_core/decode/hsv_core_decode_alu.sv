module hsv_core_decode_alu
  import hsv_core_pkg::*;
  import hsv_core_decode_pkg::*;
(
    input  word       insn,
    output alu_data_t alu_data,

    input  decode_common_t common_i,
    output common_data_t   common_o,
    output logic           illegal
);

  logic op_imm;

  always_comb begin
    op_imm   = 'x;
    common_o = 'x;

    unique case (rv_major_op(
        insn
    ))
      RV_MAJOR_LUI, RV_MAJOR_AUIPC: common_o = common_i.u_type;

      RV_MAJOR_OP: begin
        op_imm   = 0;
        common_o = common_i.r_type;
      end

      RV_MAJOR_OP_IMM: begin
        op_imm = 1;

        unique case (rv_funct3_op(
            insn
        ))
          RvFunct3OpSll, RvFunct3OpSrlSra: common_o = common_i.r_type;

          default: common_o = common_i.i_type;
        endcase
      end

      default: ;
    endcase

    illegal  = 0;
    alu_data = '0;

    unique case (rv_major_op(
        insn
    ))
      // lui
      RV_MAJOR_LUI: begin
        alu_data.is_immediate = 1;
        alu_data.out_select = ALU_OUT_ADDER;

        common_o.rs1_addr = '0;
        common_o.rs2_addr = '0;
      end

      // auipc
      RV_MAJOR_AUIPC: begin
        alu_data.is_immediate = 1;
        alu_data.out_select = ALU_OUT_ADDER;
        alu_data.pc_relative = 1;

        common_o.rs1_addr = '0;
        common_o.rs2_addr = '0;
      end

      RV_MAJOR_OP, RV_MAJOR_OP_IMM: begin
        unique casez ({
          rv_funct3_op(insn), op_imm, rv_funct7_op(insn)
        })
          // add/addi
          {
            RvFunct3OpAddSub, 1'b0, RvFunct7Null
          }, {
            RvFunct3OpAddSub, 1'b1, RvFunct7Any
          } :
          alu_data.out_select = ALU_OUT_ADDER;

          // sub
          // N.B. there's no such thing as "subi"
          {
            RvFunct3OpAddSub, 1'b0, RvFunct7OpSubSra
          } : begin
            alu_data.out_select = ALU_OUT_ADDER;
            alu_data.negate     = 1;
          end

          // and/andi
          {
            RvFunct3OpAnd, 1'b0, RvFunct7Null
          }, {
            RvFunct3OpAnd, 1'b1, RvFunct7Any
          } : begin
            alu_data.out_select     = ALU_OUT_SHIFT;
            alu_data.bitwise_select = ALU_BITWISE_AND;
          end

          // or/ori
          {
            RvFunct3OpOr, 1'b0, RvFunct7Null
          }, {
            RvFunct3OpOr, 1'b1, RvFunct7Any
          } : begin
            alu_data.out_select     = ALU_OUT_SHIFT;
            alu_data.bitwise_select = ALU_BITWISE_OR;
          end

          // xor/xori
          {
            RvFunct3OpXor, 1'b0, RvFunct7Null
          }, {
            RvFunct3OpXor, 1'b1, RvFunct7Any
          } : begin
            alu_data.out_select     = ALU_OUT_SHIFT;
            alu_data.bitwise_select = ALU_BITWISE_XOR;
          end

          // sll/slli
          {
            RvFunct3OpSll, 1'b?, RvFunct7Null
          } : begin
            alu_data.out_select     = ALU_OUT_SHIFT;
            alu_data.bitwise_select = ALU_BITWISE_PASS;
            alu_data.negate         = 1;

            if (op_imm) common_o.immediate = word'(common_o.rs2_addr);
          end

          // srl/srli
          {
            RvFunct3OpSrlSra, 1'b?, RvFunct7Null
          } : begin
            alu_data.out_select     = ALU_OUT_SHIFT;
            alu_data.bitwise_select = ALU_BITWISE_PASS;

            if (op_imm) common_o.immediate = word'(common_o.rs2_addr);
          end

          // sra/srai
          {
            RvFunct3OpSrlSra, 1'b?, RvFunct7OpSubSra
          } : begin
            alu_data.out_select     = ALU_OUT_SHIFT;
            alu_data.bitwise_select = ALU_BITWISE_PASS;
            alu_data.sign_extend    = 1;

            if (op_imm) common_o.immediate = word'(common_o.rs2_addr);
          end

          // slt/slti
          {
            RvFunct3OpSlt, 1'b0, RvFunct7Null
          }, {
            RvFunct3OpSlt, 1'b1, RvFunct7Any
          } : begin
            alu_data.out_select = ALU_OUT_ADDER;
            alu_data.negate     = 1;
            alu_data.flip_signs = 1;
            alu_data.compare    = 1;
          end

          // sltu/sltiu
          {
            RvFunct3OpSltu, 1'b0, RvFunct7Null
          }, {
            RvFunct3OpSltu, 1'b1, RvFunct7Any
          } : begin
            alu_data.out_select = ALU_OUT_ADDER;
            alu_data.negate     = 1;
            alu_data.compare    = 1;
          end

          default: illegal = 1;
        endcase

        alu_data.is_immediate = op_imm;
        if (op_imm) common_o.rs2_addr = '0;
      end

      default: illegal = 1;
    endcase

    // 'x enables important synthesis optimizations, at the cost of
    // undefined behavior in case of design errors. Under synthesis,
    // 'x means "don't care"
    unique case (alu_data.out_select)
      ALU_OUT_ADDER: begin
        alu_data.bitwise_select = alu_bitwise_t'('x);
        alu_data.sign_extend    = 'x;
      end

      ALU_OUT_SHIFT: begin
        alu_data.flip_signs  = 'x;
        alu_data.compare     = 'x;
        alu_data.pc_relative = 'x;

        unique case (alu_data.bitwise_select)
          ALU_BITWISE_PASS: if (alu_data.negate) alu_data.sign_extend = 'x;

          default: begin
            alu_data.sign_extend = 'x;
            alu_data.negate      = 'x;
          end
        endcase
      end

      default: ;
    endcase

    if (illegal) begin
      alu_data = 'x;
      common_o = 'x;
    end
  end

endmodule
