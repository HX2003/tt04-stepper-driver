`ifndef MUL16x16_V
`define MUL16x16_V

// Raise start from low to high to begin calculation
// Keep start high until you have received the output
// The output will change while calculations are ongoing, and depends on the input

`define mul16x16_IDLE 2'd0
`define mul16x16_CALC_BUSY 2'd1
`define mul16x16_CALC_COMPLETE 2'd2

// Busy will be low after calculations are complete
module mul16x16 #(parameter N=16) (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [N-1:0] in_a,
    input wire [N-1:0] in_b,
    input wire is_a_signed,
    output reg [N*2-1:0] out,
    output reg [1:0] state
);

reg sign;
reg [N*2-1:0] a;
reg [N-1:0] b;
reg [$clog2(N):0] count;

//parameter IDLE = 2'd0, CALC_BUSY = 2'd1, CALC_COMPLETE = 2'd2;

always @(posedge clk) begin
    if(rst) begin
        state <= `mul16x16_IDLE;
        count <= 0;
        out <= 0;
        a <= 0;
        b <= 0;
        sign <= 0;
    end else begin
        case(state)
            `mul16x16_IDLE: begin
                if(start) begin
                    state <= `mul16x16_CALC_BUSY;
                    count <= N;
                    sign <= in_a[15];
                    if(is_a_signed && in_a[15]) begin // Negative
                        a <= {{N{1'b0}}, ~in_a[14:0] + 15'd1};
                    end else begin
    	                a <= {{N{1'b0}}, in_a};                    
                    end
    	            b <= in_b;
    	       end
            end
            `mul16x16_CALC_BUSY: begin
                if(count > 0) begin
                    count <= count - 1;
        
	            if (b[0])
	                out <= out + a;
	
	            b <= b >> 1;
	            a <= a << 1;
	        end else begin
	            if(is_a_signed && sign) begin // Negative
	                out <= {1'b1, ~(out[14:0] - 15'd1)};
	            end
	            
	            state <= `mul16x16_CALC_COMPLETE;
	        end
            end
            `mul16x16_CALC_COMPLETE: begin
               if(!start)
                   state <= `mul16x16_IDLE;
            end
            default: state <= `mul16x16_IDLE;
        endcase
    end
end

endmodule

`endif
