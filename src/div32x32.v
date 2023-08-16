module div32x32(
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
   reg [31:0] temp_A;
   reg [5:0]  count;
   
   assign ready = start;
   
   always @( posedge clk) begin
     if (rst) begin
        count <= 0;
            D <= 0;
            AQ = 0;
            temp_A = 0;
            quotient <= 0;
     end else if( start_rising ) begin
        count <= 32;
        D <= divisor;
        AQ = {32'b0, dividend};
     end else if (count > 0) begin
            count <= count - 1;
            
            AQ = AQ << 1;
            temp_A = AQ[63:32] - D;
            
            if (temp_A[31] == 1) begin // temp_A is negative
                AQ[0] = 0;
            end else begin
                // Update with subtracted value
                AQ[63:0] = {temp_A, AQ[31:1], 1'b1};
            end
     end else if (count == 0) begin
     	quotient <= AQ[31:0];
     end
   end
endmodule
