`timescale 1ns / 1ps
// =============================================================
// tb_candado_fsm.v  -  Prueba UNITARIA del módulo candado_fsm
// Los pulsos "ingresar" y "reiniciar" se generan directamente
// (un ciclo de reloj), sin pasar por el anti-rebote.
// Clave: 5, A, 3
// =============================================================
module tb_candado_fsm;

    reg        clk       = 1'b0;
    reg        reiniciar = 1'b0;
    reg        ingresar  = 1'b0;
    reg  [3:0] digito    = 4'd0;
    wire       permitido;
    wire       denegado;
    wire [1:0] ingresados;

    integer errores = 0;

    candado_fsm #(.CLAVE(12'h5A3)) dut (
        .clk        (clk),
        .reiniciar  (reiniciar),
        .ingresar   (ingresar),
        .digito     (digito),
        .permitido  (permitido),
        .denegado   (denegado),
        .ingresados (ingresados)
    );

    always #5 clk = ~clk;

    // Las entradas cambian en el flanco de bajada para evitar carreras
    task ciclos(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) @(negedge clk);
        end
    endtask

    task enviar_digito(input [3:0] d);
        begin
            @(negedge clk);
            digito   = d;
            ingresar = 1'b1;
            @(negedge clk);
            ingresar = 1'b0;
        end
    endtask

    task pulso_reiniciar;
        begin
            @(negedge clk);
            reiniciar = 1'b1;
            @(negedge clk);
            reiniciar = 1'b0;
            ciclos(1);
        end
    endtask

    task revisar(input p, input d, input [1:0] i, input [255:0] nombre);
        begin
            if (permitido !== p || denegado !== d || ingresados !== i) begin
                $display("FALLO  [%0s]: perm=%b den=%b ingr=%0d (esperado %b %b %0d)",
                         nombre, permitido, denegado, ingresados, p, d, i);
                errores = errores + 1;
            end else
                $display("OK     [%0s]: perm=%b den=%b ingr=%0d", nombre, permitido, denegado, ingresados);
        end
    endtask

    initial begin
        $dumpfile("candado_fsm.vcd");
        $dumpvars(0, tb_candado_fsm);

        ciclos(3);
        revisar(0, 0, 0, "estado inicial");

        // Clave correcta paso a paso
        enviar_digito(4'h5);  ciclos(1);
        revisar(0, 0, 1, "1er digito correcto");
        enviar_digito(4'hA);  ciclos(1);
        revisar(0, 0, 2, "2do digito correcto");
        enviar_digito(4'h3);  ciclos(3);
        revisar(1, 0, 3, "clave correcta");

        // En ABIERTO, nuevas entradas no cambian el estado
        enviar_digito(4'h0);  ciclos(3);
        revisar(1, 0, 3, "abierto ignora entradas");

        // Reiniciar desde ABIERTO
        pulso_reiniciar;
        revisar(0, 0, 0, "reinicio desde abierto");

        // Ultimo digito incorrecto
        enviar_digito(4'h5);
        enviar_digito(4'hA);
        enviar_digito(4'h4);  ciclos(3);
        revisar(0, 1, 3, "ultimo digito malo");

        // En DENEGADO, ingresar el digito "correcto" no abre
        enviar_digito(4'h5);  ciclos(3);
        revisar(0, 1, 3, "denegado ignora entradas");
        pulso_reiniciar;
        revisar(0, 0, 0, "reinicio desde denegado");

        // Primer digito incorrecto
        enviar_digito(4'h1);
        enviar_digito(4'hA);
        enviar_digito(4'h3);  ciclos(3);
        revisar(0, 1, 3, "primer digito malo");
        pulso_reiniciar;

        // Digito del medio incorrecto (el error se recuerda)
        enviar_digito(4'h5);
        enviar_digito(4'hB);
        enviar_digito(4'h3);  ciclos(3);
        revisar(0, 1, 3, "digito medio malo");
        pulso_reiniciar;

        // Reiniciar a mitad de la secuencia borra el progreso
        enviar_digito(4'h5);  ciclos(1);
        revisar(0, 0, 1, "progreso antes de reiniciar");
        pulso_reiniciar;
        revisar(0, 0, 0, "reinicio a mitad");
        enviar_digito(4'h5);
        enviar_digito(4'hA);
        enviar_digito(4'h3);  ciclos(3);
        revisar(1, 0, 3, "clave correcta tras reinicio");

        if (errores == 0) $display("=== candado_fsm: TODAS LAS PRUEBAS PASARON ===");
        else              $display("=== candado_fsm: %0d FALLOS ===", errores);
        $finish;
    end

endmodule
