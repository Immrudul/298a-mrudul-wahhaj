# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import Timer

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

TOP_X        = 100
TOP_Y        = 180
BOTTOM_X     = 540
BOTTOM_Y     = 400
BAR_WIDTH    = 40
VISIBLE_WIDTH= 25
HEIGHT       = 60

@cocotb.test()
async def test_double_sin(dut):
    dut._log.info("Start double_sin test")
    
    for x_offset in range(0, 400):
        for pix_x in range(TOP_X, BOTTOM_X):
            for pix_y in range(TOP_Y, BOTTOM_Y):
                sin_height = SINE_VALUES_TABLE[((pix_x + x_offset)//BAR_WIDTH) % 10]
                correct_y_pos = (TOP_Y + 50 - sin_height + HEIGHT > pix_y) or (pix_y > BOTTOM_Y - sin_height - HEIGHT)
                correct_x_pos = (pix_x + x_offset) % BAR_WIDTH < VISIBLE_WIDTH

                dut.pix_x.value = pix_x
                dut.pix_y.value = pix_y
                dut.x_offset.value = x_offset

                await Timer(1, units="ns")

                actual = bool(dut.draw_double_sin.value)

                assert actual == (correct_y_pos and correct_x_pos) \
                f"ERROR: For x_offset {x_offset}, got {actual}, expected {correct_y_pos and correct_x_pos} for coords: ({pix_x}, {pix_y})"
                
                
    dut._log.info("double_sin passed")
    

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
