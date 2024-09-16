module hsv_core_decode_branch
  import hsv_core_pkg::*;
  import hsv_core_decode_pkg::*;
(
    input  word          insn,
    output branch_data_t branch_data,

    input  decode_common_t common_i,
    output common_data_t   common_o,
    output logic           illegal
);

  always_comb begin
    illegal = 0;
    common_o = 'x;

    branch_data = '0;
    branch_data.relative = 1;

    unique casez ({
      rv_major_op(insn), rv_funct3_op(insn)
    })
      // jal
      {
        RV_MAJOR_JAL, RvFunct3Any
      } : begin
        common_o = common_i.j_type;
        branch_data.link = 1;
        branch_data.unconditional = 1;
      end

      // jalr
      {
        RV_MAJOR_JALR, RvFunct3Null
      } : begin
        common_o = common_i.i_type;
        branch_data.link = 1;
        branch_data.relative = 0;
        branch_data.unconditional = 1;
      end

      // beq
      {
        RV_MAJOR_BRANCH, RvFunct3BranchBeq
      } : begin
        common_o = common_i.b_type;
        branch_data.cond = BRANCH_COND_EQUAL;
      end

      // bne
      {
        RV_MAJOR_BRANCH, RvFunct3BranchBne
      } : begin
        common_o = common_i.b_type;
        branch_data.cond = BRANCH_COND_EQUAL;
        branch_data.negate = 1;
      end

      // blt
      {
        RV_MAJOR_BRANCH, RvFunct3BranchBlt
      } : begin
        common_o = common_i.b_type;
        branch_data.cond = BRANCH_COND_LESS_THAN;
        branch_data.cond_signed = 1;
      end

      // bge
      {
        RV_MAJOR_BRANCH, RvFunct3BranchBge
      } : begin
        common_o = common_i.b_type;
        branch_data.cond = BRANCH_COND_LESS_THAN;
        branch_data.negate = 1;
        branch_data.cond_signed = 1;
      end

      // bltu
      {
        RV_MAJOR_BRANCH, RvFunct3BranchBltu
      } : begin
        common_o = common_i.b_type;
        branch_data.cond = BRANCH_COND_LESS_THAN;
      end

      // bgeu
      {
        RV_MAJOR_BRANCH, RvFunct3BranchBgeu
      } : begin
        common_o = common_i.b_type;
        branch_data.cond = BRANCH_COND_LESS_THAN;
        branch_data.negate = 1;
      end

      default: illegal = 1;
    endcase

    // Always predict the branch as not taken (the branch "target" is the next
    // instruction after the branch), even for unconditional JAL/JALR.
    // This has an impact on performance because branch mispredictions trigger
    // costly pipeline flushes. If you want to improve this, implement a proper
    // branch prediction algorithm here.
    branch_data.predicted = common_o.pc_increment;

    unique case (branch_data.cond)
      BRANCH_COND_EQUAL: branch_data.cond_signed = 'x;

      default: ;
    endcase

    if (branch_data.unconditional) begin
      branch_data.cond = branch_cond_t'('x);
      branch_data.negate = 'x;
      branch_data.cond_signed = 'x;
    end

    if (illegal) begin
      common_o = 'x;
      branch_data = 'x;
    end
  end

endmodule
