import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from cocotb.handle import Force
 
clock_frequency = 100

segments = [ 63, 6, 91, 79, 102, 109, 124, 7, 127, 103 ]

@cocotb.test()
async def test_7seg(dut):
    dut._log.info("start")
    clock = Clock(dut.clk, 1/clock_frequency, units="sec")
    cocotb.start_soon(clock.start())

    # reset
    dut._log.info("reset")
    dut.rst_n.value = 0
    dut.ext_ctrl.value = 0; # Configure step and direction pins as input
    dut.step_io.value = 0
    dut.dir_io.value = 0
    # set the compare value
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    max_count = dut.ui_in.value
    dut._log.info(f"check all segments with MAX_COUNT set to {max_count}")
    # check all segments and roll over
    for i in range(15):
        dut._log.info("check segment {}".format(i))
        dut.step_io.value = 1
        await ClockCycles(dut.clk, 10)
        dut.step_io.value = 0
        await ClockCycles(dut.clk, 10)
        #assert int(dut.segments.value) == segments[i % 10]


