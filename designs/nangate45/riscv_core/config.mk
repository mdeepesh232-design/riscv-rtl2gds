export DESIGN_NAME = riscv_core
export PLATFORM    = nangate45

export VERILOG_FILES = $(sort $(wildcard /OpenROAD-flow-scripts/flow/designs/riscv_core/src/*.v))
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NAME)/constraint.sdc

export SKIP_CTS_REPAIR_TIMING = 1
export CORE_UTILIZATION = 30
export CORE_ASPECT_RATIO = 1
export SYNTH_MEMORY_MAX_BITS = 16384
export ABC_AREA = 1

export CORE_UTILIZATION ?= 55
export PLACE_DENSITY_LB_ADDON = 0.20
export TNS_END_PERCENT        = 100
export SYNTH_REPEATABLE_BUILD ?= 1
