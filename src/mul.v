// Raise start from low to high to begin calculation
// The output will change while calculations are ongoing
// Busy will be low after calculations are complete
module mul #(parameter N=16) (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [N-1:0] in_a,
    input wire [N-1:0] in_b,
    output reg [N*2-1:0] out,
    output wire busy
);

wire start_rising;
reg [N*2-1:0] a;
reg [N-1:0] b;
reg [5:0]  count;

assign busy = start || count > 0;

rising_edge_detector rising_edge_detector0(.in(start), .clk(clk), .out(start_rising));

always @(posedge clk) begin
    if(rst) begin
        count <= 0;
        out <= 0;
        a <= 0;
        b <= 0;
    end else if(start_rising) begin
        count <= N;
    	a <= {{N{1'b0}}, in_a};
    	b <= in_b;
    end else if(count > 0) begin
        count <= count - 1;
        
	if (b[0])
	    out <= out + a;

	// Shift right	
	b <= b >> 1;

	// Shift left
	a <= a << 1;
    end
end

endmodule
