module falling_edge_detector(
    input wire in,
    input wire clk,
    output wire out
);

   reg in_d;
   
    always @(posedge clk) begin
        in_d <= in;
    end

    assign out = !in && in_d;
endmodule

