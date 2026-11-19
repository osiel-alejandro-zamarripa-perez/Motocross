/*

 * Copyright (c) 2024 Uri Shaked

 * SPDX-License-Identifier: Apache-2.0

 */



`default_nettype none



module tt_um_KK_VGA01(

  input  wire [7:0] ui_in,    // Dedicated inputs

  output wire [7:0] uo_out,   // Dedicated outputs

  input  wire [7:0] uio_in,   // IOs: Input path

  input  wire [7:0] dir_in,   // Direccion por jugador: {P4,P3,P2,P1}, cada uno {sentido,eje}

  output wire [7:0] uio_out,  // IOs: Output path

  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)

  input  wire       ena,      // always 1 when the design is powered, so you can ignore it

  input  wire       clk,      // clock

  input  wire       rst_n     // reset_n - low to reset

);



  // VGA signals

  wire hsync;

  wire vsync;

  wire [1:0] R;

  wire [1:0] G;

  wire [1:0] B;

  wire video_active;

  wire [9:0] pix_x;

  wire [9:0] pix_y;



  // TinyVGA PMOD

  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};



  // Unused outputs assigned to 0.

  assign uio_out = 8'b00000000;

  assign uio_oe  = 8'b00000000;



  wire [1:0] game_track = uio_in[1:0];

  wire [1:0] game_speed = uio_in[3:2];



  wire hard_reset = ~rst_n;

  wire user_reset = ui_in[4];

  wire gameplay_reset = hard_reset | user_reset;



  // Suppress unused signals warning

  wire _unused_ok = &{ena, ui_in[7:5], ui_in[3:0], uio_in[7:4]};



  hvsync_generator hvsync_gen(

    .clk(clk),

    .reset(~rst_n),

    .hsync(hsync),

    .vsync(vsync),

    .display_on(video_active),

    .hpos(pix_x),

    .vpos(pix_y)

  );



  wire trkon;

  track_gen track(

    .hpos(pix_x),

    .vpos(pix_y),

    .clk(clk),

    .game_track(game_track),

    .trkout(trkon)

  );



  // verilator lint_off UNOPTFLAT

  wire[14:0] mt_ctrl;

  // verilator lint_on UNOPTFLAT

  motor_handler mctrl(

    .hpos(pix_x),

    .vpos(pix_y),

    .hsync(hsync),

    .vsync(vsync),

    .clk(clk),

    .reset(gameplay_reset),

    .game_speed(game_speed),

    .ctrl(mt_ctrl)

  );



  // Rumbo instantaneo por jugador (ver dir_steer.v)
  wire [7:0] hx1,hy1,hx2,hy2,hx3,hy3,hx4,hy4;
  dir_steer ds1(.dir_sel(dir_in[1:0]), .head_x(hx1), .head_y(hy1));
  dir_steer ds2(.dir_sel(dir_in[3:2]), .head_x(hx2), .head_y(hy2));
  dir_steer ds3(.dir_sel(dir_in[5:4]), .head_x(hx3), .head_y(hy3));
  dir_steer ds4(.dir_sel(dir_in[7:6]), .head_x(hx4), .head_y(hy4));

  // Pulso de carga: una vez por cuadro, en vpos=0 (el anillo dx/dy esta quieto)
  reg ld;
  always @(posedge clk) begin
    ld <= (pix_y == 10'd0) && (pix_x == 10'd4);
  end

  wire [3:0] steer = 4'b0000;   // el giro progresivo ya no se usa

  wire gt0 = game_track[0];

  wire gt1 = game_track[1];

  wire gt_or   = gt1 | gt0;

  wire gt_and  = gt1 & gt0;

  wire gt_xor  = gt1 ^ gt0;

  wire gt_xnor = ~gt_xor;

  wire gt_nor  = ~gt_or;

  wire ngt0 = ~gt0;

  wire ngt1 = ~gt1;



  wire [9:0] reset_y1 = {1'b0, 1'b1, 1'b0,  ~gt_and, gt_xnor, gt0,  4'b0000};

  wire [9:0] reset_y2 = {1'b0, 1'b1, 1'b0,   1'b1,   ngt1,    ngt0, 4'b0000};

  wire [9:0] reset_y3 = {1'b0, 1'b1, gt_nor, gt_or,  gt_xor,  gt0,  4'b0000};

  wire [9:0] reset_y4 = {1'b0, 1'b1, ngt1,   gt1,    gt1,     ngt0, 4'b0000};



  wire sp1on, sp2on, sp3on, sp4on;

  motor_core motor1( .RESET_Y(reset_y1), .game_speed(game_speed), .ctrl(mt_ctrl), .clk(clk), .steer(steer[0]), .hpos(pix_x), .vpos(pix_y), .hsync(hsync), .track_in(trkon), .spron(sp1on), .ld(ld), .ld_x(hx1), .ld_y(hy1) );

  motor_core motor2( .RESET_Y(reset_y2), .game_speed(game_speed), .ctrl(mt_ctrl), .clk(clk), .steer(steer[1]), .hpos(pix_x), .vpos(pix_y), .hsync(hsync), .track_in(trkon), .spron(sp2on), .ld(ld), .ld_x(hx2), .ld_y(hy2) );

  motor_core motor3( .RESET_Y(reset_y3), .game_speed(game_speed), .ctrl(mt_ctrl), .clk(clk), .steer(steer[2]), .hpos(pix_x), .vpos(pix_y), .hsync(hsync), .track_in(trkon), .spron(sp3on), .ld(ld), .ld_x(hx3), .ld_y(hy3) );

  motor_core motor4( .RESET_Y(reset_y4), .game_speed(game_speed), .ctrl(mt_ctrl), .clk(clk), .steer(steer[3]), .hpos(pix_x), .vpos(pix_y), .hsync(hsync), .track_in(trkon), .spron(sp4on), .ld(ld), .ld_x(hx4), .ld_y(hy4) );



  wire mR = sp1on | sp4on;

  wire mG1 = sp2on | sp3on | sp4on;

  wire mG0 = sp2on | sp4on;

  wire mB = sp3on;

  // 1001xxxxx

  // 1010

  // 10011xxxx

  // 10100xxxx

  //wire goalmsk = pix_y[8] & ~trkon & pix_x[8] & ~pix_x[7] & (pix_x[5] ^ pix_x[6]);

  wire goalmsk = pix_y[8] & ~trkon & pix_x[8] & ~pix_x[7] & (pix_x[6] ^ pix_x[5]) & (pix_x[6] ^ pix_x[4]);

  wire goal = goalmsk & (pix_x[3] ^ pix_y[3]);

// Color Café para la pista (trkon): Rojo medio (2) + Verde bajo (1) + Azul (0)
  assign R = video_active ? {mR|trkon, mR|goal} : 2'b00;
  assign G = video_active ? {mG1, mG0|trkon|goal} : 2'b00;
  assign B = video_active ? {mB, mB|goal} : 2'b00;
  

  // Suppress unused signals warning

  //wire _unused_ok_ = &{moving_x, pix_y};



endmodule