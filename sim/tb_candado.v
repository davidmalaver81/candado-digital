`timescale 1ns / 1ps
// =============================================================
// tb_candado.v
// Testbench: simula a un usuario marcando claves en los switches
// y presionando los botones. Revisa que los LEDs respondan bien.
// Clave configurada: 5, A, 3
// =============================================================
module tb_candado;

    reg        clk  = 1'b0;
    reg  [3:0] sw   = 4'd0;
    reg        btnc = 1'b0;
    reg        btnd = 1'b0;
    wire [4:0] led;

    integer errores = 0;

    // En simulación el anti-rebote usa solo 4 ciclos (no 20 ms)
    candado_top #(
        .CLAVE          (12'h5A3),
        .CICLOS_ESTABLE (4)
    ) dut (
        .clk  (clk),
        .sw   (sw),
        .btnc (btnc),
        .btnd (btnd),
        .led  (led)
    );

    // Reloj de 100 MHz (periodo 10 ns)
    always #5 clk = ~clk;

    // Espera N ciclos de reloj
    task esperar(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) @(posedge clk);
        end
    endtask

    // Marca un dígito en los switches y presiona "ingresar"
    task ingresar_digito(input [3:0] d);
        begin
            sw = d;
            esperar(5);
            btnc = 1'b1;  esperar(20);
            btnc = 1'b0;  esperar(20);
        end
    endtask

    // Presiona "reiniciar"
    task reiniciar;
        begin
            btnd = 1'b1;  esperar(20);
            btnd = 1'b0;  esperar(20);
        end
    endtask

    // Compara el valor de los LEDs de resultado con lo esperado
    task revisar(input permitido_esp, input denegado_esp, input [255:0] nombre);
        begin
            if (led[0] !== permitido_esp || led[1] !== denegado_esp) begin
                $display("FALLO  [%0s]: led[0]=%b (esperado %b), led[1]=%b (esperado %b)",
                         nombre, led[0], permitido_esp, led[1], denegado_esp);
                errores = errores + 1;
            end else begin
                $display("OK     [%0s]: permitido=%b denegado=%b", nombre, led[0], led[1]);
            end
        end
    endtask

    initial begin
        $dumpfile("candado.vcd");
        $dumpvars(0, tb_candado);

        esperar(10);

        // ---- Prueba 1: estado inicial ----
        revisar(1'b0, 1'b0, "inicio");

        // ---- Prueba 2: clave correcta (5, A, 3) ----
        ingresar_digito(4'h5);
        revisar(1'b0, 1'b0, "tras 1er digito");
        ingresar_digito(4'hA);
        revisar(1'b0, 1'b0, "tras 2do digito");
        ingresar_digito(4'h3);
        esperar(5);
        revisar(1'b1, 1'b0, "clave correcta");

        // ---- Prueba 3: reiniciar vuelve a ESPERA ----
        reiniciar;
        revisar(1'b0, 1'b0, "tras reiniciar");

        // ---- Prueba 4: último dígito incorrecto (5, A, 4) ----
        ingresar_digito(4'h5);
        ingresar_digito(4'hA);
        ingresar_digito(4'h4);
        esperar(5);
        revisar(1'b0, 1'b1, "ultimo digito malo");
        reiniciar;

        // ---- Prueba 5: primer dígito incorrecto (1, A, 3) ----
        ingresar_digito(4'h1);
        ingresar_digito(4'hA);
        ingresar_digito(4'h3);
        esperar(5);
        revisar(1'b0, 1'b1, "primer digito malo");

        // ---- Prueba 6: en DENEGADO, otra pulsación no abre ----
        sw = 4'h5;
        ingresar_digito(4'h5);
        revisar(1'b0, 1'b1, "sigue denegado");
        reiniciar;

        // ---- Prueba 7: clave correcta otra vez después de fallar ----
        ingresar_digito(4'h5);
        ingresar_digito(4'hA);
        ingresar_digito(4'h3);
        esperar(5);
        revisar(1'b1, 1'b0, "correcta tras reinicio");

        if (errores == 0)
            $display("=== TODAS LAS PRUEBAS PASARON ===");
        else
            $display("=== HUBO %0d FALLOS ===", errores);

        $finish;
    end

endmodule
