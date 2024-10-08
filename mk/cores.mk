here = $(if $(mod_path),$(mod_path)/)
mod_path :=
subdir_stack :=

unknown_core = $(error $(if $(2),in core '$(2)': ,)unknown core '$(1)')

all_cores :=
all_stamps :=

top_stamp = $(call core_stamp,$(rule_top))
core_stamp = $(obj)/deps/$(core_info/$(1)/path)/stamp

core_paths_no_dyn = \
  $(strip \
    $(patsubst /%,%, \
      $(patsubst /,., \
        $(abspath \
          $(foreach path_elem,$(core_info/$(1)/$(2)), \
            $(if $(patsubst /%,,$(path_elem)), \
              $(addprefix /$(if $(3),$(3)/,$(if $(core_info/$(1)/workdir),$(core_info/$(1)/workdir)/)),$(path_elem)), \
              $(path_elem)))))))

core_paths = \
  $(call core_paths_no_dyn,$(1),$(2),$(3)) $(call core_paths_no_dyn,$(1),$(call target_var,$(2)),$(3))

core_objs = $(call core_paths,$(1),$(2),$(obj))

require_core_paths = \
  $(strip \
    $(eval path_val := $$(strip $$(call core_paths,$(1),$(2),$(3)))) \
    $(if $(path_val),$(path_val),$(error core '$(1)' must define '$(2)')))

require_core_objs = $(call require_core_paths,$(1),$(2),$(obj))

core_paths_dyn = $(call core_paths,$(1),$(call target_var,$(2)))

define add_core_dyn
  core_info/$(1)/$(call target_var,$(2)) := $(core_info/$(1)/$(call target_var,$(2))) $(3)
endef

require_core_var = \
  $(strip \
    $(eval var_val := $$(core_info/$(1)/$(2))) \
    $(if $(var_val),$(var_val),$(error core '$(1)' must define '$(2)')))

core_shell = $(call shell_checked,cd $(here); $(1))

define add_core
  this := core_info/$(1)

  ifneq (,$$($$(this)/path))
    $$(error multiple definitions of core '$(1)': '$$($$(this)/path)' and '$(2)')
  else ifneq (,$$(core_path/$(2)))
    $$(error multiple cores under path '$(2)')
  endif

  $$(this)/path := $(2)
  $$(this)/mod_file := $$(mod_file)
  $$(this)/workdir := $$(mod_path)

  $$(eval $$(call $(3)))

  this :=
  all_cores += $(1)
  core_path/$(2) := $(1)
endef

define add_core_subdir
  core :=
  cores :=
  subdirs :=

  subdir_stack += $$(mod_path)
  mod_path := $$(here)$(1)
  mod_file := $$(here)mod.mk

  include $$(mod_file)

  $$(if $$(core), \
    $$(eval $$(call add_core,$(notdir $(1)),$$(mod_path),core)))

  $$(foreach core,$$(cores), \
    $$(eval $$(call add_core,$$(core),$$(here)$$(core),core/$$(core))))

  $$(foreach subdir,$$(subdirs), \
    $$(eval $$(call add_core_subdir,$$(subdir))))

  mod_path := $$(lastword $$(subdir_stack))
  subdir_stack := $$(filter-out $$(mod_path),$$(subdir_stack))
endef

define setup_dep_tree
  $$(foreach core,$$(all_cores), \
    $$(eval $$(call defer,dep_tree/$$(core),$$$$(call get_core_deps,$$(core)))))
endef

define setup_stamp_rules
  $$(strip $$(foreach core,$$(all_cores), \
    $$(eval stamp_val := $$$$(call core_stamp,$$(core))) $$(stamp_val) \
    $$(eval $$(call add_core_stamp,$$(core),$$(stamp_val))))): $$(build_makefiles) | $$(obj)
endef

define add_core_stamp
  $(2): $$(core_info/$(1)/mod_file) \
        $$(foreach dep,$$(core_info/$(1)/deps),$$(call core_stamp,$$(dep)))

  all_stamps += $(2)
endef

define get_core_deps
  dep_tree/$(1) :=

  $$(foreach dep,$$(core_info/$(1)/deps), \
    $$(if $$(core_info/$$(dep)/path),,$$(call unknown_core,$$(dep),$(1))) \
    $$(eval dep_tree/$(1) := \
      $$(dep_tree/$$(dep)) $$(filter-out $$(dep_tree/$$(dep)),$$(dep_tree/$(1)))))

  dep_tree/$(1) := $$(strip $$(dep_tree/$(1)))
  dep_tree/$(1) += $(1)
endef

map_core_deps = \
  $(if $(findstring undefined,$(origin $(1)_deps/$(2))), \
    $(eval $(call merge_mapped_deps,$(1),$(2)))) \
  $($(1)_deps/$(2))

define merge_mapped_deps
  $(1)_deps/$(2) := $$(core_info/$(2)/$(1))

  $$(foreach dep,$$(core_info/$(2)/deps), \
    $$(eval $(1)_deps/$(2) := \
      $$(eval mapped_dep := $$$$(call map_core_deps,$(1),$$(dep))) \
      $$(mapped_dep) $$(filter-out $$(mapped_dep),$$($(1)_deps/$(2)))))
endef

define finish_stamp_rules
  $$(all_stamps):
	@mkdir -p $$$$(dirname $$@) && touch $$@
endef
