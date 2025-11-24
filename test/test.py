# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

SINE_VALUES_TABLE = {
    0: 50,
    1: 40,
    2: 30,
    3: 20,
    4: 10,
    5: 0,
    6: 10,
    7: 20,
    8: 30,
    9: 40
}


@cocotb.test()
async def test_sine_lut(dut):
    dut._log.info("Start sine_lut test")

    # Test only defined LUT positions 0–9
    for index, value in SINE_VALUES_TABLE.items():
        dut.tb_pos.value = index

        # No clock in this module → allow time to settle
        await Timer(1, units="ns")

        actual = int(dut.tb_sin_output.value)
        dut._log.info(f"pos={index} → sin_output={actual}, value={value}")

        assert actual == value, \
            f"ERROR: For index {index}, got {actual}, value {value}"

    dut._log.info("sine_lut passed")
