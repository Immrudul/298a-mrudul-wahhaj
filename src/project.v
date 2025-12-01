/*
 * Tiny Tapeout VGA: UWaterloo style Sans Bad Time Fight simulator
 * By Mrudul Suresh and Wahhaj Khan
 */

`default_nettype none

// declare top-level module of our entire circuit
module tt_um_immrudul_w7khan (
  input  wire [7:0] ui_in,    // Unused inputs
  output wire [7:0] uo_out,   // VGA PMOD outputs
  input  wire [7:0] uio_in,   // Unused bidirectional IOs
  output wire [7:0] uio_out,
  output wire [7:0] uio_oe,
  input  wire       ena,
  input  wire       clk,
  input  wire       rst_n
);

  // a VGA monitor expects 5 things:
  // 1. hsync – horizontal sync pulse (end of a scanline)
  // 2. vsync – vertical sync pulse (end of a full frame)
  // 3. R, G, B – color bits
  // 4. Pixel position (x,y) – this is for us to decide
  // 5. display_on – tells whether the monitor is currently drawing or in “invisible” timing areas

  wire hsync, vsync;
  wire [1:0] R, G, B;
  wire video_active;
  wire [9:0] pix_x, pix_y;   

  // VGA PMOD mapping
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  assign uio_out = 0;
  assign uio_oe  = 0;
  wire _unused_ok = &{ena, ui_in, uio_in};

  // ── VGA timing ─────────────────────────────────────────────
  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  // ── Animation Control ──────────────────────────────────────

  // registers that store the animation state
  reg [9:0] x_offset = 0;         //initial x offset starts at 0
  reg       game_started = 0;     // checking whether the game animation has started
  reg [7:0] speed_reg = 8'd4;     // speed register to control animation speed
  reg direction = 1'b0;           // direction register to control animation direction 0 = forward, 1 = reverse

  //update animation once per frame 
  always @(posedge vsync or negedge rst_n) begin
      if (!rst_n) begin
          direction <= 1'b0;
      end else begin
          direction <= ui_in[4];   // user controls direction
      end
  end

  // if the user sets the animation speed to 0, we would have no animation
  // so to avoid this, if the speed is inputted to be 0, we set a minimum animation speed of 0
  wire [7:0] speed_safe = (speed_reg == 0) ? 1 : speed_reg;

  // computing delta, which is how far to move each frame since it is speed and direction dependent
  wire [9:0] delta =
      direction ? (400 - speed_safe) : speed_safe;

  always @(posedge vsync or negedge rst_n) begin 
      if (!rst_n) begin
          speed_reg <= 8'd4;
      end else begin
          speed_reg <= {4'b0000, ui_in[3:0]};  // read switches for speed
      end
  end

  // updating the animation each frame
  always @(posedge vsync or negedge rst_n) begin 
    // on reset
    if (!rst_n) begin
      x_offset     <= 0;
      game_started <= 0;
    // on first frame
    end else begin
      if (!game_started) begin
        game_started <= 1;   // start immediately, no animation delay
      // every other frame
      end else begin
        x_offset <= (x_offset + delta) % 400;     // wrap sine wave so that endless scrolling
      end
    end
  end

  // ── Scene Drawing ──────────────────────────────────────────
  // instantiation for a module (create_game_scene) that determines if a sine wave should be drawn at a specific pixel coordinate
  // it looks at the current pixel coordinate pix_x, pix_y
  // it looks at the animation shift x_offset
  // it outputs draw_sin = 1 when the sine wave should be drawn

  wire draw_sin;
  create_game_scene scene(
    .pix_x(pix_x),s
    .pix_y(pix_y),
    .x_offset(x_offset),
    .draw_sin(draw_sin)
  );

  // ── Auto-Following UW ─────────────────────────────────────
  // creating the auto following UW character/sprite
  // compute which part of the sine wave is currently under the UW
  // read the sine wave height from the lookup table
  // convert that height into a Y-position
  // draw the UW letters at that Y-position for every frame
  // so the UW "rides" the sin waves

  localparam [9:0] CENTER_BASE_Y = 10'd290;  // (480/2) + 50      // roughly the center of the screen (480/2) + a vertical shift
  localparam [9:0] DOT_X_POS = 10'd200;                           // fixed X location where UW sits (since only y moves)
  localparam [9:0] BAR_WIDTH = 10'd40;                            // width of one sine-wave segment (matches sine LUT logic)

  wire [3:0] addr_player = ((DOT_X_POS + x_offset) / BAR_WIDTH) % 10;     // checking which sine table entry below the UW
  wire [7:0] sine_y_player;
  sine_lut lut_player(.pos(addr_player), .sin_output(sine_y_player));     // read the value from the sine lookup table at the selected index

  wire [9:0] player_y_pos = CENTER_BASE_Y - sine_y_player + 10'd25;       // convert the sine wave height into a screen Y coordinate

  // instantiate player model
  wire draw_player;
  player p(
    .pix_x(pix_x),
    .pix_y(pix_y),
    .y_pos(player_y_pos),
    .show_player(game_started),
    .draw_player(draw_player)
  );

  // ── Static Top Line ────────────────────────────────────────
  // instantiate the static Goose Sans drawing at the top
  wire draw_line;
  static_top_line top_line(
    .pix_x(pix_x),
    .pix_y(pix_y),
    .draw_line(draw_line)
  );

  // ── VGA Color Output ───────────────────────────────────────
  wire line_area = (pix_y >= 10) && (pix_y < 170) &&
                   (pix_x >= 250) && (pix_x < 390);         // rectangular bounding box to keep the animation within
  wire line_color = line_area && draw_line;                 // draw the line if in the allowed area and pattern says to
  
  // colour assignment, you can see that only the draw_player is only red (everything else white or black)
  assign R = video_active ? ((draw_sin || draw_player || line_color) ? 2'b11 : 2'b00) : 0;
  assign G = video_active ? ((draw_sin || line_color) ? 2'b11 : 2'b00) : 0;
  assign B = video_active ? ((draw_sin || line_color) ? 2'b11 : 2'b00) : 0;
endmodule
// end of the top module

// ─────────────────────────────────────────────
// VGA Sync Generator Module (640x480 @ 60Hz)
// ─────────────────────────────────────────────
module hvsync_generator(
    input wire clk,
    input wire reset,
    output reg hsync,
    output reg vsync,
    output wire display_on,
    output wire [9:0] hpos,
    output wire [9:0] vpos
);
  // Horizontal timing (640x480 @ 60Hz, 25 MHz pixel clock)
  // there are 535 rows of 800 pixels being sent 

  // horizontal timing
  localparam H_DISPLAY    = 640;
  localparam H_FRONT      = 16;
  localparam H_SYNC       = 96;
  localparam H_BACK       = 48;
  localparam H_TOTAL      = 800;

  // vertical timing
  localparam V_DISPLAY    = 480;
  localparam V_FRONT      = 10;
  localparam V_SYNC       = 2;
  localparam V_BACK       = 33;
  localparam V_TOTAL      = 525;

  reg [9:0] h_count = 0;
  reg [9:0] v_count = 0;

  // Horizontal counter
  // for every clock, we move one pixel to the right
  // when we reach 799th pixel, go back to the 0th pixel
  always @(posedge clk) begin
    if (reset) begin
      h_count <= 0;
    end else begin
      if (h_count == H_TOTAL - 1)
        h_count <= 0;
      else
        h_count <= h_count + 1;
    end
  end

  // Vertical counter
  // keep checking every clock
  // increment when a full horizontal line has completed  
  always @(posedge clk) begin
    if (reset) begin
      v_count <= 0;
    end else begin
      if (h_count == H_TOTAL - 1) begin
        if (v_count == V_TOTAL - 1)
          v_count <= 0;
        else
          v_count <= v_count + 1;
      end
    end
  end

  // Generate sync signals
  // VGA requires horizontal and vertical sync pulse (end of scanline and end of full frame respectively)
  always @(posedge clk) begin
    hsync <= (h_count >= (H_DISPLAY + H_FRONT)) && 
             (h_count < (H_DISPLAY + H_FRONT + H_SYNC));
    vsync <= (v_count >= (V_DISPLAY + V_FRONT)) && 
             (v_count < (V_DISPLAY + V_FRONT + V_SYNC));
  end

  // Display enable
  assign display_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);   // make sure that we're in the horizontal and vertical range that we want
  assign hpos = h_count;
  assign vpos = v_count;
endmodule
//end of the vga sync module


// ─────────────────────────────────────────────
// Static Top Pattern (16 rows x 14 columns) with symmetry
// ─────────────────────────────────────────────
// module that draws the Goose Sans at the top
module static_top_line (
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    output wire draw_line
);
  localparam integer ROWS = 16;
  localparam integer COLS = 14;
  localparam integer PIXEL_WIDTH = 8;
  localparam integer START_X = 250;
  localparam integer START_Y = 10;
  
  // store only the left half (7 bits instead of 14)
  // this is because we can just mirror the same thing onto the other side (so take advantage of symmetry)
  reg [6:0] pattern_half [0:ROWS-1];
  // hard coded goose where all the 1s represent white and the 0s are black
  initial begin
    pattern_half[0]  = 7'b0000011;
    pattern_half[1]  = 7'b0000100;
    pattern_half[2]  = 7'b0001000;
    pattern_half[3]  = 7'b0001010;
    pattern_half[4]  = 7'b0001001;
    pattern_half[5]  = 7'b0001111;
    pattern_half[6]  = 7'b0010011;
    pattern_half[7]  = 7'b0100000;
    pattern_half[8]  = 7'b1000000;
    pattern_half[9]  = 7'b1000000;
    pattern_half[10] = 7'b1000000;
    pattern_half[11] = 7'b0101000;
    pattern_half[12] = 7'b0010000;
    pattern_half[13] = 7'b0001000;
    pattern_half[14] = 7'b0010001;
    pattern_half[15] = 7'b0001110;
  end
  
  wire [9:0] pattern_y = (pix_y >= START_Y) ? (pix_y - START_Y) : 10'd0;
  wire [9:0] pattern_x = (pix_x >= START_X) ? (pix_x - START_X) : 10'd0;
  
  wire [4:0] row_index = pattern_y[9:3];
  wire [3:0] col_index = pattern_x[9:3];
  
  wire in_bounds = (pix_y >= START_Y) && (pix_y < START_Y + ROWS * PIXEL_WIDTH) &&
                   (pix_x >= START_X) && (pix_x < START_X + COLS * PIXEL_WIDTH);
  
  // mirror the column index if in the right half
  wire [2:0] half_col = (col_index < 7) ? col_index[2:0] : (13 - col_index);
  
  wire pattern_bit = (row_index < ROWS && col_index < COLS) ? 
                     pattern_half[row_index][6 - half_col] : 1'b0;
  
  assign draw_line = in_bounds && pattern_bit;
endmodule
// end of Goose Sans module

// ─────────────────────────────────────────────
// Player ("UW" letters)
// ─────────────────────────────────────────────
// module that combines the uses the U shape module to draw UW character
module player (
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire [9:0] y_pos,
    input  wire show_player,
    output wire draw_player
);

  // all x positions for the U and W are fixed since only vertical movement
  localparam [9:0] X_POS = 10'd200;

  // instantiate 3 Us, each at different x positions
  // U UU - cretes a U W like pattern

  // --- "U" shape ---
  wire u_shape;
  U_shape u(pix_x, pix_y, X_POS, y_pos, u_shape);

  localparam [9:0] W_X = 10'd217;  // X_POS + 17

  // --- "W" shape ---
  wire w_shape;
  U_shape w1(pix_x, pix_y, W_X, y_pos, w_shape);

  localparam [9:0] W_X2 = 10'd227;  // W_X + 10

  wire w_shape2;
  U_shape w2(pix_x, pix_y, W_X2, y_pos, w_shape2);

  assign draw_player = show_player && (u_shape || w_shape || w_shape2);
endmodule

// drawing the actual U that we use 3 times
module U_shape (
  input  wire [9:0] pix_x,
  input  wire [9:0] pix_y,
  input wire [9:0] x_pos,
  input  wire [9:0] y_pos,
  output wire draw_U
);

  assign draw_U =
        // Vertical legs (left & right)
    ((pix_x >= x_pos - 5 && pix_x <= x_pos - 3) && (pix_y >= y_pos - 10 && pix_y <= y_pos + 2)) ||
    ((pix_x >= x_pos + 3 && pix_x <= x_pos + 5) && (pix_y >= y_pos - 10 && pix_y <= y_pos + 2)) ||

    // y = y_pos + 3:    ##    ##
    ((pix_y == y_pos + 3) &&
        ((pix_x >= x_pos - 4 && pix_x <= x_pos - 3) ||
         (pix_x >= x_pos + 3 && pix_x <= x_pos + 4))) ||

    // y = y_pos + 4:     ##  ##
    ((pix_y == y_pos + 4) &&
        ((pix_x >= x_pos - 3 && pix_x <= x_pos - 2) ||
         (pix_x >= x_pos + 2 && pix_x <= x_pos + 3))) ||

    // y = y_pos + 5:      ####
    ((pix_y == y_pos + 5) &&
         (pix_x >= x_pos - 2 && pix_x <= x_pos + 2));

endmodule
// end of UW player module

// ─────────────────────────────────────────────
// Scene: Moving sine waves with fixed constants
// ─────────────────────────────────────────────
// this module just sets up the drawing of the double sine wave, it doesn't actually do any drawing itself
module create_game_scene (
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire [9:0] x_offset,
    output wire draw_sin
);

  // Fixed constants - no calculations based on animation
  localparam [9:0] TOP_X = 10'd100;
  localparam [9:0] TOP_Y = 10'd180;
  localparam [9:0] BOTTOM_X = 10'd540;
  localparam [9:0] BOTTOM_Y = 10'd400;
  localparam [9:0] BAR_WIDTH = 10'd40;
  localparam [9:0] VISIBLE_WIDTH = 10'd25;
  localparam [9:0] HEIGHT = 10'd60;

  double_sin sin(
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
    .draw_double_sin(draw_sin)
  );

endmodule


// ─────────────────────────────────────────────
// Double Sine Wave
// ─────────────────────────────────────────────
module double_sin (
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire [9:0] x_offset,
    input  wire [9:0] top_x,
    input  wire [9:0] top_y,
    input  wire [9:0] bottum_x,
    input  wire [9:0] bottum_y,
    input  wire [9:0] bar_width,
    input  wire [9:0] visible_width,
    input  wire [9:0] height,
    output wire draw_double_sin
);

  wire [3:0] addr = ((pix_x + x_offset)/bar_width) % 10;      // selects which of the 10 sine samples to use - will be used with LUT
  wire [7:0] sine_y;
  wire [9:0] bar_pos = (pix_x + x_offset) % bar_width;        // determines at which part of the width of the bar we're at (so we can leave a gap)

  sine_lut lut(.pos(addr), .sin_output(sine_y));              // fetch the sine height from the LUT

  // build top and bottom sin wave
  wire moving_sin_top    = (bar_pos < visible_width) &&
                           (top_y + 50 - sine_y + height > pix_y && pix_y > top_y);
  wire moving_sin_bottom = (bar_pos < visible_width) &&
                           (bottum_y > pix_y && pix_y > bottum_y - sine_y - height);
  
  // making sure the sin waves are drawin in the boundary
  assign draw_double_sin = ((moving_sin_top || moving_sin_bottom) &&
                            (top_x < pix_x  && pix_x < bottum_x)) &&
                           (top_y < pix_y  && pix_y < bottum_y);
endmodule


// ─────────────────────────────────────────────
// Sine Lookup Table
// ─────────────────────────────────────────────
// simple sine look up table
module sine_lut (
    input  wire [3:0] pos,        
    output reg  [7:0] sin_output  
);
  reg [7:0] sine_table[0:9];
  initial begin
    sine_table[0] = 50;
    sine_table[1] = 40;
    sine_table[2] = 30;
    sine_table[3] = 20;
    sine_table[4] = 10;
    sine_table[5] = 00;
    sine_table[6] = 10;
    sine_table[7] = 20;
    sine_table[8] = 30;
    sine_table[9] = 40;
  end
  always @(*) sin_output = sine_table[pos];
endmodule
