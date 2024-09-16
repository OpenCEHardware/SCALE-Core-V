module hsv_core_decode
  import hsv_core_pkg::*;
  import hsv_core_decode_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    input  logic flush_req,
    output logic flush_ack,

    output logic        ready_o,
    input  logic        valid_i,
    input  fetch_data_t fetch_data,

    input  logic        ready_i,
    output logic        valid_o,
    output issue_data_t issue_data
);

  word insn;
  logic illegal, stall, out_ready, out_valid;
  issue_data_t  out;
  exec_select_t exec_select;

  logic illegal_alu, illegal_foo, illegal_mem, illegal_branch, illegal_ctrlstatus;
  alu_data_t alu_data, alu_data_or_trap;
  foo_data_t foo_data;
  mem_data_t mem_data;
  branch_data_t branch_data;
  ctrlstatus_data_t ctrlstatus_data;

  common_data_t common_alu, common_foo, common_mem, common_branch, common_ctrlstatus;
  common_data_t   common_final;
  decode_common_t common;

  assign stall = ~out_ready;
  assign ready_o = ~stall;

  assign insn = fetch_data.insn;

  hsv_core_decode_alu decode_alu (
      .insn,
      .alu_data,

      .illegal (illegal_alu),
      .common_i(common),
      .common_o(common_alu)
  );

  hsv_core_decode_foo decode_foo (
      .insn,
      .foo_data,

      .illegal (illegal_foo),
      .common_i(common),
      .common_o(common_foo)
  );

  hsv_core_decode_mem decode_mem (
      .insn,
      .mem_data,

      .illegal (illegal_mem),
      .common_i(common),
      .common_o(common_mem)
  );

  hsv_core_decode_branch decode_branch (
      .insn,
      .branch_data,

      .illegal (illegal_branch),
      .common_i(common),
      .common_o(common_ctrlstatus)
  );

  hsv_core_decode_ctrlstatus decode_ctrlstatus (
      .insn,
      .ctrlstatus_data,

      .illegal (illegal_ctrlstatus),
      .common_i(common),
      .common_o(common_branch)
  );

  hsv_core_decode_common decode_common (
      .fetch_data,
      .common
  );

  hs_skid_buffer #(
      .WIDTH($bits(issue_data_t))
  ) decode2issue (
      .clk_core,
      .rst_core_n,

      .flush(flush_req),

      .in(out),
      .ready_o(out_ready),
      .valid_i(out_valid),

      .out(issue_data),
      .ready_i,
      .valid_o
  );

  always_comb begin
    illegal = 1;
    exec_select = '0;

    unique case (rv_major_op(
        insn
    ))
      RV_MAJOR_OP, RV_MAJOR_OP_IMM, RV_MAJOR_LUI, RV_MAJOR_AUIPC: begin
        illegal = illegal_alu;
        common_final = common_alu;
        exec_select.alu = 1;
      end

      RV_MAJOR_CUSTOM_0, RV_MAJOR_CUSTOM_1, RV_MAJOR_CUSTOM_2, RV_MAJOR_CUSTOM_3: begin
        illegal = illegal_foo;
        common_final = common_foo;
        exec_select.foo = 1;
      end

      RV_MAJOR_LOAD, RV_MAJOR_STORE: begin
        illegal = illegal_mem;
        common_final = common_mem;
        exec_select.mem = 1;
      end

      RV_MAJOR_BRANCH, RV_MAJOR_JAL, RV_MAJOR_JALR: begin
        illegal = illegal_branch;
        common_final = common_branch;
        exec_select.branch = 1;
      end

      RV_MAJOR_SYSTEM: begin
        illegal = illegal_ctrlstatus;
        common_final = common_ctrlstatus;
        exec_select.ctrlstatus = 1;
      end

      default: begin
        illegal = 1;
        common_final = 'x;
      end
    endcase

    alu_data_or_trap = alu_data;
    alu_data_or_trap.illegal = 0;
    //TODO: alu_data_or_trap.fetch_fault = fetch_data.fault;

    // Illegal opcodes are "executed" by ALU and later handled by commit
    if (fetch_data.fault | illegal) begin
      exec_select = '{alu: 1, default: '0};
      alu_data_or_trap.illegal = 1;
    end
  end

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      out_valid <= valid_i;

      out.common <= common_final;
      out.exec_select <= exec_select;
      out.exec_mem_data.alu_data <= alu_data_or_trap;
      out.exec_mem_data.foo_data <= foo_data;
      out.exec_mem_data.mem_data <= mem_data;
      out.exec_mem_data.branch_data <= branch_data;
      out.exec_mem_data.ctrlstatus_data <= ctrlstatus_data;
    end

    if (flush_req) out_valid <= 0;
  end

endmodule
