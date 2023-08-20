import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from cocotb.handle import Force
from cocotbext.spi import SpiMaster, SpiSignals, SpiConfig
import numpy as np
 
clock_frequency = 100

def to_twos_complement(value):        
    bit_width = np.dtype(type(value)).itemsize * 8
    
    if(value < 0):
        return value + (1 << bit_width)
    else:
        return value

def from_twos_complement(value, type):
    bit_width = np.dtype(type(value)).itemsize * 8
    
    if(value & (1 << (bit_width - 1))):
        return type(value - (1 << bit_width))
    else:
        return type(value)
        
@cocotb.test()
async def test_7seg(dut):
    dut._log.info("start")
    
    clock = Clock(dut.clk, 1/clock_frequency, units="sec")
    cocotb.start_soon(clock.start())
    

    spi_signals = SpiSignals(
        sclk = dut.spi_clk,
        mosi = dut.spi_mosi,
        miso = dut.spi_miso,
        cs   = dut.spi_cs
    )

    spi_config = SpiConfig(
        word_width = 40,
        sclk_freq  = 20,
        cpol       = False,
        cpha       = False,
        msb_first  = True
    )

    spi_master = SpiMaster(spi_signals, spi_config)

    # reset
    dut._log.info("reset")
    dut.rst_n.value = 0
    dut.ext_ctrl.value = 0; # Configure step and direction pins as input
    dut.uio_combined[6].value = 0 #step_io
    dut.uio_combined[7].value = 0 #dir_io
    # set the compare value
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    
    #dut.tt_um_stepper_driver.test_number_a.value = 248230948
    #dut.tt_um_stepper_driver.test_number_b.value = 32412
    #dut.tt_um_stepper_driver.start.value = 1
    
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 0 | 0 << 7;
    spi_write_data = 0;
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    read_bytes = await spi_master.read()
    print(f"Value: {read_bytes[0] & 0xFFFFFFFF}")
    
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 1 | 0 << 7;
    spi_write_data = 0;
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    read_bytes = await spi_master.read()
    print(f"Value: {read_bytes[0] & 0xFFFFFFFF}")
    
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 2 | 0 << 7;
    spi_write_data = 0;
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    read_bytes = await spi_master.read()
    print(f"Value: {read_bytes[0] & 0xFFFFFFFF}")
    
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 3 | 0 << 7;
    spi_write_data = 0;
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    read_bytes = await spi_master.read()
    print(f"Value: {read_bytes[0] & 0xFFFFFFFF}")
    
    # Write test
    start_velocity = np.int16(-24000)
    end_velocity = np.int16(12000)
    cur_time = np.uint16(1234)
    time_interval = np.uint16(12345)
    
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 0 | 1 << 7;
    spi_write_data = to_twos_complement(np.int32(9999))
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    await spi_master.read()
    
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 1 | 1 << 7;
    spi_write_data = to_twos_complement(start_velocity) | (to_twos_complement(end_velocity) << 16)
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    await spi_master.read()
    
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 2 | 1 << 7;
    spi_write_data = cur_time | time_interval << 16;
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    await spi_master.read()
    
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 3 | 0 << 7;
    spi_write_data = 0;
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    read_bytes = await spi_master.read()
    print(f"Stepgen value: {from_twos_complement(read_bytes[0] & 0xFFFFFFFF, np.int32)}")

    '''await ClockCycles(dut.clk, 200)
    spi_reg_addr = 3 | 1 << 7;
    spi_write_data = 6666666;
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    await spi_master.read()
    
    # Read test after writing
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 0 | 0 << 7;
    spi_write_data = 0;
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    read_bytes = await spi_master.read()
    print(f"Value: {read_bytes[0] & 0xFFFFFFFF}")
    
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 1 | 0 << 7;
    spi_write_data = 0;
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    read_bytes = await spi_master.read()
    print(f"Value: {read_bytes[0] & 0xFFFFFFFF}")
    
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 2 | 0 << 7;
    spi_write_data = 0;
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    read_bytes = await spi_master.read()
    print(f"Value: {read_bytes[0] & 0xFFFFFFFF}")
    
    await ClockCycles(dut.clk, 200)
    spi_reg_addr = 3 | 0 << 7;
    spi_write_data = 0;
    spi_frame = spi_reg_addr << 32 | spi_write_data;
    await spi_master.write([spi_frame])
    read_bytes = await spi_master.read()
    print(f"Value: {read_bytes[0] & 0xFFFFFFFF}")
    '''
    #assert int(dut.tt_um_stepper_driver.test_number_c.value) == 7658
    max_count = dut.ui_in.value
    dut._log.info(f"check all segments with MAX_COUNT set to {max_count}")
    # check all segments and roll over
    for i in range(15):
        dut._log.info("check segment {}".format(i))
        dut.uio_combined[6].value = 1 #step_io
        await ClockCycles(dut.clk, 10)
        dut.uio_combined[6].value = 0 #step_io
        await ClockCycles(dut.clk, 10)
        #assert int(dut.segments.value) == segments[i % 10]



