# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


# Inspired by https://github.com/MichaelBell/tt05-spi-peripheral/blob/main/src/test.py

async def apa102_clock_cycle(dut):
    await Timer(62, "ns")
    dut.apa102_sck.value = 0
    await Timer(125, "ns") # 8MHz
    dut.apa102_sck.value = 1
    await Timer(63, "ns")

async def apa102_send(dut, data):
    for d in data:
        for i in range(32):
            dut.apa102_sda.value = 1 if (d & 0x80000000) != 0 else 0
            d <<= 1
            await apa102_clock_cycle(dut)
    

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 40 ns (25 MHz)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.apa102_sck.value = 1
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test

    test_string = [0x00000000, 0xdeadbeef, 0xd0d0cafe, 0xfeedface, 0xdecea5ed, 0x01234567, 0x89abcdef, 0xdecafbad, 0xffffffff]

    await apa102_send(dut, test_string) 


    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    
    # These tests dig too far into the internals and so they don't work the GL tests.
    # Uncomment for local testing with `make -B`...
    # assert dut.user_project.spi_in.data_out.value == 0xadbeefd0cafeedfacecea5ed234567abcdefcafbad

    # assert dut.user_project.ws2812_out.data.value == 0xbeefadcafed0faceeda5edce456723cdefabfbadca

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.

    await Timer(500, "us")
