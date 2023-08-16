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
    dut.uio_combined[0].value = 0 #step_io
    dut.uio_combined[1].value = 0 #dir_io
    # set the compare value
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    
    dut.tt_um_stepper_driver.test_number_a.value = 248230948
    dut.tt_um_stepper_driver.test_number_b.value = 32412
    dut.tt_um_stepper_driver.start.value = 1
    
    await ClockCycles(dut.clk, 36)
    
    assert int(dut.tt_um_stepper_driver.test_number_c.value) == 7658
    max_count = dut.ui_in.value
    dut._log.info(f"check all segments with MAX_COUNT set to {max_count}")
    # check all segments and roll over
    for i in range(15):
        dut._log.info("check segment {}".format(i))
        dut.uio_combined[0].value = 1 #step_io
        await ClockCycles(dut.clk, 10)
        dut.uio_combined[0].value = 0 #step_io
        await ClockCycles(dut.clk, 10)
        #assert int(dut.segments.value) == segments[i % 10]



