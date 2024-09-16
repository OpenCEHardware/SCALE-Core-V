cores := hsv_core_decode hsv_core_decode_pkg

define core/hsv_core_decode
  $(this)/deps := hsv_core_pkg hsv_core_decode_pkg

  $(this)/rtl_top := hsv_core_decode
  $(this)/rtl_files := \
    hsv_core_decode.sv \
    hsv_core_decode_common.sv \
    hsv_core_decode_alu.sv \
    hsv_core_decode_foo.sv \
    hsv_core_decode_mem.sv \
    hsv_core_decode_branch.sv \
    hsv_core_decode_ctrlstatus.sv
endef

define core/hsv_core_decode_pkg
  $(this)/deps := hsv_core_pkg
  $(this)/rtl_files := hsv_core_decode_pkg.sv
endef
