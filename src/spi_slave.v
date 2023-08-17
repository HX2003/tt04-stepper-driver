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
   output reg [31:0] spi_reg_0,
   output reg [31:0] spi_reg_1,
   output reg [31:0] spi_reg_2,
   output reg [31:0] spi_reg_3,
   
   output reg       o_RX_DV,    // Data Valid pulse (1 clock cycle)
   input            i_TX_DV,    // Data Valid pulse to register i_TX_Byte
   input  [7:0]     i_TX_Byte,  // Byte to serialize to MISO.

   // SPI Interface
   input      i_SPI_Clk,
   output reg o_SPI_MISO,
   input      i_SPI_MOSI,
   input      i_SPI_CS_n        // active low
   );


  // SPI Interface (All Runs at SPI Clock Domain)
  wire w_SPI_Clk;  // Inverted/non-inverted depending on settings
  
  reg [7:0] address;
  
  reg [$clog2(40):0] rx_tx_bits_count; 
  reg [7:0] rx_address_bits;
  reg [31:0] rx_data_bits;

  reg r_RX_Done, r2_RX_Done, r3_RX_Done;
  reg r_SPI_MISO_Bit;

wire spi_cs_falling;
falling_edge_detector falling_edge_detector_spi_cs(.in(i_SPI_CS_n), .clk(clk), .out(spi_cs_falling));

  assign w_SPI_Clk = i_SPI_Clk;


  // Purpose: Recover SPI Byte in SPI Clock Domain
  // Samples line on correct edge of SPI Clock
always @(posedge clk) begin
    if (spi_cs_falling) begin
        rx_tx_bits_count <= 40;
        r_RX_Done      <= 1'b0;
    end
end
  
always @(posedge w_SPI_Clk) begin
    if (!i_SPI_CS_n) begin
      rx_tx_bits_count <= rx_tx_bits_count - 1;

      // Receive in LSB, shift up to MSB
      if(rx_tx_bits_count > 32) begin
          rx_address_bits <= {rx_address_bits[6:0], i_SPI_MOSI};
      end else begin
          rx_data_bits <= {rx_data_bits[30:0], i_SPI_MOSI};
      end
    
      if (rx_tx_bits_count == 0)
      begin
        r_RX_Done <= 1'b1;
      end
      else if (rx_tx_bits_count == 2)
      begin
        r_RX_Done <= 1'b0;        
      end

    end // else: !if(i_SPI_CS_n)
  end // always @ (posedge w_SPI_Clk or posedge i_SPI_CS_n)



  // Purpose: Cross from SPI Clock Domain to main FPGA clock domain
  // Assert o_RX_DV for 1 clock cycle when o_RX_Byte has valid data.
  always @(posedge clk or negedge i_Rst_L)
  begin
    if (~i_Rst_L)
    begin
      r2_RX_Done <= 1'b0;
      r3_RX_Done <= 1'b0;
      o_RX_DV    <= 1'b0;
      r_SPI_MISO_Bit <= 0;
      
      rx_tx_bits_count <= 0;
      rx_address_bits <= 0;
      rx_data_bits <= 0;
      // Default register values
      spi_reg_0 <= 1234567;
      spi_reg_1 <= 2345678;
      spi_reg_2 <= 3456789;
      spi_reg_3 <= 4567890;
    end
    else
    begin
      // Here is where clock domains are crossed.
      // This will require timing constraint created, can set up long path.
      r2_RX_Done <= r_RX_Done;

      r3_RX_Done <= r2_RX_Done;

      if (r3_RX_Done == 1'b0 && r2_RX_Done == 1'b1) // rising edge
      begin
        o_RX_DV   <= 1'b1;  // Pulse Data Valid 1 clock cycle
        //o_RX_Byte <= r_RX_Byte;
      end
      else
      begin
        o_RX_DV <= 1'b0;
      end
    end // else: !if(~i_Rst_L)
  end // always @ (posedge i_Bus_Clk)

  // Purpose: Transmits 1 SPI Byte whenever SPI clock is toggling
  // Will transmit read data back to SW over MISO line.
  // Want to put data on the line immediately when CS goes low.
always @(posedge clk) begin
    if (spi_cs_falling) begin
        //r_SPI_MISO_Bit <= r_TX_Byte[7];  // Reset to MSb // Is this needed? HX2003
    end
end
  
 always @(posedge w_SPI_Clk)
 begin
    if (!i_SPI_CS_n)
    begin

      // Here is where data crosses clock domains from clk to w_SPI_Clk
      // Can set up a timing constraint with wide margin for data path.
      //r_SPI_MISO_Bit <= r_TX_Byte[r_TX_Bit_Count];
      if(rx_tx_bits_count > 32) begin
          r_SPI_MISO_Bit <= 1'b1;
      end else begin
      case(rx_address_bits)
          0: begin
             r_SPI_MISO_Bit <= spi_reg_0[rx_tx_bits_count]; 
          end
          1: begin
             r_SPI_MISO_Bit <= spi_reg_1[rx_tx_bits_count]; 
          end
          2: begin
             r_SPI_MISO_Bit <= spi_reg_2[rx_tx_bits_count]; 
          end
          3: begin
             r_SPI_MISO_Bit <= spi_reg_3[rx_tx_bits_count]; 
          end
          default: r_SPI_MISO_Bit <= 1'b1;
        endcase
        end
    end // else: !if(i_SPI_CS_n)
  end // always @ (negedge w_SPI_Clk or posedge i_SPI_CS_n_SW)

/*
  // Purpose: Register TX Byte when DV pulse comes.  Keeps registed byte in 
  // this module to get serialized and sent back to master.
  always @(posedge clk or negedge i_Rst_L)
  begin
    if (~i_Rst_L)
    begin
      r_TX_Byte <= 8'h00;
    end
    else
    begin
      if (i_TX_DV)
      begin
        r_TX_Byte <= i_TX_Byte; 
      end
    end // else: !if(~i_Rst_L)
  end // always @ (posedge clk or negedge i_Rst_L)*/

  assign o_SPI_MISO = r_SPI_MISO_Bit;

endmodule // SPI_Slave
