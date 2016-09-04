BUILD_DIR = build
PART = xc3s500e-4-fg320
PROJECT = charlie

all: $(BUILD_DIR)/$(PROJECT).bit

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/$(PROJECT).ngc: clock_divider.vhd config.vhd debounce.vhd display.vhd i2c_slave.vhd matrix_driver.vhd memory.vhd top.vhd $(PROJECT).prj | $(BUILD_DIR)
	@cd $(BUILD_DIR); \
	echo "run -ifn ../$(PROJECT).prj -ifmt mixed -ofn $(PROJECT) -ofmt NGC -p $(PART) -top $(PROJECT) -opt_mode Speed -opt_level 1" | xst

$(BUILD_DIR)/$(PROJECT).ngd: spartan-3e.ucf $(BUILD_DIR)/$(PROJECT).ngc
	@cd $(BUILD_DIR); \
	ngdbuild -aul -p $(PART) -uc ../spartan-3e.ucf $(PROJECT).ngc

$(BUILD_DIR)/$(PROJECT).ncd: $(BUILD_DIR)/$(PROJECT).ngd
	@cd $(BUILD_DIR); \
	map -intstyle ise -p $(PART) \
		-detail -ir off -ignore_keep_hierarchy -pr b -timing -ol high -logic_opt on \
		-w -o $(PROJECT).ncd $(PROJECT).ngd $(PROJECT).pcf

$(BUILD_DIR)/parout.ncd: $(BUILD_DIR)/$(PROJECT).ncd
	@cd $(BUILD_DIR); \
	par -w $(PROJECT).ncd parout.ncd $(PROJECT).pcf

$(BUILD_DIR)/$(PROJECT).bit: $(BUILD_DIR)/parout.ncd
	@cd $(BUILD_DIR); \
	bitgen -g CRC:Enable -g StartUpClk:CClk -g Compress -w parout.ncd $(PROJECT).bit $(PROJECT).pcf

$(BUILD_DIR)/$(PROJECT).bin: $(BUILD_DIR)/$(PROJECT).bit
	@cd $(BUILD_DIR); \
	promgen -w -spi -p bin -o ${PROJECT}.bin -s 1024 -u 0 ${PROJECT}.bit

clean:
	rm -rf $(BUILD_DIR)

program: $(BUILD_DIR)/$(PROJECT).bit
	@cd $(BUILD_DIR); \
	echo "setMode -bs" > impact.cmd; \
	echo "setCable -port auto" >> impact.cmd; \
	echo "Identify -inferir" >> impact.cmd; \
	echo "assignFile -p 1 -file $(PROJECT).bit" >> impact.cmd; \
	echo "Program -p 1" >> impact.cmd; \
	echo "exit" >> impact.cmd; \
	impact -batch impact.cmd
