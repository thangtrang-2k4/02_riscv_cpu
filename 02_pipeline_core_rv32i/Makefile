# ========= User knobs =========
TOOL ?= questa
UNIT ?=
TOP  ?= tb_$(UNIT)
SEED ?= 1
WAVES?= 0
UVM ?= 0

# ========= Bare test knobs (top-level core testbenches) =========
# Ví dụ: make BARE=single_cycle gui  -> dùng tb/bare/tb_single_cycle.sv
BARE ?=
ifeq ($(BARE),)
  IS_BARE := 0
else
  IS_BARE := 1
endif

# ========= Board test knobs (board-level testbenches) =========
# Ví dụ: make BOARD=de2 gui -> dùng tb/board/tb_fpga_top_de2.sv
BOARD ?=
ifeq ($(BOARD),)
  IS_BOARD := 0
else
  IS_BOARD := 1
endif

# ========= Paths =========
OUT_DIR    := sim/out/$(TOOL)
FLIST_DIR  := sim/filelists
COMMON_FL  := $(FLIST_DIR)/common.f

# ========= Filelists chọn động (ưu tiên: BOARD > BARE > UNIT) =========
ifeq ($(IS_BOARD),1)
  # --- BOARD mode ---
  # Quy ước: filelist: sim/filelists/tb_board_$(BOARD).f
  #          top:      tb_$(BOARD)
  TOP     := tb_$(BOARD)
  FLISTS  := $(COMMON_FL) $(FLIST_DIR)/tb_board_$(BOARD).f
else ifeq ($(IS_BARE),1)
  # --- BARE mode ---
  # Quy ước: filelist: sim/filelists/tb_bare_$(BARE).f
  #          top:      tb_$(BARE)
  TOP     := tb_$(BARE)
  FLISTS  := $(COMMON_FL) $(FLIST_DIR)/tb_bare_$(BARE).f
else
  # --- UNIT mode ---
  # Quy ước: filelist: sim/filelists/tb_unit_$(UNIT).f
  #          top:      tb_$(UNIT)
  TOP     := tb_$(UNIT)
  FLISTS  := $(COMMON_FL) $(FLIST_DIR)/tb_unit_$(UNIT).f
endif

# (Tuỳ chọn) kiểm tra filelist tồn tại để báo lỗi sớm, comment nếu bạn không muốn cứng ràng
# $(info [INFO] TOP=$(TOP)  FLISTS=$(FLISTS))
# $(if $(wildcard $(word 2,$(FLISTS))),,$(error Filelist '$(word 2,$(FLISTS))' not found))

# ========= UVM flags (để dành) =========
ifeq ($(UVM),1)
  UVM_FLAGS_QUESTA := -uvm
  UVM_FLAGS_XRUN   := -uvm
else
  UVM_FLAGS_QUESTA :=
  UVM_FLAGS_XRUN   :=
endif

# ========= Phony =========
.PHONY: all run gui wave batch clean clear compile prepare tool info

all: run

info:
	@echo "MODE=$$(if [ $(IS_BOARD) -eq 1 ]; then echo BOARD($(BOARD)); else if [ $(IS_BARE) -eq 1 ]; then echo BARE($(BARE)); else echo UNIT($(UNIT)); fi; fi)"
	@echo "TOOL=$(TOOL)"
	@echo "TOP=$(TOP)"
	@echo "UNIT=$(UNIT)"
	@echo "BARE=$(BARE)"
	@echo "BOARD=$(BOARD)"
	@echo "WAVES=$(WAVES)"
	@echo "UVM=$(UVM)"
	@echo "FLISTS=$(FLISTS)"
	@echo "OUT_DIR='$(OUT_DIR)'"

# ========= Front targets =========
run: WAVES=0
run: tool

gui: WAVES=1
gui: tool

wave: gui
batch: run

tool: $(TOOL)

# ========= QuestaSim flow =========
questa: prepare_questa compile_questa run_questa

prepare_questa:
	@mkdir -p $(OUT_DIR)
	@vmap -del work >/dev/null 2>&1 || true
	@vlib $(OUT_DIR)/work >/dev/null 2>&1 || true
	@echo "[Questa] Mapping work -> $(OUT_DIR)/work"
	@vmap work $(abspath $(OUT_DIR)/work)

compile_questa:
	@echo "[Questa] vlog compile..."
	@for fl in $(FLISTS); do \
	    echo "  -> $$fl"; \
	    vlog -work work -sv +acc +define+SIM $(UVM_FLAGS_QUESTA) -f $$fl || exit 1; \
	done

run_questa:
	@echo "[Questa] vsim run (WAVES=$(WAVES))..."
	@if [ "$(WAVES)" = "1" ]; then \
	  vsim -voptargs=+acc -sv_seed $(SEED) -onfinish stop \
	       -wlf $(OUT_DIR)/$(TOP).wlf work.$(TOP) \
	       -do "view wave; log -r /*; add wave -r /*; run -all"; \
	else \
	  vsim -c -voptargs=+acc -sv_seed $(SEED) \
	       -wlf $(OUT_DIR)/$(TOP).wlf work.$(TOP) \
	       -do "log -r /*; run -all; quit -f"; \
	fi

# ========= Xcelium flow =========
xcelium:
	@mkdir -p $(OUT_DIR)
	@echo "[Xcelium] xrun compile+run (WAVES=$(WAVES))..."
	@xrun -64bit -sv -access +rwc +define+SIM $(UVM_FLAGS_XRUN) \
	     -f $(FLISTS) -top $(TOP) \
	     +ntb_random_seed=$(SEED) \
	     $(if $(filter 1,$(WAVES)),-gui,)

# ========= Clean =========
clean:
	rm -rf sim/out/* transcript vsim.wlf *.log xcelium.d simvision* work

clear: clean
