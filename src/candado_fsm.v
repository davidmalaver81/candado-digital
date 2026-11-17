// =============================================================
// candado_fsm.v
// Máquina de estados finitos (FSM) del candado digital.
//
// La clave tiene 3 dígitos de 4 bits (un dígito = 4 switches).
// Cada pulsación del botón "ingresar" compara el dígito actual
// con el dígito que corresponde de la clave.
//
// Estados:
//   ESPERA       -> el usuario va ingresando los 3 dígitos
//   VERIFICACION -> se decide si la clave fue correcta
//   ABIERTO      -> acceso permitido (se sale con "reiniciar")
//   DENEGADO     -> acceso denegado  (se sale con "reiniciar")
// =============================================================
module candado_fsm #(
    // Clave: tres dígitos hexadecimales, se ingresan en este orden: 5, A, 3
    parameter [11:0] CLAVE = 12'h5A3
)(
    input  wire       clk,
    input  wire       reiniciar,   // pulso: vuelve a ESPERA
    input  wire       ingresar,    // pulso: confirma el dígito de los switches
    input  wire [3:0] digito,      // dígito marcado en los switches
    output wire       permitido,   // 1 cuando el estado es ABIERTO
    output wire       denegado,    // 1 cuando el estado es DENEGADO
    output wire [1:0] ingresados   // dígitos ya confirmados (0 a 3)
);

    // Codificación de estados
    localparam [1:0] ESPERA       = 2'd0,
                     VERIFICACION = 2'd1,
                     ABIERTO      = 2'd2,
                     DENEGADO     = 2'd3;

    reg [1:0] estado = ESPERA;
    reg [1:0] indice = 2'd0;   // cuántos dígitos se han ingresado
    reg       error  = 1'b0;   // se pone en 1 si algún dígito fue incorrecto

    // Dígito de la clave que toca comparar ahora (lógica combinacional)
    wire [3:0] esperado = (indice == 2'd0) ? CLAVE[11:8] :
                          (indice == 2'd1) ? CLAVE[7:4]  :
                                             CLAVE[3:0];

    // Registro de estado (lógica secuencial)
    always @(posedge clk) begin
        if (reiniciar) begin
            estado <= ESPERA;
            indice <= 2'd0;
            error  <= 1'b0;
        end else begin
            case (estado)
                ESPERA: begin
                    if (ingresar) begin
                        if (digito != esperado)
                            error <= 1'b1;            // recuerda que hubo un error
                        if (indice == 2'd2)
                            estado <= VERIFICACION;   // era el último dígito
                        else
                            indice <= indice + 1'b1;
                    end
                end

                VERIFICACION: begin
                    estado <= error ? DENEGADO : ABIERTO;
                end

                ABIERTO:  begin end   // se queda aquí hasta "reiniciar"
                DENEGADO: begin end   // se queda aquí hasta "reiniciar"

                default:  estado <= ESPERA;
            endcase
        end
    end

    // Salidas (dependen solo del estado actual)
    assign permitido   = (estado == ABIERTO);
    assign denegado    = (estado == DENEGADO);
    assign ingresados  = (estado == ESPERA) ? indice : 2'd3;

endmodule
