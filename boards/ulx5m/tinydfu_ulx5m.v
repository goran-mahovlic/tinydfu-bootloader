/*
 *  TinyDFU Bootloader for the Lone Dynamics Klinge computer.
 *  (based on the Logicbone ECP5 bootloader)
 */

module tinydfu_ulx5m (
    input        refclk,
    output       resetn,

    inout        usb_ufp_dp,
    inout        usb_ufp_dm,
    output       usb_ufp_pull,

    output       [3:0] led,
    output r,

    output       flash_csel,
    output       flash_sclk,
    output       flash_mosi,
    input        flash_miso
);

wire clk270, clk180, clk90, clk_48mhz, usr_ref_out;
wire usr_pll_lock_stdy, usr_pll_lock;

CC_PLL #(
    .REF_CLK(10.0),      // reference input in MHz
    .OUT_CLK(48.0),      // pll output frequency in MHz
    .LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
    .CI_FILTER_CONST(2), // optional CI filter constant
    .CP_FILTER_CONST(4)  // optional CP filter constant
) pll_inst (
    .CLK_REF(refclk), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
    .USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy), .USR_PLL_LOCKED(usr_pll_lock),
    .CLK270(clk270), .CLK180(clk180), .CLK90(clk90), .CLK0(clk_48mhz), .CLK_REF_OUT(usr_ref_out)
);

(* clkbuf_inhibit *) reg  clk_24mhz = 0;
reg  clk = 0;
always @(posedge clk_48mhz) clk_24mhz <= ~clk_24mhz;
always @(posedge clk_24mhz) clk <= ~clk;

//////////////////////////
// LED Patterns
//////////////////////////
reg [31:0] led_counter;
always @(posedge clk) begin
    led_counter <= led_counter + 1;
end

// Simple blink pattern when idle.
wire [3:0] led_idle = {3'b0, led_counter[21]};

// Cylon pattern when programming.
reg [2:0] led_cylon_count = 0;
reg [3:0] led_cylon = 4'b0;
always @(posedge led_counter[20]) begin
   if (led_cylon_count) led_cylon_count <= led_cylon_count - 1;
   else led_cylon_count <= 5;

   if (led_cylon_count == 4) led_cylon <= 4'b0100;
   else if (led_cylon_count == 5) led_cylon <= 4'b0010;
   else led_cylon <= 4'b0001 << led_cylon_count[1:0];
end

// Select the LED pattern by DFU state.
wire [7:0] dfu_state;
assign led = (dfu_state == 'h02) ? ~led_idle : ~led_cylon;

//////////////////////////
// Reset and Multiboot
//////////////////////////

reg user_boot_now = 1'b0;
reg user_auto_boot = 1'b1;

reg [15:0] reset_delay = 16'hff_ff;
reg [31:0] boot_delay = (12000000 * 5);
wire dfu_detach;
always @(posedge clk) begin

	if (reset_delay) reset_delay <= reset_delay - 1;
   if (boot_delay) boot_delay <= boot_delay - 1;

   // if the user does something with dfu, cancel auto boot
   if (dfu_state > 2) user_auto_boot = 1'b0;

   // if the user detaches, boot now
   if (dfu_detach) user_boot_now = 1'b1;

   // if autoboot is enabled and the timer ends, boot now
   if (user_auto_boot && boot_delay == 0) user_boot_now = 1'b1;

end

assign r =  reset_delay != 0;

CC_TOBUF pin_resetn (.A(1'b0), .T(~user_boot_now), .O(resetn) );

wire usb_p_tx;
wire usb_n_tx;
wire usb_p_rx;
wire usb_n_rx;
wire usb_tx_en;

// USB DFU - this instanciates the entire USB device.
usb_dfu_core dfu (
  .clk_48mhz  (clk_48mhz),
  .clk        (clk),
  .reset      (r),

  // USB signals
  .usb_p_tx( usb_p_tx ),
  .usb_n_tx( usb_n_tx ),
  .usb_p_rx( usb_p_rx ),
  .usb_n_rx( usb_n_rx ),
  .usb_tx_en( usb_tx_en ),

  // SPI
  .spi_csel( flash_csel ),
  .spi_clk( flash_sclk ),
  .spi_mosi( flash_mosi ),
  .spi_miso( flash_miso ),

  // DFU State and debug
  .dfu_detach( dfu_detach ),
  .dfu_state( dfu_state )
  //.debug( )
);

// USB Physical interface
usb_phy_gatemate phy (
  .pin_usb_p (usb_ufp_dp),
  .pin_usb_n (usb_ufp_dm),

  .usb_p_tx( usb_p_tx ),
  .usb_n_tx( usb_n_tx ),
  .usb_p_rx( usb_p_rx ),
  .usb_n_rx( usb_n_rx ),
  .usb_tx_en( usb_tx_en )
);

// USB Host Detect Pull Up
assign usb_ufp_pull = 1'b1;

endmodule
