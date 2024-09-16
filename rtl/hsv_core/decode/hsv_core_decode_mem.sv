module hsv_core_decode_mem
  import hsv_core_pkg::*;
  import hsv_core_decode_pkg::*;
(
    input  word       insn,
    output mem_data_t mem_data,

    input  decode_common_t common_i,
    output common_data_t   common_o,
    output logic           illegal
);

  always_comb begin
    illegal  = 0;
    mem_data = '0;

    unique case ({
      rv_major_op(insn), rv_funct3_op(insn)
    })
      {
        RV_MAJOR_LOAD, RvFunct3LoadStoreByteSigned
      }, {
        RV_MAJOR_STORE, RvFunct3LoadStoreByteSigned
      } : begin
        mem_data.size = MEM_SIZE_BYTE;
        mem_data.sign_extend = 1;
      end

      {
        RV_MAJOR_LOAD, RvFunct3LoadStoreHalfSigned
      }, {
        RV_MAJOR_STORE, RvFunct3LoadStoreHalfSigned
      } : begin
        mem_data.size = MEM_SIZE_HALF;
        mem_data.sign_extend = 1;
      end

      {
        RV_MAJOR_LOAD, RvFunct3LoadStoreWord
      }, {
        RV_MAJOR_STORE, RvFunct3LoadStoreWord
      } :
      mem_data.size = MEM_SIZE_WORD;

      {RV_MAJOR_LOAD, RvFunct3LoadStoreByteUnsigned} : mem_data.size = MEM_SIZE_BYTE;

      {RV_MAJOR_LOAD, RvFunct3LoadStoreHalfUnsigned} : mem_data.size = MEM_SIZE_HALF;

      default: illegal = 1;
    endcase

    unique case (rv_major_op(
        insn
    ))
      RV_MAJOR_LOAD: begin
        common_o = common_i.i_type;
        mem_data.direction = MEM_DIRECTION_READ;
      end

      RV_MAJOR_STORE: begin
        common_o = common_i.s_type;
        mem_data.direction = MEM_DIRECTION_WRITE;
        mem_data.sign_extend = 'x;
      end

      default: illegal = 1;
    endcase

    if (illegal) begin
      common_o = 'x;
      mem_data = 'x;
    end
  end

endmodule
