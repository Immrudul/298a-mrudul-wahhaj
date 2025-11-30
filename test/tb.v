`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end   

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
  tt_um_example user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );
   

 `ifndef GL_TEST

  reg  [9:0] pix_x;
  reg  [9:0] pix_y;
  reg  [9:0] x_offset;

  reg  [9:0] x_pos;
  reg  [9:0] y_pos;


 reg draw_line;
 reg draw_player;
 reg draw_U;
 wire draw_double_sin;

 reg  [3:0] pos;
 wire [7:0] sin_output;

  // ----------------------------------------
  // Testing For double_sin
  // ----------------------------------------
  static_top_line top_line(
    .pix_x(pix_x),
    .pix_y(pix_y),
    .draw_line(draw_line)
  );

  player p(
    .pix_x(pix_x),
    .pix_y(pix_y),
    .y_pos(y_pos),
    .show_player(1),
    .draw_player(draw_player)
  );
   
  U_shape single_u(
      .pix_x(pix_x),
      .pix_y(pix_y),
      .x_pos(x_pos),
      .y_pos(y_pos),
      .draw_U(draw_U)
  );

  localparam [9:0] TOP_X        = 10'd100;
  localparam [9:0] TOP_Y        = 10'd180;
  localparam [9:0] BOTTOM_X     = 10'd540;
  localparam [9:0] BOTTOM_Y     = 10'd400;
  localparam [9:0] BAR_WIDTH    = 10'd40;
  localparam [9:0] VISIBLE_WIDTH= 10'd25;
  localparam [9:0] HEIGHT       = 10'd60;

  double_sin dut_double_sin (
      .pix_x(pix_x),
      .pix_y(pix_y),
      .x_offset(x_offset),
      .top_x(TOP_X),
      .top_y(TOP_Y),
      .bottum_x(BOTTOM_X),
      .bottum_y(BOTTOM_Y),
      .bar_width(BAR_WIDTH),
      .visible_width(VISIBLE_WIDTH),
      .height(HEIGHT),
      .draw_double_sin(draw_double_sin)
  );

  // ----------------------------------------
  // Testing sine_lut
  // ----------------------------------------

  sine_lut lut_for_test (
      .pos(pos),
      .sin_output(sin_output)
  );

`endif

endmodule
