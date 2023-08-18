module rising_edge_detector(
    input wire in,
    input wire clk,
    output wire out
);

reg in_1;
reg in_2;
   
always @(posedge clk) begin
    in_1 <= in;
    in_2 <= in_1;
end

assign out = in_1 && !in_2;

endmodule

