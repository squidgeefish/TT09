// A very basic SPI receiver; waits for a valid 32-bit '0' start packet for APA102s
// Then shifts the next 7 LEDs' 32-bit payloads into data_out
// Stops shifting just prior to the 32-bit stop packet and then cycles back around for the next one

module apa102_in (
  input wire rst_n,
  input wire sck,
  input wire sda,
  output reg [223:0] data_out
);

  localparam START = 2'b00;
  localparam DATA = 2'b01;
  localparam STOP = 2'b10;
  
  reg [1:0] state;
  
  reg [223:0] shift_data;
  
  reg [8:0] bit_count;
 
  always @(negedge rst_n) begin
    state <= START;
    shift_data <= 0;
    data_out <= 0;
    bit_count <= 0;
  end
  
  always @(posedge sck) begin
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
        shift_data <= (shift_data << 1) | sda;
        bit_count <= bit_count + 1;
        if (bit_count == 256) begin // 32*(start + 7 LEDs)
          state <= STOP;
          data_out <= shift_data;
        end
      end // DATA
   
      STOP: begin
        if (bit_count == 288) begin // 32*(start + 7 LEDs + stop)
          state <= START;
          shift_data <= 0; // reset for good measure
          bit_count <= 0;
        end else begin
          bit_count <= bit_count + 1;
        end
      end // STOP
    endcase
  end

endmodule