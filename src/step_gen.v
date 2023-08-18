module step_gen(
input wire clk,
input wire rst,
input wire start,
inout wire cur_step_pos
//output wire ready,
);

parameter IDLE = 2'd0, CALC_1_START = 2'd1, CALC_1_BUSY = 2'd2, CALC_2_START = 2'd3;
 
reg [1:0] state;
reg [15:0] cur_time;
reg [15:0] interval_time;

reg signed [15:0] velocity;

//assign ready = start;
wire start_rising;
rising_edge_detector rising_edge_detector0(.in(start), .clk(clk), .out(start_rising));

mul mul16x16(.clk(clk), .rst(rst), .start(mul16_start), .in_a(mul16_in_a), .in_b(mul16_in_b), .out(mul16_out), .busy(mul16_busy));
reg [15:0] mul16_in_a;
reg [15:0] mul16_in_b;
wire [31:0] mul16_out;
reg mul16_start;
wire mul16_busy;

//div32x32 div32x32(.clk(clk), .rst(reset), .dividend(test_number_a), .divisor(test_number_b), .ready(busy), .quotient(test_number_c), .start(start));
      
always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        cur_step_pos <= 0;
        cur_time <= 0;
        interval_time <= 0;
        mul16_in_a <= 0;
        mul16_in_b <= 0;
        mul16_start <= 0;
    end else
        case(state)
            IDLE: begin
                if(start_rising)
                    state <= CALC_1_START;
                    velocity <= 9205;
                    cur_time <= 3242;
            end
            CALC_1_START: begin
                if(velocity[15]) begin // Negative
                    mul16_in_a <= ~velocity + 1;
                end else begin
                    mul16_in_a <= velocity;
                end
                        
                mul16_in_b <= cur_time;
                mul16_start <= 1;
                state <= CALC_1_BUSY;
            end
            CALC_1_BUSY: begin
                mul16_start <= 0;
                if(mul16_busy == 0) begin
                    cur_step_pos <= mul16_out;
                    state <= CALC_2_START;
                end
            end
            CALC_2_START: begin
                
            end
            default: state <= IDLE;
        endcase      
    end
endmodule
