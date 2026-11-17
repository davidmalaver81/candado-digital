// =============================================================
// boton_limpio.v
// Acondiciona un botón mecánico para usarlo dentro de la FPGA:
//   1) Sincroniza la señal con el reloj (2 flip-flops).
//   2) Filtra los rebotes: el valor solo cambia si se mantiene
//      estable durante CICLOS_ESTABLE ciclos de reloj.
//   3) Entrega un pulso de UN ciclo cada vez que se presiona.
// =============================================================
module boton_limpio #(
    // 2_000_000 ciclos a 100 MHz = 20 ms (valor típico anti-rebote).
    // En simulación se sobreescribe con un número pequeño.
    parameter CICLOS_ESTABLE = 2_000_000
)(
    input  wire clk,
    input  wire btn_in,    // señal cruda del botón
    output wire pulso      // 1 ciclo en alto por cada pulsación
);

    // --- 1) Sincronizador ---
    reg sync0 = 1'b0;
    reg sync1 = 1'b0;

    // --- 2) Filtro de rebotes ---
    reg [20:0] contador = 21'd0;   // 21 bits alcanzan para 2_000_000
    reg        estable  = 1'b0;    // valor ya "limpio" del botón

    // --- 3) Detector de flanco de subida ---
    reg        estable_previo = 1'b0;

    always @(posedge clk) begin
        sync0 <= btn_in;
        sync1 <= sync0;

        if (sync1 == estable) begin
            contador <= 21'd0;                 // sin cambio: reinicia la cuenta
        end else if (contador == CICLOS_ESTABLE - 1) begin
            estable  <= sync1;                 // cambio confirmado
            contador <= 21'd0;
        end else begin
            contador <= contador + 1'b1;       // sigue contando mientras sea distinto
        end

        estable_previo <= estable;
    end

    assign pulso = estable & ~estable_previo;

endmodule
