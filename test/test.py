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

expected_U = [
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ], 
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ], 
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ], 
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ], 
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ], 
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ],  
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ], 
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ],  
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ], 
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ],
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ], 
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ], 
    [ 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1 ], 
    [ 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0 ],
    [ 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0 ],
    [ 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0 ]
]

async def test_U_at(x_coord, y_coord):
    height = len(expected_U)
    width = len(expected_U[0])

    dut.x_pos.value = x_coord
    dut.y_pos.value = y_coord
    
    for y in range(0, height):
        for x in range(0, width):
            dut.pix_x.value = x_coord - 5 +  x
            dut.pix_y.value = y_coord - 10 + y

            await Timer(1, units="ns")

            actual = bool(dut.draw_U.value)

            assert actual == bool(expected_U[y][x]), \
                f"ERROR: For for coords: ({x}, {y}, got {actual}, expected {bool(expected_U[y][x])})"
@cocotb.test()
async def test_player(dut):
    dut._log.info("Start player test")

    

    dut._log.info("player passed")

@cocotb.test()
async def test_U_shape(dut):
    dut._log.info("Start U_shape test")
    
    test_U_at(100, 100)
    
    dut._log.info("U_shape passed")

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
    
    for x_offset in range(0, 400, 20):
        for pix_x in range(TOP_X+1, BOTTOM_X):
            for pix_y in range(TOP_Y+1, BOTTOM_Y):
                sin_height = SINE_VALUES_TABLE[((pix_x + x_offset)//BAR_WIDTH) % 10]
                correct_y_pos = (TOP_Y + 50 - sin_height + HEIGHT > pix_y) or (pix_y > BOTTOM_Y - sin_height - HEIGHT)
                correct_x_pos = (pix_x + x_offset) % BAR_WIDTH < VISIBLE_WIDTH

                dut.pix_x.value = pix_x
                dut.pix_y.value = pix_y
                dut.x_offset.value = x_offset

                await Timer(1, units="ns")

                actual = bool(dut.draw_double_sin.value)

                assert actual == (correct_y_pos and correct_x_pos), \
                f"ERROR: For x_offset {x_offset}, got {actual}, expected {correct_y_pos and correct_x_pos} for coords: ({pix_x}, {pix_y})"

            dut._log.info(f"on offset: {x_offset}, on row: {pix_x}")
                
                
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
