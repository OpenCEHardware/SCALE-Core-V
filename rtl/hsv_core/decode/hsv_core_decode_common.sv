module hsv_core_decode_common
  import hsv_core_pkg::*;
  import hsv_core_decode_pkg::*;
(
    input  fetch_data_t    fetch_data,
    output decode_common_t common
);

  common_data_t baseline;

  always_comb begin
    baseline.pc = fetch_data.pc;
    baseline.pc_increment = fetch_data.pc_increment;

    baseline.rd_addr = rv_rd(fetch_data.insn);
    baseline.rs1_addr = rv_rs1(fetch_data.insn);
    baseline.rs2_addr = rv_rs2(fetch_data.insn);

    common.r_type = baseline;
    common.r_type.immediate = rv_r_type_immediate(fetch_data.insn);

    common.i_type = baseline;
    common.i_type.rs2_addr = '0;
    common.i_type.immediate = rv_i_type_immediate(fetch_data.insn);

    common.s_type = baseline;
    common.s_type.rd_addr = '0;
    common.s_type.immediate = rv_s_type_immediate(fetch_data.insn);

    common.b_type = baseline;
    common.b_type.rd_addr = '0;
    common.b_type.immediate = rv_b_type_immediate(fetch_data.insn);

    common.u_type = baseline;
    common.u_type.rs1_addr = '0;
    common.u_type.rs2_addr = '0;
    common.u_type.immediate = rv_u_type_immediate(fetch_data.insn);

    common.j_type = baseline;
    common.j_type.rs1_addr = '0;
    common.j_type.rs2_addr = '0;
    common.j_type.immediate = rv_j_type_immediate(fetch_data.insn);
  end

endmodule
