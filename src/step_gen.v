`ifndef STEP_GEN_V
`define STEP_GEN_V
`define step_gen_IDLE 3'd0
`define step_gen_CALC_1_BUSY 3'd1
`define step_gen_CALC_2_BUSY 3'd2
`define step_gen_CALC_3_BUSY 3'd3
`define step_gen_CALC_COMPLETE 3'd4

`include "mul16x16.v"
`include "div32x32.v"
module step_gen(
input wire clk,
input wire rst,
input wire start,
input wire signed [15:0] in_start_velocity,
input wire signed [15:0] in_end_velocity,
input wire [15:0] in_cur_time,
input wire [15:0] in_time_interval,
input wire signed [31:0] in_start_step_pos,
output reg [2:0] state,
output reg signed [15:0] out_cur_velocity,
output reg [31:0] out_cur_step_cos
);

reg [15:0] interval_time;

mul16x16 mul16x16(.clk(clk), .rst(rst), .start(mul16_start), .in_a(mul16_in_a), .in_b(mul16_in_b), .is_a_signed(mul16_is_a_signed), .out(mul16_out), .state(mul16_state));
reg [15:0] mul16_in_a;
reg [15:0] mul16_in_b;
wire [31:0] mul16_out;
reg mul16_is_a_signed;
reg mul16_start;
wire [1:0] mul16_state;

reg [31:0] div32x32_in_dividend;
reg [31:0] div32x32_in_divisor;
wire [31:0] div32x32_out;
reg div32x32_is_dividend_signed;
reg div32x32_is_truncate_16;
reg div32x32_start;
wire [1:0] div32x32_state;

div32x32 div32x32(.clk(clk), .rst(rst), .start(div32x32_start), .in_dividend(div32x32_in_dividend), .in_divisor(div32x32_in_divisor), .is_dividend_signed(div32x32_is_dividend_signed), .is_truncate_16(div32x32_is_truncate_16), .out(div32x32_out), .state(div32x32_state));

always @(*) begin
    if(1) begin
        out_cur_step_cos <= in_start_step_pos - div32x32_out;
    end else begin
        out_cur_step_cos <= in_start_step_pos + div32x32_out;
    end
end

always @(posedge clk) begin
    if (rst) begin
        state <= `step_gen_IDLE;
        interval_time <= 0;
        mul16_in_a <= 0;
        mul16_in_b <= 0;
        mul16_is_a_signed <= 0;
        mul16_start <= 0;
        div32x32_in_dividend <= 0;
        div32x32_in_divisor <= 0;
        div32x32_is_dividend_signed <= 0;
        div32x32_is_truncate_16 <= 1;
        div32x32_start <= 0;
        out_cur_velocity <= 0;
        
    end else begin
        case(state)
            `step_gen_IDLE: begin
                if(start) begin
                    mul16_in_a <= in_end_velocity - in_start_velocity;
                    mul16_is_a_signed <= 1;
                    mul16_in_b <= in_cur_time;
                    mul16_start <= 1; 
                    state <= `step_gen_CALC_1_BUSY;
                end
            end
            `step_gen_CALC_1_BUSY: begin
                if(mul16_state == `mul16x16_CALC_COMPLETE) begin
                    mul16_start <= 0;
                    div32x32_in_dividend <= mul16_out;
                    div32x32_in_divisor <= in_time_interval;
                    div32x32_is_dividend_signed <= 1;
                    div32x32_is_truncate_16 <= 1;
                    div32x32_start <= 1;
                    state <= `step_gen_CALC_2_BUSY;
                end   
            end
            `step_gen_CALC_2_BUSY: begin
                if(div32x32_state == `div32x32_CALC_COMPLETE) begin
                    div32x32_start <= 0;
                    out_cur_velocity <= div32x32_out[15:0]; 
                    state <= `step_gen_CALC_3_BUSY;
                end 
            end
            `step_gen_CALC_3_BUSY: begin
                // Delay a cycle
                state <= `step_gen_CALC_COMPLETE;
            end
            `step_gen_CALC_COMPLETE: begin
                state <= `step_gen_IDLE;
            end
            default: state <= `step_gen_IDLE;
        endcase      
    end
end

endmodule

`endif
