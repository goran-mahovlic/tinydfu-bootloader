/*
    TinyDFU Bootloader

    Wrapping usb/usb_dfu_ice40.v.
*/

module logicbone_ecp5 (
    input  refclk,

    inout  usb_ufp_dp,
    inout  usb_ufp_dm,
    output usb_ufp_pull,

    output [3:0] led,

    output flash_csel,
    //output flash_sclk,
    output flash_mosi,
    input flash_miso,

    output [3:0] debug
);

// Use an ecppll generated pll
wire clk_48mhz;
wire clk_locked;
pll pll48( .clkin(refclk), .clkout0(clk_48mhz), .locked( clk_locked ) );

// The SPI serial clock requires a special IP block to access.
wire flash_sclk;
USRMCLK usr_sclk(.USRMCLKI(flash_sclk), .USRMCLKTS(1'b0));

//////////////////////////
// LED Patterns
//////////////////////////
reg [31:0] led_counter;
always @(posedge clk_48mhz) begin
    led_counter <= led_counter + 1;
end

// Simple blink pattern when idle.
wire [3:0] led_idle = {3'b0, led_counter[25]};

// Cylon pattern when programming.
reg [2:0] led_cylon_count = 0;
reg [3:0] led_cylon = 4'b0;
always @(posedge led_counter[22]) begin
   if (led_cylon_count) led_cylon_count <= led_cylon_count - 1;
   else led_cylon_count <= 5;

   if (led_cylon_count == 4) led_cylon <= 4'b0100;
   else if (led_cylon_count == 5) led_cylon <= 4'b0010;
   else led_cylon <= 4'b0001 << led_cylon_count[1:0];
end

// Select the LED pattern by DFU state.
wire [7:0] dfu_state;
always @* begin
    case (dfu_state)
        'h02 : led <= ~led_idle;    // DFU_STATE_dfuIDLE
        default : led <= ~led_cylon;
    endcase
end

// Generate reset signal
reg [5:0] reset_cnt = 0;
wire reset = ~reset_cnt[5];
always @(posedge clk_48mhz)
    if ( clk_locked )
        reset_cnt <= reset_cnt + reset;

wire usb_p_tx;
wire usb_n_tx;
wire usb_p_rx;
wire usb_n_rx;
wire usb_tx_en;

// usb DFU - this instanciates the entire USB device.
usb_dfu dfu (
    .clk_48mhz  (clk_48mhz),
    .reset      (reset),

    // pins
    .pin_usb_p( usb_ufp_dp ),
    .pin_usb_n( usb_ufp_dm ),

    // SPI
    .spi_csel( flash_csel ),
    .spi_clk( flash_sclk ),
    .spi_mosi( flash_mosi ),
    .spi_miso( flash_miso ),  

    // DFU State and debug
    .dfu_state( dfu_state ), 
    .debug( debug )
);

// USB Host Detect Pull Up
assign usb_ufp_pull = 1'b1;

endmodule
