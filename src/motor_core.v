
`default_nettype none





module sprite_dly(

  input wire  start,

  input wire  sclk,

  output wire spon

);

  // 000->000

  // 001->010->101->011->111->110->100

  //  00x 0 0

  //  01x 1 1

  //  11x 0 0

  //  10x 0 1

  reg[2:0] st;

  always @(posedge sclk) begin

      st <= {st[1:0], (~st[2] & st[1]) | (st[2] & ~st[1] & st[0]) | start};

  end

  assign spon = |{st};

endmodule



module adc_1bit(

  input wire      ain,

  input wire      bin,

  input wire      cin,

  input wire[2:0] mode,   // Echo | Sub | Start

  input wire      aclk,

  output wire     yout

);

  // Operations:

  //  out = A+B+C     C<-C1  E<-B   ADD

  //  out = A+B+0     C<-C1         ADD start

  //  out = A+~B+C    C<-C1         SUB

  //  out = A+~B+1    C<-C1         SUB start



  wire start = mode[0];

  wire sub = mode[1];

  wire echo = mode[2];

  reg prevC;

  reg prevB;



  wire asrc = ain;

  wire bsrc = (echo ? prevB : bin ^ sub);

  wire csrc = start ? cin ^ sub : prevC;

  wire[1:0] sum = asrc + bsrc + csrc;



  always @(posedge aclk) begin

    prevC <= sum[1];

    prevB <= bsrc;

  end

  assign yout = sum[0];



endmodule



    module motor_core(

  input  wire[9:0]  RESET_Y,

  input  wire[1:0]  game_speed,

  input  wire[14:0] ctrl,

  input  wire       clk,

  input  wire       steer,

  input  wire[9:0]  hpos,

  input  wire[9:0]  vpos,

  input  wire       hsync,

  input  wire       track_in,

  output wire       spron,
  input  wire       ld,       // pulso: cargar rumbo instantaneo
  input  wire[7:0]  ld_x,     // rumbo X a cargar (signed)
  input  wire[7:0]  ld_y      // rumbo Y a cargar (signed, +y = abajo)
);

  // Input signal decoding

  wire[9:0] RESET_X = 320;

  wire r = ctrl[0];   // reset

  wire nr = ~r;

  wire dxy_mask = ctrl[5];

  wire dxy_clk = (ctrl[1] & (r | steer | ~dxy_mask)) | ld;

  wire[2:0] dxy_mode = ctrl[4:2];

  wire[3:0] mov_gate = ctrl[12:9];

  wire mov_clk = ctrl[6] & |{mov_gate & speed, r} & alive;

  wire spd_clk = ctrl[13];

  wire deathmask = ctrl[14];



  // Alive

  reg alive;

  always @(posedge clk) begin

    alive <= (alive & ~(spron & track_in)) | r;

  end



  // Speed handling

  // Velocidad CONSTANTE segun game_speed (sin aceleracion automatica)
  //   game_speed: 00 -> 3 , 01 -> 5 , 10 -> 10 , 11 -> 15  (pasadas de movimiento por cuadro)
  reg[3:0] speed;
  always @* begin
    case (game_speed)
      2'b00: speed = 4'd3;
      2'b01: speed = 4'd5;
      2'b10: speed = 4'd10;
      default: speed = 4'd15;
    endcase
  end
  wire spd_unused_ = &{spd_clk, steer};

  // Position handling

  reg[13:0] xp;

  reg[12:0] yp;

  wire[13:0] xp_rst = {RESET_X[9:0], 4'b0000};

  wire[12:0] yp_rst = {RESET_Y[8:0], 4'b0000};

  wire xy_adcout;

  adc_1bit xy_adc(

    .ain(yp[0]),

    .bin(dy[3]),

    .cin(dy[2]),

    .mode({ctrl[8],1'b0,ctrl[7]}),    // Echo | ADD | Start

    .aclk(mov_clk),

    .yout(xy_adcout)

  );

  always @(posedge mov_clk) begin

    yp <= ({xp[0],yp[12:1]} | {{13{r}} & yp_rst}) & {{13{nr}} | yp_rst};

    xp <= ({xy_adcout,xp[13:1]} | {{14{r}} & xp_rst}) & {{14{nr}} | xp_rst};

  end



  // DX/DY handling

  reg[7:0] dx;

  reg[7:0] dy;

  wire dxy_adcout;

  adc_1bit dxy_adc(

    .ain(dy[0]),

    .bin(dx[5] & dxy_mask),

    .cin(dx[4] & dxy_mask),

    .mode(dxy_mode),

    .aclk(dxy_clk),

    .yout(dxy_adcout)

  );

  always @(posedge dxy_clk) begin
    if (ld & nr) begin
      dy <= ld_y;
      dx <= ld_x;
    end else begin
      dy <= {dx[0]&nr, dy[7]&nr, dy[6]&nr, dy[5]&nr, dy[4]&nr, dy[3]&nr, dy[2]&nr, dy[1]&nr};     // reset -> 0
      dx <= {dxy_adcout&nr, dx[7]|r, dx[6]|r, dx[5]&nr, dx[4]&nr, dx[3]|r, dx[2]&nr, dx[1]&nr};   // reset -> 01100100 (100)
    end
  end

  // Draw the sprite

  //wire[9:0] spx = {2'b00,dx};

  //wire[9:0] spy = {2'b00,dy};

  wire[9:0] spx = xp[13:4];

  wire[9:0] spy = {1'b0,yp[12:4]};



  wire spon_x, spon_y;

  sprite_dly stmr_x( .start(spx==hpos), .sclk(clk), .spon(spon_x));

  sprite_dly stmr_y( .start(spy==vpos), .sclk(hsync), .spon(spon_y));



  assign spron = (spon_x & spon_y) & (alive | deathmask);



  // Suppress unused signals warning

  wire _unused_ok_ = &{RESET_Y};



endmodule