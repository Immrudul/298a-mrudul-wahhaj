import cocotb
from cocotb.triggers import Timer
import os

GL_MODE = bool(os.getenv("GL_TEST"))

SINE_VALUES_TABLE = {
    0: 50, 1: 40, 2: 30, 3: 20, 4: 10,
    5: 0, 6: 10, 7: 20, 8: 30, 9: 40
}

# ===============================
#  GL TEST: ONLY CHECK TOP MODULE
# ===============================
@cocotb.test()
async def gl_top_module_runs(dut):
    if not GL_MODE:
        return  # Skip in RTL mode

    dut._log.info("Running GL smoke test")

    dut.rst_n.value = 0
    await Timer(10, units="ns")
    dut.rst_n.value = 1
    await Timer(50, units="ns")

    dut._log.info("GL top-level test passed (smoke only)")


# ===============================
#  RTL TESTS BELOW THIS POINT
# ===============================
if not GL_MODE:

    expected_U = [...]
    expected_static_top_line = [...]

    @cocotb.test()
    async def test_static_top_line(dut):
        dut._log.info("Start static_top_line test")
        height = len(expected_static_top_line)
        width  = len(expected_static_top_line[0])

        for y in range(10, height * 8):
            for x in range(250, width * 8):
                dut.pix_x.value = x
                dut.pix_y.value = y
                await Timer(1, units="ns")

                actual = bool(dut.draw_line.value)
                expected = bool(expected_static_top_line[y//8][x//8])
                assert actual == expected

        dut._log.info("static_top_line passed")


    async def u_shape_helper(dut, x_coord, y_coord, isUW):
        height = len(expected_U)
        width  = len(expected_U[0])

        dut.x_pos.value = x_coord
        dut.y_pos.value = y_coord

        for y in range(height):
            for x in range(width):
                dut.pix_x.value = x_coord - 5 + x
                dut.pix_y.value = y_coord - 10 + y
                await Timer(1, units="ns")

                actual = bool(dut.draw_player.value) if isUW else bool(dut.draw_U.value)
                assert actual == bool(expected_U[y][x])


    @cocotb.test()
    async def test_player(dut):
        dut._log.info("Start player test")
        x, y = 200, 100

        await u_shape_helper(dut, x, y, True)
        await u_shape_helper(dut, x+17, y, True)
        await u_shape_helper(dut, x+27, y, True)

        dut._log.info("player passed")


    @cocotb.test()
    async def test_U_shape(dut):
        dut._log.info("Start U_shape test")
        await u_shape_helper(dut, 100, 100, False)
        dut._log.info("U_shape passed")


    @cocotb.test()
    async def test_double_sin(dut):
        dut._log.info("Start double_sin test")

        TOP_X = 100
        TOP_Y = 180
        BOTTOM_X = 540
        BOTTOM_Y = 400
        BAR_WIDTH = 40
        VISIBLE_WIDTH = 25
        HEIGHT = 60

        for x_offset in range(0, 400, 20):
            for pix_x in range(TOP_X+1, BOTTOM_X):
                for pix_y in range(TOP_Y+1, BOTTOM_Y):

                    sin_height = SINE_VALUES_TABLE[((pix_x + x_offset)//BAR_WIDTH) % 10]
                    correct_y_pos = ((TOP_Y + 50 - sin_height + HEIGHT > pix_y) or
                                     (pix_y > BOTTOM_Y - sin_height - HEIGHT))
                    correct_x_pos = ((pix_x + x_offset) % BAR_WIDTH) < VISIBLE_WIDTH

                    dut.pix_x.value = pix_x
                    dut.pix_y.value = pix_y
                    dut.x_offset.value = x_offset

                    await Timer(1, units="ns")
                    actual = bool(dut.draw_double_sin.value)

                    assert actual == (correct_y_pos and correct_x_pos)

        dut._log.info("double_sin passed")


    @cocotb.test()
    async def test_sine_lut(dut):
        dut._log.info("Start sine_lut test")

        for index, value in SINE_VALUES_TABLE.items():
            dut.tb_pos.value = index
            await Timer(1, units="ns")
            actual = int(dut.tb_sin_output.value)
            assert actual == value

        dut._log.info("sine_lut passed")
