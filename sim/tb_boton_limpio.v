`timescale 1ns / 1ps
// =============================================================
// tb_boton_limpio.v  -  Prueba UNITARIA del módulo boton_limpio
// Anti-rebote reducido a 4 ciclos para que la simulación sea corta.
// =============================================================
module tb_boton_limpio;

    reg  clk = 1'b0;
    reg  btn = 1'b0;
    wire pulso;

    integer errores = 0;
    integer cuenta  = 0;      // pulsos de salida observados

    boton_limpio #(.CICLOS_ESTABLE(4)) dut (
        .clk    (clk),
        .btn_in (btn),
        .pulso  (pulso)
    );

    always #5 clk = ~clk;

    always @(posedge clk)
        if (pulso) cuenta <= cuenta + 1;

    task esperar(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) @(posedge clk);
        end
    endtask

    task revisar(input integer esperado, input [255:0] nombre);
        begin
            if (cuenta !== esperado) begin
                $display("FALLO  [%0s]: pulsos=%0d (esperado %0d)", nombre, cuenta, esperado);
                errores = errores + 1;
            end else
                $display("OK     [%0s]: pulsos=%0d", nombre, cuenta);
        end
    endtask

    initial begin
        $dumpfile("boton_limpio.vcd");
        $dumpvars(0, tb_boton_limpio);

        esperar(10);
        revisar(0, "reposo sin pulsar");

        // Pulsación limpia: debe dar exactamente 1 pulso
        btn = 1'b1;  esperar(20);
        revisar(1, "pulsacion estable");

        // Mantener presionado no genera pulsos nuevos
        esperar(20);
        revisar(1, "boton mantenido");

        // Soltar no genera pulso
        btn = 1'b0;  esperar(20);
        revisar(1, "al soltar");

        // Rebote corto (2 ciclos) debe ignorarse
        btn = 1'b1;  esperar(2);
        btn = 1'b0;  esperar(2);
        btn = 1'b1;  esperar(2);
        btn = 1'b0;  esperar(20);
        revisar(1, "rebote ignorado");

        // Rebotes seguidos de una pulsación estable: solo 1 pulso nuevo
        btn = 1'b1;  esperar(1);
        btn = 1'b0;  esperar(1);
        btn = 1'b1;  esperar(1);
        btn = 1'b0;  esperar(1);
        btn = 1'b1;  esperar(20);
        btn = 1'b0;  esperar(20);
        revisar(2, "rebotes y pulsacion");

        if (errores == 0) $display("=== boton_limpio: TODAS LAS PRUEBAS PASARON ===");
        else              $display("=== boton_limpio: %0d FALLOS ===", errores);
        $finish;
    end

endmodule
