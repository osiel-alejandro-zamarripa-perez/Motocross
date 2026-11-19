`default_nettype none
// Decodifica los 2 switches de un jugador en el rumbo (dx,dy) de la moto.
// El motor carga este rumbo de golpe (sin girar poco a poco) una vez por cuadro.
//
// dir_sel = {sentido, eje}
//   eje=0 horizontal : sentido=0 DERECHA , sentido=1 IZQUIERDA
//   eje=1 vertical   : sentido=0 ABAJO   , sentido=1 ARRIBA
module dir_steer(
  input  wire[1:0] dir_sel,
  output wire[7:0] head_x,
  output wire[7:0] head_y
);
  localparam [7:0] POS = 8'd100;
  localparam [7:0] NEG = 8'd156;   // -100 en complemento a 2

  wire eje = dir_sel[0];
  wire sen = dir_sel[1];

  assign head_x = eje ? 8'd0 : (sen ? NEG : POS);
  assign head_y = eje ? (sen ? NEG : POS) : 8'd0;
endmodule
