`default_nettype none
`timescale 1ns/1ps

/*
this testbench just instantiates the module and makes some convenient wires
that can be driven / tested by the cocotb test.py
*/
// testbench is controlled by test.py
module tb ();

    // this part dumps the trace to a vcd file that can be viewed with GTKWave
    initial begin
        $dumpfile ("tb.vcd");
        $dumpvars (0, tb);
        #1;
    end

    // wire up the inputs and outputs
    wire  clk;
    wire  rst_n;
    wire  ena;
    wire  [7:0] ui_in;
    wire  [7:0] uo_out;
    wire  [7:0] uio_in;
    wire  [7:0] uio_out;
    wire  [7:0] uio_oe;
    
    wire spi_miso = uio_out[1];
    wire spi_clk;
    wire spi_cs;
    wire spi_mosi;
    
    assign uio_in[2] = spi_clk;
    assign uio_in[3] = spi_cs;
    assign uio_in[0] = spi_mosi;
    
    wire  [7:0] uio_combined;
    assign uio_in = uio_combined;
    
    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            assign uio_combined[i] = uio_oe[i] ? uio_out[i] : 1'bZ;
        end
    endgenerate
    
    // Dedicated outputs
    wire [3:0] motor_driver_out = uo_out[3:0];
    
    // Dedicated inputs
    wire ext_ctrl;
    assign ui_in[0] = ext_ctrl;
    
    tt_um_stepper_driver tt_um_stepper_driver (
    // include power ports for the Gate Level test
    `ifdef GL_TEST
        .VPWR( 1'b1),
        .VGND( 1'b0),
    `endif
        .ui_in      (ui_in),    // Dedicated inputs
        .uo_out     (uo_out),   // Dedicated outputs
        .uio_in     (uio_in),   // IOs: Input path
        .uio_out    (uio_out),  // IOs: Output path
        .uio_oe     (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
        .ena        (ena),      // enable - goes high when design is selected
        .clk        (clk),      // clock
        .rst_n      (rst_n)     // not reset
        );

endmodule
