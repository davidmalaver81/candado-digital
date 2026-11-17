// =============================================================
// candado_top.v
// Módulo principal: conecta los periféricos de la Nexys 4
// con la FSM del candado.
//
//   Entradas : sw[3:0] (dígito), btnc (ingresar), btnd (reiniciar)
//   Salidas  : led[0]   -> ACCESO PERMITIDO
//              led[1]   -> ACCESO DENEGADO
//              led[4:2] -> progreso (cuántos dígitos se han ingresado)
// =============================================================
module candado_top #(
    parameter [11:0] CLAVE           = 12'h5A3,
    parameter        CICLOS_ESTABLE  = 2_000_000   // 20 ms a 100 MHz
)(
    input  wire       clk,     // reloj de 100 MHz de la tarjeta
    input  wire [3:0] sw,      // switches SW3..SW0
    input  wire       btnc,    // botón central: ingresar dígito
    input  wire       btnd,    // botón inferior: reiniciar
    output wire [4:0] led      // LD4..LD0
);

    // ---- Bloque de entrada ----
    // Los switches también se sincronizan con el reloj (buena práctica).
    reg [3:0] sw_s0 = 4'd0;
    reg [3:0] sw_s1 = 4'd0;
    always @(posedge clk) begin
        sw_s0 <= sw;
        sw_s1 <= sw_s0;
    end

    wire pulso_ingresar;
    wire pulso_reiniciar;

    boton_limpio #(.CICLOS_ESTABLE(CICLOS_ESTABLE)) u_btn_ingresar (
        .clk    (clk),
        .btn_in (btnc),
        .pulso  (pulso_ingresar)
    );

    boton_limpio #(.CICLOS_ESTABLE(CICLOS_ESTABLE)) u_btn_reiniciar (
        .clk    (clk),
        .btn_in (btnd),
        .pulso  (pulso_reiniciar)
    );

    // ---- Lógica de control (FSM) ----
    wire       permitido;
    wire       denegado;
    wire [1:0] ingresados;

    candado_fsm #(.CLAVE(CLAVE)) u_fsm (
        .clk        (clk),
        .reiniciar  (pulso_reiniciar),
        .ingresar   (pulso_ingresar),
        .digito     (sw_s1),
        .permitido  (permitido),
        .denegado   (denegado),
        .ingresados (ingresados)
    );

    // ---- Bloque de salida (LEDs) ----
    assign led[0] = permitido;
    assign led[1] = denegado;
    assign led[2] = (ingresados >= 2'd1);   // 1er dígito confirmado
    assign led[3] = (ingresados >= 2'd2);   // 2do dígito confirmado
    assign led[4] = (ingresados >= 2'd3);   // 3er dígito confirmado

endmodule
