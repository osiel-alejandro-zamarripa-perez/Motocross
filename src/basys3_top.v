`timescale 1ns / 1ps
`default_nettype wire

module basys3_top (
    input clk,            // Reloj de 100MHz de la Basys 3
    input btnC,           // Botón central (Reset global)
    input btnU,           // Botón Arriba (Steer 3)
    input btnD,           // Botón Abajo (Steer 2)
    input btnL,           // Botón Izquierda (Steer 1)
    input btnR,           // Botón Derecha (Steer 0)
    input [15:0] sw,      // sw[4:0] = control del juego, sw[12:5] = direccion de los 4 jugadores, sw[15:13] libres
    input [3:0] ja,       // PMOD JA pines 1-4: botones externos J1..J4 (steer)
    
    // Salidas físicas VGA de la Basys 3
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output Hsync,
    output Vsync
);

    // 1. DIVISOR DE RELOJ: 100 MHz a 25 MHz para el VGA
    reg [1:0] clk_div = 0;
    wire clk_25m = clk_div[1];
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end

    // 2. MAPEO DE ENTRADAS AL FORMATO TINY TAPEOUT
    wire [7:0] ui_in;
    wire [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // Asignación de controles de la motocicleta a los botones
    // Cada jugador puede girar con su boton de la Basys 3 O con un boton externo en el PMOD JA
    assign ui_in[0] = btnR | ja[0]; // Jugador 1 (J1)
    assign ui_in[1] = btnL | ja[1]; // Jugador 2 (J2)
    assign ui_in[2] = btnD | ja[2]; // Jugador 3 (J3)
    assign ui_in[3] = btnU | ja[3]; // Jugador 4 (J4)
    
    // Switch 4 para el reset del usuario (según tu código)
    assign ui_in[4] = sw[4];
    assign ui_in[7:5] = 3'b000; // Sin uso

    // Configuración del juego a los switches
    assign uio_in[1:0] = sw[1:0]; // game_track
    assign uio_in[3:2] = sw[3:2]; // game_speed
    assign uio_in[7:4] = 4'b0000; // Sin uso

    // 3. INSTANCIA DE TU CÓDIGO ORIGINAL
    tt_um_KK_VGA01 motor_game (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .dir_in(sw[12:5]),  // {P4,P3,P2,P1} cada uno {sentido,eje}
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(1'b1),         // Siempre encendido
        .clk(clk_25m),      // Entra el reloj de 25MHz
        .rst_n(~btnC)       // Reset negado (btnC presionado = 0)
    );

    // 4. DESEMPAQUETADO DEL VGA Y ADAPTACIÓN A 12-BITS
    wire hsync_out = uo_out[7];
    wire vsync_out = uo_out[3];
    
    // Extraemos los colores (El bit 1 es el MSB según tu PMOD)
    wire [1:0] r_out = {uo_out[0], uo_out[4]};
    wire [1:0] g_out = {uo_out[1], uo_out[5]};
    wire [1:0] b_out = {uo_out[2], uo_out[6]};

    // La Basys 3 tiene 4 bits por color. Duplicamos los 2 bits para alcanzar el brillo máximo
    assign vgaRed   = {r_out, r_out};
    assign vgaGreen = {g_out, g_out};
    assign vgaBlue  = {b_out, b_out};
    
    assign Hsync = hsync_out;
    assign Vsync = vsync_out;

endmodule