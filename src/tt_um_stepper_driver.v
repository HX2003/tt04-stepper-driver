`default_nettype none

module tt_um_stepper_driver #( parameter MAX_COUNT = 24'd10_000_000 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire reset = ! rst_n;
    
    // Dedicated outputs
    wire [3:0] motor_driver_out;
    assign uo_out[3:0] = motor_driver_out;
    assign uo_out[7:4] = test_number_c[3:0] + test_number_c[31:28];
    // Dedicated inputs
    wire ext_ctrl = ui_in[0];
    
    // Bidirectional IO
    wire io_step = uio_in[0];
    wire io_step_rising;
    rising_edge_detector rising_edge_detector0(.in(io_step), .clk(clk), .out(io_step_rising));
    wire io_dir = uio_in[1];
    
    assign uio_oe[7:2] = 6'b000000;
    assign uio_oe[0] = ext_ctrl;
    assign uio_oe[1] = ext_ctrl;

    assign uio_out = 8'b00000000;

    reg [31:0] step_pos;
    
    reg [31:0] test_number_a;
    reg [31:0] test_number_b;
    wire [31:0] test_number_c;
    
    reg start;
    wire busy;
    
    mul mul(.clk(clk), .rst(reset), .in_a(test_number_a), .in_b(test_number_b), .out(test_number_c), .start(start), .busy(busy));
    // if external inputs are set then use that as compare count
    // otherwise use the hard coded MAX_COUNT
    //wire [23:0] compare = ui_in == 0 ? MAX_COUNT: {16'b0, ui_in[7:0]};

    always @(posedge clk) begin
        // if reset, set counter to 0
        if (reset) begin
            step_pos <= 0;
            start <= 0;
            
        end else begin
            if (io_step_rising)
                step_pos <= step_pos + 1;
            /*// if up to 16e6
            if (second_counter == compare) begin
                // reset
                second_counter <= 0;

                // increment digit
                digit <= digit + 1'b1;

                // only count from 0 to 3
                if (digit == 3)
                    digit <= 0;

            end else
                // increment counter
                second_counter <= second_counter + 1'b1;*/
        end
    end
    
    full_step_waveform_decoder full_step_waveform_decoder(.in(step_pos[1:0]), .out(motor_driver_out));

endmodule
