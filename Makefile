BUILD_DIR = build
DEVICE = xc3s500e-4-fg320
TARGET = charlie

all: $(BUILD_DIR)/$(TARGET).bit

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/$(TARGET).ngc: $(TARGET).vhd | $(BUILD_DIR)
	@cd $(BUILD_DIR); \
	echo "run -ifn ../$(TARGET).vhd -ifmt VHDL -ofn $(TARGET) -p $(DEVICE) -opt_mode Speed -opt_level 1" | xst

$(BUILD_DIR)/$(TARGET).ngd: spartan-3e.ucf $(BUILD_DIR)/$(TARGET).ngc
	@cd $(BUILD_DIR); \
	ngd$(BUILD_DIR) -p $(DEVICE) -uc ../spartan-3e.ucf $(TARGET).ngc

$(BUILD_DIR)/$(TARGET).ncd: $(BUILD_DIR)/$(TARGET).ngd
	@cd $(BUILD_DIR); \
	map -detail -pr b $(TARGET).ngd

# $(TARGET).pcf: $(TARGET).ngd
# 	@cd $(BUILD_DIR); \
# 	map -detail -pr b $(TARGET).ngd

$(BUILD_DIR)/parout.ncd: $(BUILD_DIR)/$(TARGET).ncd
	@cd $(BUILD_DIR); \
	par -w $(TARGET).ncd parout.ncd $(TARGET).pcf

$(BUILD_DIR)/$(TARGET).bit: $(BUILD_DIR)/parout.ncd
	@cd $(BUILD_DIR); \
	bitgen -g CRC:Enable -g StartUpClk:CClk -g Compress -w parout.ncd $(TARGET).bit $(TARGET).pcf

clean:
	rm -rf $(BUILD_DIR)

program: $(BUILD_DIR)/$(TARGET).bit
	@cd $(BUILD_DIR); \
	echo "setMode -bs" > impact.cmd; \
	echo "setCable -port auto" >> impact.cmd; \
	echo "Identify -inferir" >> impact.cmd; \
	echo "assignFile -p 1 -file $(TARGET).bit" >> impact.cmd; \
	echo "Program -p 1" >> impact.cmd; \
	echo "exit" >> impact.cmd; \
	impact -batch impact.cmd
