module hsv_core_ctrlstatus_readwrite
  import hsv_core_pkg::*;
  import hsv_core_ctrlstatus_regs_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    input  logic flush_req,
    output logic flush_ack,

    input ctrlstatus_data_t in,
    output logic ready_o,
    input logic valid_i,

    output commit_data_t out,
    input logic ready_i,
    output logic valid_o,

    output logic regs_req,
    output logic regs_req_is_wr,
    output logic [15:0] regs_addr,
    output logic [31:0] regs_wr_data,
    output logic [31:0] regs_wr_biten,
    input logic regs_req_stall_wr,
    input logic regs_req_stall_rd,
    input logic regs_rd_ack,
    input logic regs_rd_err,
    input logic [31:0] regs_rd_data,
    input logic regs_wr_ack,
    input logic regs_wr_err,

    input insn_token  commit_token,
    input privilege_t current_mode
);

  typedef enum int unsigned {
    ACCEPT,
    CHECK,
    CSR_READ,
    CSR_WRITE,
    COMMIT
  } state_t;

  word read_data, write_data, write_mask;
  logic check, do_read, do_write;
  logic illegal, read_permitted, write_permitted, valid_access;
  logic read_done, read_error, write_done, write_error;
  state_t state, next_state;
  csr_num_t csr_num;
  ctrlstatus_data_t cmd;

  //TODO: trap_cause, trap_value
  assign out.jump = 0;
  assign out.trap = illegal | read_error | write_error;
  assign out.common = cmd.common;
  assign out.result = read_data;
  assign out.next_pc = cmd.common.pc_increment;
  assign out.writeback = do_read;

  assign regs_addr = {csr_num, 4'b0000};

  assign csr_num = cmd.common.immediate[$bits(csr_num_t)-1:0];
  assign valid_access = (~cmd.read | read_permitted) & (~cmd.write | write_permitted);

  always_comb begin
    read_permitted  = 1;
    write_permitted = 1;

    if (csr_num.privilege > current_mode) begin
      read_permitted  = 0;
      write_permitted = 0;
    end

    if (csr_is_read_only(csr_num)) read_permitted = 0;

    if (cmd.is_immediate) write_data = word'(cmd.short_immediate);
    else write_data = cmd.common.rs1;

    if (cmd.write_mask) write_mask = write_data;
    else write_mask = '1;

    if (cmd.write_flip) write_data = ~write_data;

    check = 0;
    ready_o = 0;
    valid_o = 0;

    regs_req = 0;
    regs_req_is_wr = 0;

    next_state = state;

    unique case (state)
      ACCEPT: begin
        ready_o = 1;
        if (ready_o & valid_i) next_state = CHECK;
      end

      CHECK: begin
        check = 1;

        if (commit_token == cmd.common.token) next_state = CSR_READ;
      end

      CSR_READ: begin
        regs_req = do_read;
        regs_req_is_wr = 0;

        if (~do_read | ~regs_req_stall_rd) next_state = CSR_WRITE;
      end

      CSR_WRITE: begin
        regs_req = do_write & read_done;
        regs_req_is_wr = 1;

        if (~do_write | (read_done & ~regs_req_stall_wr)) next_state = COMMIT;
      end

      COMMIT: begin
        valid_o = ~do_write | write_done;

        if (ready_i & valid_o) next_state = ACCEPT;
      end

      default: ;
    endcase
  end

  always_ff @(posedge clk_core) begin
    if (regs_rd_ack) begin
      read_done  <= 1;
      read_data  <= regs_rd_data;
      read_error <= regs_rd_err;
    end

    if (regs_wr_ack) begin
      write_done  <= 1;
      write_error <= regs_wr_err;
    end

    if (ready_o) begin
      cmd <= in;

      read_done <= 0;
      read_error <= 0;
      write_done <= 0;
      write_error <= 0;
    end

    if (check) begin
      illegal <= ~valid_access;
      do_read <= cmd.read & valid_access;
      do_write <= cmd.write & valid_access;

      regs_wr_data <= write_data;
      regs_wr_biten <= write_mask;
    end
  end

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) begin
      state <= ACCEPT;
      flush_ack <= 1;
    end else begin
      state <= next_state;
      if (ready_o & ~valid_i) flush_ack <= flush_req;
    end

endmodule
