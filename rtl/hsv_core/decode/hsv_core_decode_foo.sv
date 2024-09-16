module hsv_core_decode_foo
  import hsv_core_pkg::*;
  import hsv_core_decode_pkg::*;
(
    input  word       insn,
    output foo_data_t foo_data,

    input  decode_common_t common_i,
    output common_data_t   common_o,
    output logic           illegal
);

  // Write your decode logic

  always_comb begin
    illegal  = 0;
    common_o = common_i.r_type;
    foo_data = '0;

    unique case (rv_major_op(
        insn
    ))
      // RV_MAJOR_CUSTOM_0: begin
      //   foo_data.bar = 1;
      //   foo_data.baz = 1;
      //   ...
      // end
      //
      // RV_MAJOR_CUSTOM_1: begin
      //   common_o = common_i.i_type;
      //   foo_data.bar = 1;
      //   ...
      // end
      //
      // RV_MAJOR_CUSTOM_2: ...
      //
      // RV_MAJOR_CUSTOM_3: ...

      default: illegal = 1;
    endcase

    if (illegal) begin
      common_o = 'x;
      foo_data = 'x;
    end
  end

endmodule
