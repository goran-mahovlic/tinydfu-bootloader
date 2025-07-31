##
## Make and program ULX5M
##

TEST_CASE := tinydfu
TOP := tinydfu_ulx5m
YOSYS_PARAM := -nomx8 -nomult
RTL_USB_DIR = ../../usb
BOOTADDR = 0x100000 # User image starts at 1MB

VERILOG_FILES := \
	tinydfu_ulx5m.v \
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

include ../../../makefile.inc