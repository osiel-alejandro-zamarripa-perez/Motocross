# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start VGA Motorcycle Racing Game test")

    # Reloj VGA (~25 MHz -> periodo de 40 ns)
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset inicial
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Verificar que los pines bidireccionales queden configurados como entradas
    assert int(dut.uio_oe.value) == 0
    assert int(dut.uio_out.value) == 0

    # Configurar pista 1, velocidad 1 y direccion del jugador 1
    dut.uio_in.value = 0b00000101
    dut.ui_in.value = 0b00000001

    # Avanzar al pulso activo de HSYNC en la primera linea (pix_x ~ 660, blanking activo)
    # uo_out = {hsync, B0, G0, R0, vsync, B1, G1, R1} -> hsync=0, vsync=1, RGB=0 -> 0x08
    await ClockCycles(dut.clk, 660)
    assert int(dut.uo_out.value) == 0x08, f"Se esperaba uo_out=0x08 durante HSYNC activo, se obtuvo {dut.uo_out.value}"

    # Avanzar fuera del pulso HSYNC (pix_x ~ 760, sigue en blanking)
    # hsync=1, vsync=1, RGB=0 -> 0x88
    await ClockCycles(dut.clk, 100)
    assert int(dut.uo_out.value) == 0x88, f"Se esperaba uo_out=0x88 tras finalizar HSYNC, se obtuvo {dut.uo_out.value}"
