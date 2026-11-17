# Candado Digital en Nexys 4 (Verilog)

Prototipo del anteproyecto: candado de 3 dígitos con switches, botones y LEDs.

## Cómo se usa en la tarjeta

| Elemento | Función |
|---|---|
| SW0 a SW3 | Dígito en binario (0 a F) |
| BTNC (central) | Confirma el dígito marcado |
| BTND (inferior) | Reinicia el candado |
| LD0 | Acceso permitido |
| LD1 | Acceso denegado |
| LD2, LD3, LD4 | Progreso: 1, 2 o 3 dígitos confirmados |

**Clave por defecto: 5, A, 3** (se cambia en el parámetro `CLAVE` de `candado_top.v`).

Ejemplo: pon SW3..SW0 = 0101 y pulsa BTNC; luego 1010 y BTNC; luego 0011 y BTNC. Se enciende LD0.

## Estructura

```
src/boton_limpio.v    Sincroniza, quita rebotes y genera un pulso por pulsación
src/candado_fsm.v     FSM: ESPERA -> VERIFICACION -> ABIERTO / DENEGADO
src/candado_top.v     Módulo principal (entrada -> FSM -> LEDs)
sim/tb_boton_limpio.v Prueba unitaria del anti-rebote
sim/tb_candado_fsm.v  Prueba unitaria de la FSM
sim/tb_candado.v      Prueba de integracion del sistema completo (candado_top)
constraints/nexys4.xdc  Pines de la tarjeta
```

## Pasos en Vivado

1. **Create Project** -> RTL Project. Parte: `xc7a100tcsg324-1`.
2. **Add Sources**: agrega los 3 archivos de `src/` como *Design Sources*, `sim/tb_candado.v` como *Simulation Source* y `nexys4.xdc` como *Constraints*.
3. Agrega los tres testbenches como *Simulation Sources*. Para cada uno: *Settings -> Simulation -> Simulation top module name* (`tb_boton_limpio`, `tb_candado_fsm` y `tb_candado`) y ejecuta cada simulacion por separado. Ejecuta **Run Simulation -> Run Behavioral Simulation**. En la consola Tcl debes ver `OK` en cada prueba y al final `=== TODAS LAS PRUEBAS PASARON ===`.
4. Define `candado_top` como Top del diseño. Ejecuta **Run Synthesis**, **Run Implementation** y **Generate Bitstream**.
5. **Open Hardware Manager** -> Auto Connect -> Program Device.

## Verificación automática (sin tarjeta ni Vivado)

El repositorio incluye un flujo de GitHub Actions (`.github/workflows/simulacion.yml`) que, en cada subida, instala Icarus Verilog y ejecuta los tres bancos de prueba. En la pestaña **Actions** se ve el registro de cada caso (`OK` o `FALLO`) y, al final de la ejecución, se pueden descargar los registros y las formas de onda (`.vcd`) como *Artifacts*.

## Antes de programar la tarjeta

- Confirma si tu tarjeta es la **Nexys 4** original o la **Nexys 4 DDR** (viene escrito en la placa). El `.xdc` usa los pines de la DDR; en la versión original los **botones** pueden tener otros pines. Revisa el Master XDC de Digilent de tu versión.
- Si no tienes un botón central cómodo, puedes cambiar `btnc`/`btnd` por otros botones en el `.xdc`.
