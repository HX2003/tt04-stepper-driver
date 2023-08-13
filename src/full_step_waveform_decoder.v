module full_step_waveform_decoder(
    input [1:0] in,
    output reg [3:0] out /* Coil1 Coil3 Coil2 Coil4 */
);

always @(*) begin
    case(in)
        2'b00: out= 4'b0011;
        2'b01: out= 4'b0110;
        2'b10: out= 4'b1100;
        2'b11: out= 4'b1001;
    endcase
end

endmodule

