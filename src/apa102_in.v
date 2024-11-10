// A very basic SPI receiver; waits for a valid 32-bit '0' start packet for APA102s
// Then shifts the next 7 LEDs' 32-bit payloads into data_out (ignoring the leading 8 bits of "intensity")
// Stops shifting just prior to the 32-bit stop packet and then cycles back around for the next one

module apa102_in (
  input wire clk,
  input wire rst_n,
  input wire sck,
  input wire sda,
  output reg [167:0] data_out
);

  localparam START = 2'b00;
  localparam DATA = 2'b01;
  localparam STOP = 2'b10;
  
  reg [1:0] state;
  
  reg [7:0] index;
  
  reg [8:0] bit_count;

  reg last_sck;

  always @(posedge clk) begin
    if (!rst_n) begin
      state <= START;
      data_out <= 0;
      bit_count <= 0;
      last_sck <= 1;
      index <= 167;
    end else begin
      last_sck <= sck;

      //posedge sck
      if ((sck == 1) && !last_sck) begin 
        case(state)
          START: begin
            if (sda) begin // we need 32 0 bits for a valid start frame
              bit_count <= 0;
            end else begin
              if (bit_count == 31) begin
                state <= DATA;
              end
              bit_count <= bit_count + 1;
            end
          end // START
      
          DATA: begin
            if ( ((bit_count - 32)  % 32) >= 8 ) begin
              data_out[index] <= sda;
              index <= index - 1;
            end
            bit_count <= bit_count + 1;
            if (bit_count == 256) begin // 32*(start + 7 LEDs)
              state <= STOP;
            end
          end // DATA
       
          STOP: begin
            if (bit_count == 288) begin // 32*(start + 7 LEDs + stop)
              state <= START;
              index <= 167;
              bit_count <= 0;
            end else begin
              bit_count <= bit_count + 1;
            end
          end // STOP

          default: begin
            state <= START;
            data_out <= 0;
            bit_count <= 0;
            index <= 167;
          end
        endcase
      end
    end
  end    
endmodule
