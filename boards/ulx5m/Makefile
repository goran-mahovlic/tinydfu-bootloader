##
## Make and program ULX5M
##

BASENAME = tinydfu
TARGETNAME = $(BASENAME)_ulx5m
PROJTOP = tinydfu_ulx5m

RTL_USB_DIR = ../../usb

SOURCES = \
	$(RTL_USB_DIR)/edge_detect.v \
	$(RTL_USB_DIR)/strobe.v \
	$(RTL_USB_DIR)/usb_fs_in_arb.v \
	$(RTL_USB_DIR)/usb_fs_in_pe.v \
	$(RTL_USB_DIR)/usb_fs_out_arb.v \
	$(RTL_USB_DIR)/usb_fs_out_pe.v \
	$(RTL_USB_DIR)/usb_fs_pe.v \
	$(RTL_USB_DIR)/usb_fs_rx.v \
	$(RTL_USB_DIR)/usb_fs_tx_mux.v \
	$(RTL_USB_DIR)/usb_fs_tx.v \
	$(RTL_USB_DIR)/usb_string_rom.v \
	$(RTL_USB_DIR)/usb_dfu_ctrl_ep.v \
	$(RTL_USB_DIR)/usb_spiflash_bridge.v \
	$(RTL_USB_DIR)/usb_dfu_core.v \
	$(RTL_USB_DIR)/usb_phy_gatemate.v

SRC = $(PROJTOP).v $(SOURCES)

PIN_DEF = ulx5m.ccf

BOOTADDR = 0x100000 # User image starts at 1MB

all: $(PROJTOP).bit
bootloader: $(PROJTOP).bit

synth: $(PROJTOP).json

$(PROJTOP).json: $(SRC)
	yosys -q -p 'synth_gatemate -top $(PROJTOP) -nomx8 -nomult -luttree -json $@' $^

$(PROJTOP).txt: $(PROJTOP).json $(PIN_DEF)
	nextpnr-himbaechel --device CCGM1A1 --json $< --vopt ccf=$(PIN_DEF) --vopt out=$@ --router router2

%.bit: %.txt
	gmpack $< $@

prog: $(PROJTOP).bit
	openFPGALoader --index-chain 0 -b gatemate_evb_jtag $<

prog_flash: $(PROJTOP).bit
	openFPGALoader --index-chain 0 -b gatemate_evb_jtag -f $<

dfu:
	dfu-util -d 16d0:116d -a2 -D blink.bit

clean:
	rm -f $(PROJTOP).json $(PROJTOP).txt $(PROJTOP).bit

