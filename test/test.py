# SPDX-FileCopyrightText: © 2025 AravindakshanGA
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_gcd_finder(dut):
    dut._log.info("Starting GCD Finder Test")

    # Set up the clock with a period of 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset the DUT
    dut._log.info("Resetting DUT")
    dut.ena.value = 1  # Enable the design
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    dut._log.info("Reset DUT Done")

    # Set test inputs for two 64-bit numbers
    num_a = 56  # Example 64-bit number (can be replaced with any value)
    num_b = 98  # Example 64-bit number (can be replaced with any value)

    # Loading the first input (INPUT_A) 8 bits at a time
    dut._log.info("Loading INPUT_A")
    for i in range(8):
        dut.ui_in.value = (num_a >> (i * 8)) & 0xFF  # Extract 8-bit chunk
        await ClockCycles(dut.clk, 1)
        dut._log.info(f"Loaded INPUT_A[{i}]: {hex((num_a >> (i * 8)) & 0xFF)}")

    # Loading the second input (INPUT_B) 8 bits at a time
    dut._log.info("Loading INPUT_B")
    for i in range(8):
        dut.ui_in.value = (num_b >> (i * 8)) & 0xFF  # Extract 8-bit chunk
        await ClockCycles(dut.clk, 1)
        dut._log.info(f"Loaded INPUT_B[{i}]: {hex((num_b >> (i * 8)) & 0xFF)}")

    # Assert the start signal to begin computation
    dut._log.info("Asserting start signal")
    dut.uio_in.value = 0b00000001  # Set IO[0] (start signal)
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0b00000000  # Clear IO[0] after 1 cycle

    # Wait for computation to complete (monitor IO[4] for a ready signal)
    dut._log.info("Waiting for computation to complete")
    while (dut.uio_out.value & 0b00010000) == 0:  # Wait for IO[4] to go high
        await ClockCycles(dut.clk, 1)

    # Read back the result (OUTPUT) 8 bits at a time
    dut._log.info("Reading the GCD result")
    gcd_result = 0
    for i in range(8):
        gcd_result |= (int(dut.uo_out.value) & 0xFF) << (i * 8)
        dut._log.info(f"GCD result byte[{i}]: {hex(int(dut.uo_out.value) & 0xFF)}")
        await ClockCycles(dut.clk, 1)

    # Calculate the expected GCD
    expected_gcd = gcd(num_a, num_b)
    dut._log.info(f"Computed GCD: {gcd_result}, Expected GCD: {expected_gcd}")

    # Assert the result matches the expected value
    assert gcd_result == expected_gcd, f"GCD mismatch: {gcd_result} != {expected_gcd}"


def gcd(a, b):
    """Helper function to calculate the GCD of two numbers."""
    while b:
        a, b = b, a % b
    return a
