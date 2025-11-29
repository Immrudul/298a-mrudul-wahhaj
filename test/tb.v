`default_nettype none
`timescale 1ns / 1ps

module tb ();

  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // DUT I/O
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

  // -----------------------------
  // Top-level DUT (always exists)
  // -----------------------------
  tt_um_example user_project (
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (ena),
      .clk    (clk),
      .rst_n  (rst_n)
  );

  // ==========================================================
  //  RTL-ONLY MODULE TESTING
  //  These modules DO NOT EXIST in GL netlist (flattened)
  // ==========================================================
`ifndef GL_TEST

  // Shared test signals
  reg  [9:0] pix_x;
  reg  [9:0] pix_y;
  reg  [9:0] x_offset;
  reg  [9:0] x_pos;
  reg  [9:0] y_pos;

  // ---- static_top_line test instance ----
  wire draw_line;
  static_top_line top_line (
      .pix_x(pix_x),
      .pix_y(pix_y),
      .draw_line(draw_line)
  );

  // ---- player test instance ----
  wire draw_player;
  player p (
      .pix_x(pix_x),
      .pix_y(pix_y),
      .y_pos(y_pos),
      .show_player(1'b1),
      .draw_player(draw_player)
  );

  // ---- U_shape test instance ----
  wire draw_U;
  U_shape u_shape_dut (
      .pix_x(pix_x),
      .pix_y(pix_y),
      .x_pos(x_pos),
      .y_pos(y_pos),
      .draw_U(draw_U)
  );

  // Sine wave geometry constants
  localparam [9:0] TOP_X        = 100;
  localparam [9:0] TOP_Y        = 180;
  localparam [9:0] BOTTOM_X     = 540;
  localparam [9:0] BOTTOM_Y     = 400;
  localparam [9:0] BAR_WIDTH    = 40;
  localparam [9:0] VISIBLE_WIDTH= 25;
  localparam [9:0] HEIGHT       = 60;

  // ---- double_sin test instance ----
  wire draw_double_sin;
  double_sin double_sin_dut (
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

  // ---- sine_lut test instance ----
  reg  [3:0] tb_pos;
  wire [7:0] tb_sin_output;
  sine_lut lut_test (
      .pos(tb_pos),
      .sin_output(tb_sin_output)
  );

`endif // !GL_TEST

endmodule
