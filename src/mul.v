module mul #(parameter N_BITS=32) (
    input wire clk,
    input wire rst,
    input wire [N_BITS-1:0] in_a,
    input wire [N_BITS-1:0] in_b,
    input wire start,
    output reg busy,
    output reg [N_BITS-1:0] out
);

wire start_rising;
reg [N_BITS-1:0] a;
reg [N_BITS-1:0] b;

rising_edge_detector rising_edge_detector0(.in(start), .clk(clk), .out(start_rising));

always @(posedge clk) begin
    if(rst) begin
        busy <= 0;
    end
    
    if(start_rising) begin
    	a <= in_a;
    	b <= in_b;
    	out <= 0;
    	busy <= 1;
    end
    
    if(busy) begin
	if (b[0])
	    out <= out + a;

	// Shift right	
	b <= b >> 1;

	// Shift left discard upper bits
	a <= a << 1;
    end
end

endmodule
