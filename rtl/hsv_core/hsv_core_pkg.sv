package hsv_core_pkg;
  //      ______________________________________
  //_____/ CORE

  // Constants

  localparam int RegAmount = 32;

  // -------------- Core typedefs --------------

  typedef logic [31:0] word;
  typedef logic [4:0] reg_addr;
  typedef logic [4:0] alu_opcode;

  // Instructions are 4-byte sized and aligned
  typedef logic [31:2] pc_ptr;

  // Unique sequential id for issued instructions. The first instruction after
  // a flush gets token 0, second one gets token 1, etc. The commit stage
  // makes use of this token to select outputs from execution units in the
  // same order those instructions were issued.
  typedef logic [7:0] insn_token;

  // -------------- Core enums --------------


  // -------------- Core structs --------------

  typedef struct packed {
    word     pc;
    word     pc_increment;
    reg_addr rs1_addr;
    reg_addr rs2_addr;
    reg_addr rd_addr;
    word     immediate;
  } common_data_t;

  typedef struct packed {
    word insn;
    word pc;
    word pc_increment;
    logic fault;  // E.g. jump to invalid address
  } fetch_data_t;

  //      ______________________________________
  //_____/ FRONTEND STAGE


  // -------------- Frontend typedefs --------------



  // -------------- Frontend enums -----------------



  // -------------- Frontend structs ---------------




  //      ______________________________________
  //_____/ EXECUTE-MEMORY STAGE

  // -------------- Exec-Mem typedefs --------------

  // ALU adder requires an additional 33th bit to implement slt/sltu
  typedef logic [$bits(word):0] adder_in;

  typedef logic [4:0] shift;

  // Up to 31 reads and writes may be pending at any given time.
  // Note that mem_counters might go below zero and become negative.
  typedef logic signed [5:0] mem_counter;

  // -------------- Exec-Mem enums and structs -----------------

  // -------------- Exec-Mem common structs ---------------

  typedef struct packed {
    insn_token token;
    word       pc;
    word       pc_increment;
    reg_addr   rs1_addr;
    reg_addr   rs2_addr;
    reg_addr   rd_addr;
    word       rs1;
    word       rs2;
    word       immediate;
  } exec_mem_common_t;

  // -- ALU --

  typedef enum logic [0:0] {
    ALU_OUT_ADDER,
    ALU_OUT_SHIFT
  } alu_out_t;

  typedef enum logic [1:0] {
    ALU_BITWISE_AND,
    ALU_BITWISE_OR,
    ALU_BITWISE_XOR,
    ALU_BITWISE_PASS
  } alu_bitwise_t;

  typedef enum logic [4:0] {
    OPCODE_ADD,
    OPCODE_ADDI,
    OPCODE_SUB,
    OPCODE_AND,
    OPCODE_ANDI,
    OPCODE_OR,
    OPCODE_ORI,
    OPCODE_XOR,
    OPCODE_XORI,
    OPCODE_SLL,
    OPCODE_SLLI,
    OPCODE_SRL,
    OPCODE_SRLI,
    OPCODE_SRA,
    OPCODE_SRAI,
    OPCODE_SLT,
    OPCODE_SLTI,
    OPCODE_SLTU,
    OPCODE_SLTIU,
    OPCODE_LUI,
    OPCODE_AUIPC
  } alu_opcode_t;

  // -- Branch --

  typedef enum logic [0:0] {
    BRANCH_COND_EQUAL,
    BRANCH_COND_LESS_THAN
  } branch_cond_t;

  // -- Control-Status --

  typedef enum logic [1:0] {
    USER_MODE       = 2'b00,
    SUPERVISOR_MODE = 2'b01,
    MACHINE_MODE    = 2'b11
  } privilege_t;

  typedef enum logic [1:0] {
    CSR_RW_00 = 2'b00,
    CSR_RW_01 = 2'b01,
    CSR_RW_10 = 2'b10,
    CSR_RO    = 2'b11
  } csr_access_t;

  typedef struct packed {
    csr_access_t access;
    privilege_t privilege;
    logic [7:0] index;
  } csr_num_t;

  function automatic csr_is_read_only(csr_num_t csr);
    return csr.access == CSR_RO;
  endfunction

  // -- Memory --

  typedef enum logic [0:0] {
    MEM_DIRECTION_READ,
    MEM_DIRECTION_WRITE
  } mem_direction_t;

  typedef enum logic [1:0] {
    // In the future, MEM_SIZE_DOUBLE can be added here to support RV64
    MEM_SIZE_BYTE,
    MEM_SIZE_HALF,
    MEM_SIZE_WORD
  } mem_size_t;

  // The first 1GiB of physical address space is presumed to exclusively
  // contain ordinary RAM and ROM, that is, bufferable and cacheable memory.
  // Addresses outside this range are for memory-mapped I/O devices. Reads and
  // writes to I/O space cannot be pipelined, forwarded or cached, because
  // they can and will trigger all sorts of side effects. As such, they are
  // usually slower than accesses to normal RAM/ROM space.
  //
  // This does not mean that we have a full 1GiB of available RAM. Rather,
  // all system RAM and ROM must be mapped below the 1GiB mark and everything else
  // must be mapped above it. The CPU core uses this division to make
  // decisions on how to access memory. It is illegal, for example, to jump to
  // an address within I/O space.
  //
  // Be sure to respect this separation between RAM/ROM and I/O when including
  // this core in a larger system. Otherwise, memory behavior will be
  // unpredictable. If needed, you can safely change this function to specify a
  // different RAM/ROM-I/O split.
  function automatic logic address_is_memory(word address);
    return address[31:30] == '0;
  endfunction

  typedef enum logic [1:0] {
    AXI_RESP_OKAY   = 2'b00,
    AXI_RESP_EXOKAY = 2'b01,
    AXI_RESP_SLVERR = 2'b10,
    AXI_RESP_DECERR = 2'b11
  } axi_resp_t;

  function automatic logic is_axi_error(axi_resp_t resp);
    return (resp == AXI_RESP_SLVERR) & (resp == AXI_RESP_DECERR);
  endfunction

  typedef enum logic [1:0] {
    AXI_BURST_FIXED = 2'b00,
    AXI_BURST_INCR  = 2'b01,
    AXI_BURST_WRAP  = 2'b10
  } axi_burst_t;

  // Number of bytes per transfer
  typedef enum logic [2:0] {
    AXI_SIZE_1   = 3'b000,
    AXI_SIZE_2   = 3'b001,
    AXI_SIZE_4   = 3'b010,
    AXI_SIZE_8   = 3'b011,
    AXI_SIZE_16  = 3'b100,
    AXI_SIZE_32  = 3'b101,
    AXI_SIZE_64  = 3'b110,
    AXI_SIZE_128 = 3'b111
  } axi_size_t;

  // -- Foo --

  // Define structs and enums for your foo unit

  // -- ALU --

  typedef struct packed {
    // The decoder routes all illegal instructions through ALU. The ALU will
    // then compute some nonsensical result (discarded) and commit the exception.
    // We handle illegal opcodes this way because traps are not actually triggered
    // until commit, like every other instruction side effect. Thus, issue and
    // execute have to propagate the illegal operation all the way to commit.
    // The simplest solution is to reuse the ALU path, because ALU will never
    // generate exceptions by itself.
    //
    // Note that real ALU instructions will have `illegal = 0`.
    logic illegal;

    logic             negate;
    logic             flip_signs;
    alu_bitwise_t     bitwise_select;
    logic             sign_extend;
    logic             is_immediate;
    logic             compare;
    alu_out_t         out_select;
    logic             pc_relative;
    exec_mem_common_t common;
  } alu_data_t;

  // -- Branch --

  typedef struct packed {
    word              predicted;
    branch_cond_t     cond;
    logic             cond_signed;
    logic             unconditional;
    logic             negate;
    logic             relative;
    logic             link;
    exec_mem_common_t common;
  } branch_data_t;

  // -- Control-Status --

  typedef struct packed {
    logic             read;
    logic             write;
    logic             write_flip;
    logic             write_mask;
    logic             is_immediate;
    logic [4:0]       short_immediate;
    exec_mem_common_t common;
  } ctrlstatus_data_t;

  // -- Memory --

  typedef struct packed {
    mem_direction_t   direction;
    mem_size_t        size;
    logic             sign_extend;  // lbu/lhu vs lb/lh
    exec_mem_common_t common;
  } mem_data_t;

  typedef struct packed {
    mem_data_t  mem_data;
    word        address;
    word        write_data;
    logic [3:0] write_strobe;
    logic       is_memory;          // See address_is_memory() above
    logic       unaligned_address;
    logic [1:0] read_shift;         // Subword address bits, used for correcting read results
  } read_write_t;

  // -- Foo --

  // Add new decode signals as needed by your foo unit
  typedef struct packed {
    // "bar, baz, qux" are dummy signals, replace them with something useful
    logic             bar;
    logic             baz;
    logic             qux;
    exec_mem_common_t common;
  } foo_data_t;

  // Unified decode data for all execution units

  typedef struct packed {
    alu_data_t        alu_data;
    foo_data_t        foo_data;
    mem_data_t        mem_data;
    branch_data_t     branch_data;
    ctrlstatus_data_t ctrlstatus_data;
  } exec_mem_data_t;

  //      ______________________________________
  //_____/ ISSUE STAGE


  // -------------- Issue typedefs --------------

  typedef logic [RegAmount-1:1] reg_mask;


  // -------------- Issue enums -----------------

  // In this case we use a one-hot vector notation to avoid adding extra
  // decoding logic. One downside is undefined behaviour should the signal
  // erroneously flip one bit
  typedef struct packed {
    logic alu;
    logic branch;
    logic ctrlstatus;
    logic mem;
    logic foo;
  } exec_select_t;

  // -------------- Issue structs ---------------

  typedef struct packed {
    common_data_t   common;
    exec_mem_data_t exec_mem_data;
    exec_select_t   exec_select;
  } issue_data_t;

  //      ______________________________________
  //_____/ COMMIT STAGE


  // -------------- Commit typedefs --------------



  // -------------- Commit enums -----------------



  // -------------- Commit structs ---------------

  typedef struct packed {
    word              next_pc;
    word              result;
    logic             jump;
    logic             trap;
    logic             writeback;
    reg_mask          rd_mask;
    logic [4:0]       trap_cause;  //Check size
    logic [31:0]      trap_value;  //Check size
    exec_mem_common_t common;
  } commit_data_t;

endpackage : hsv_core_pkg
