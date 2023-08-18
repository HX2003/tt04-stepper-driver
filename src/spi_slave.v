///////////////////////////////////////////////////////////////////////////////
// Description: SPI (Serial Peripheral Interface) Slave
//              Uses 40 bit data frames. Where the most significant 8 bits are
//              for the address. Write access involves setting the most
//              significant bit of the address byte to 1, while read access
//              involves setting the most significant bit of the address byte
//              to 0. The remaining 32 bits are for the data. Ensure that CS_n
//              is kept low during the whole transaction.
//
// Note:        clk must be at least 4x faster than i_SPI_Clk
//              MISO should be tri-stated when not communicating.  Allows for multiple
//              SPI Slaves on the same interface.
//
///////////////////////////////////////////////////////////////////////////////

module spi_slave
  (
   // Control/Data Signals,
   input            i_Rst_L,    // FPGA Reset, active low
   input clk,      // FPGA Clock
   
   input wire [31:0] spi_reg_0,
   input wire [31:0] spi_reg_1,
   input wire [31:0] spi_reg_2,
   input wire [31:0] spi_reg_3,
   
   output reg [31:0] spi_data_bits,
   output reg        spi_rx,
   output reg [7:0]  spi_address_bits,

   // SPI Interface
   input      i_SPI_Clk,
   output reg o_SPI_MISO,
   input      i_SPI_MOSI,
   input      i_SPI_CS_n        // active low
   );
  
  reg [$clog2(40):0] rx_tx_bits_count; 
  reg       o_RX_DV;
  reg r_SPI_MISO_Bit;

wire spi_cs_falling;
falling_edge_detector falling_edge_detector_spi_cs(.in(i_SPI_CS_n), .clk(clk), .out(spi_cs_falling));

wire spi_clk_rising;
rising_edge_detector rising_edge_detector_spi_clk(.in(i_SPI_Clk), .clk(clk), .out(spi_clk_rising));

wire spi_clk_falling;
falling_edge_detector falling_edge_detector_spi_clk(.in(i_SPI_Clk), .clk(clk), .out(spi_clk_falling));

always @(posedge clk) begin
    if (~i_Rst_L) begin
      spi_rx      <= 1'b0;
      spi_data_bits = {32{1'b1}};
      o_RX_DV    <= 1'b0;
      r_SPI_MISO_Bit <= 0;
      
      rx_tx_bits_count <= 0;
      spi_address_bits = 0; 
      
    end else if (spi_cs_falling) begin
        // Start of frame
        rx_tx_bits_count <= 39;
        spi_rx      <= 1'b0;
    end else if (!i_SPI_CS_n) begin
        if(spi_clk_rising) begin
            // Receive
            if(rx_tx_bits_count > 0) begin
                rx_tx_bits_count <= rx_tx_bits_count - 1;
            end

            // Receive in LSB, shift up to MSB
            if(rx_tx_bits_count > 31) begin
                // Receive the first 8 bits used for address
                spi_address_bits = {spi_address_bits[6:0], i_SPI_MOSI};
                
                if(rx_tx_bits_count == 32 && !spi_address_bits[7]) begin
                    // MSB is reserved for read/write flag
                    // Read flag (spi_address_bits[7] is low), save a copy of the register data, in case it changes
                    case(spi_address_bits[6:0])
                    0: begin
                        spi_data_bits = spi_reg_0; 
                    end
                    1: begin
                        spi_data_bits = spi_reg_1;
                    end
                    2: begin
                        spi_data_bits = spi_reg_2; 
                    end
                    3: begin
                        spi_data_bits = spi_reg_3; 
                    end
                    default: spi_data_bits = {32{1'b1}};
                    endcase
                end
            end else begin
                if(spi_address_bits[7]) begin
                    // Write flag (spi_address_bits[7] is high), save the data received
                    spi_data_bits = {spi_data_bits[30:0], i_SPI_MOSI};
                    
                    if(rx_tx_bits_count == 0) begin
                        spi_rx <= 1'b1;
                    end
                end
            end
        end else if (spi_cs_falling || spi_clk_falling) begin
        // Transmit
            if(rx_tx_bits_count > 31) begin
                r_SPI_MISO_Bit <= 1'b1;
                // Can be filled with useful data, current unused
            end else begin
                r_SPI_MISO_Bit <= spi_data_bits[rx_tx_bits_count[4:0]]; 
            end
        end
    end
end

assign o_SPI_MISO = r_SPI_MISO_Bit;

endmodule // SPI_Slave
