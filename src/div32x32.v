`ifndef DIV32x32_V
`define DIV32x32_V

// Raise start from low to high to begin calculation
// Keep start high until you have received the output
// The output will change while calculations are ongoing, and depends on the input

`define div32x32_IDLE 2'd0
`define div32x32_CALC_BUSY 2'd1
`define div32x32_CALC_COMPLETE 2'd2

//Restoring Division
module div32x32(
   input wire clk,
   input wire rst,
   input wire start,
   input wire [31:0] in_dividend,
   input wire [31:0] in_divisor,
   input wire is_dividend_signed,
   input wire is_truncate_16, // Is output of the division 16 bits, inputs is still 32 bits
   output reg [31:0] out,
   output reg [1:0] state
);

reg sign;
reg [31:0] D;
reg [63:0] AQ;
reg [31:0] temp_A;
reg [5:0]  count;

always @(*) begin
    if(is_truncate_16) begin
        if(is_dividend_signed && sign) begin // Negative
            out = {16'b0, 1'b1, ~(AQ[14:0] - 15'd1)};
        end else begin
            out = {16'b0, AQ[15:0]};
        end
    end else begin
        if(is_dividend_signed && sign) begin // Negative
            out = {1'b1, ~(AQ[30:0] - 31'd1)};
        end else begin
            out = AQ[31:0];
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        state <= `div32x32_IDLE;
        count <= 0;
        D <= 0;
        AQ = 0;
        temp_A = 0;
        sign <= 0;
    end else begin
        case(state)
            `div32x32_IDLE: begin
                if(start) begin
                    state <= `div32x32_CALC_BUSY;
                    count <= 32;
                    D <= in_divisor;
                    sign <= in_dividend[31];
                    if(is_dividend_signed && in_dividend[31]) begin // Negative
                        AQ = {32'b0, ~in_dividend[30:0] + 31'd1};
                    end else begin
                        AQ = {32'b0, in_dividend};
                    end
                end
            end
            `div32x32_CALC_BUSY: begin
                if(count > 0) begin
                    count <= count - 1;
        
	            AQ = AQ << 1;
                    temp_A = AQ[63:32] - D;
            
                    if (temp_A[31] == 1) begin // temp_A is negative
                        AQ[0] = 0;
                    end else begin
                    // Update with subtracted value
                    AQ[63:0] = {temp_A, AQ[31:1], 1'b1};
                    end
	        end else begin
	            state <= `div32x32_CALC_COMPLETE;
	        end
            end
            `div32x32_CALC_COMPLETE: begin
               if(!start)
                   state <= `div32x32_IDLE;
            end
            default: state <= `div32x32_IDLE;
        endcase
   end
end

endmodule

`endif
/*Non restoring division module div32x32(
input wire clk,
input wire rst,
input wire [31:0] dividend, 
input wire [31:0] divisor,
output wire ready,
input wire start,
output reg [31:0] quotient
);

wire start_rising;
rising_edge_detector rising_edge_detector0(.in(start), .clk(clk), .out(start_rising));

   reg [31:0] D;
   reg [63:0] AQ;
   reg [5:0]  count;
   reg one_bit;
   
   assign ready = start;
   
   always @( posedge clk) begin
     if (rst) begin
        count <= 0;
            D <= 0;
            AQ = 0;
            quotient <= 0;
            one_bit = 0;
     end else if( start_rising ) begin
        count <= 32;
        D <= divisor;
        AQ = {32'b0, dividend};
     end else if (count > 0) begin
            count <= count - 1;
            
            one_bit = AQ[63];
            AQ = AQ << 1;
            
            if(one_bit == 0) begin // A is positive
            	AQ[63:32] = AQ[63:32] - D;
            end else begin
            	AQ[63:32] = AQ[63:32] + D;
            end
             
            AQ[0] = ~AQ[63];
     end else if (count == 0) begin
        // Only if you need the remainder
        // if(AQ[63] == 1) // A is negative
        //    AQ[63:32] = AQ[63:32] + D;
            
     	quotient <= AQ[31:0];
     end
   end
endmodule*/
