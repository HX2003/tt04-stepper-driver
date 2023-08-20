`default_nettype none
`include "step_gen.v"

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

    wire rst = !rst_n;
    
    // Dedicated outputs
    wire [3:0] motor_driver_out;
    assign uo_out[3:0] = motor_driver_out;
    assign uo_out[7:4] = 4'b0000;//test_number_c[3:0] + test_number_c[31:28];
    // Dedicated inputs
    wire ext_ctrl = ui_in[0];
    
    // Bidirectional IO
    wire spi_mosi = uio_in[0];
    assign uio_out[0] = 1'b0;
    assign uio_oe[0] = 1'b0;
    
    wire spi_miso;
    assign uio_out[1] = spi_miso;
    //Tri-state MISO when CS is high.  Allows for multiple slaves to talk.
    assign uio_oe[1] = !spi_cs;
    
    wire spi_clk = uio_in[2];
    assign uio_out[2] = 1'b0;
    assign uio_oe[2] = 1'b0;
    
    wire spi_cs = uio_in[3];
    assign uio_out[3] = 1'b0;
    assign uio_oe[3] = 1'b0;
    
    assign uio_out[5:4] = 2'b00;
    assign uio_oe[5:4] = 2'b00;
    
    wire io_step = uio_in[6];
    wire io_step_rising;
    rising_edge_detector rising_edge_detector0(.in(io_step), .clk(clk), .out(io_step_rising));
    assign uio_out[6] = 1'b0;
    assign uio_oe[6] = ext_ctrl;
        
    wire io_dir = uio_in[7];
    assign uio_out[7] = 1'b0;
    assign uio_oe[7] = ext_ctrl;

    //reg [31:0] step_pos;
    
    reg [31:0] counter;
    wire signed [15:0] out_cur_velocity;
    wire signed [31:0] out_cur_step_cos;
    
    reg start;
    wire [2:0] state;
    
step_gen step_gen(
    .clk(clk),
    .rst(rst),
    .start(start),
    .state(state),
    .in_start_velocity(spi_reg_1[15:0]),
    .in_end_velocity(spi_reg_1[31:16]),
    .in_cur_time(spi_reg_2[15:0]),
    .in_time_interval(spi_reg_2[31:16]),
    .in_start_step_pos(spi_reg_0),
    .out_cur_velocity(out_cur_velocity),
    .out_cur_step_cos(out_cur_step_cos)
);
     

// SPI Registers
reg [31:0] spi_reg_0; // cur_step_pos
reg [31:0] spi_reg_1; //
reg [31:0] spi_reg_2;
reg [31:0] spi_reg_3;

wire [31:0] spi_data_bits;
wire [7:0] spi_address_bits;
wire spi_rx;
wire spi_rx_rising;
rising_edge_detector rising_edge_detector_spi_rx(.in(spi_rx), .clk(clk), .out(spi_rx_rising));

spi_slave spi_slave
(
    // Control/Data Signals,
    .i_Rst_L(rst_n),      // FPGA Reset Active Low
    .clk(clk),          // FPGA Clock
    .spi_reg_0(spi_reg_0),
    .spi_reg_1(spi_reg_1),
    .spi_reg_2(spi_reg_2),
    .spi_reg_3(spi_reg_3),
    
    .spi_address_bits(spi_address_bits),
    .spi_data_bits(spi_data_bits),
    .spi_rx(spi_rx),

    // SPI Interface
    .i_SPI_Clk(spi_clk),
    .o_SPI_MISO(spi_miso),
    .i_SPI_MOSI(spi_mosi),
    .i_SPI_CS_n(spi_cs)
 );
   
    always @(posedge clk) begin
        // if reset, set counter to 0
        if (rst) begin
            start <= 0;
            counter <= 0;
            spi_reg_0 <= 0;
            spi_reg_1 <= 0;
            spi_reg_2 <= 0;
            spi_reg_3 <= 0;
           
        end else begin
            //if (io_step_rising)
                //step_pos <= step_pos + 1;
                
            counter <= counter + 1'b1;
            
            if (counter == 100) begin
              spi_reg_0 <= 1;
	      spi_reg_1 <= 2345678;
	      spi_reg_2 <= 3456789;
	      spi_reg_3 <= 4567890;
	    end
	    
	    if (spi_rx_rising == 1) begin
	        case(spi_address_bits[6:0])
                    0: begin
                        spi_reg_0 <= spi_data_bits; 
                    end
                    1: begin
                        spi_reg_1 <= spi_data_bits;
                    end
                    2: begin
                        spi_reg_2 <= spi_data_bits; 
                        start <= 1;
                    end
                    3: begin
                        spi_reg_3 <= spi_data_bits; 
                    end
                endcase
	    end
            
            if (state == `step_gen_CALC_COMPLETE) begin
                start <= 0;
                spi_reg_3 <= out_cur_velocity; 
            end
            /*if (counter == 150) begin
                start <= 0;
            end
            
            if (counter == 200) begin
                test_number_a <= 200000;
                test_number_b <= counter;
                start <= 1;
            end*/
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
    
    full_step_waveform_decoder full_step_waveform_decoder(.in(spi_reg_0[1:0]), .out(motor_driver_out));

endmodule
