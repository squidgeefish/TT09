module uart_printer (
  input wire clk,
  input wire rst_n,
  output reg uart_out
);
  localparam CLK_SPEED = 25000000;
  localparam UART_PERIOD = 0.000008681;
  localparam UART_COUNTS32 = $rtoi(CLK_SPEED*UART_PERIOD);
  localparam UART_COUNTS = UART_COUNTS32[7:0];
  localparam MSG_LEN = 180;

  // Generated in Python - but I had to flip it around backwards, gah:
  // for c in "Arglius Barglius\r\n"[::-1]:
  //     print("1'b1, {}, 1'b0, ".format(bin(ord(c))).replace("0b", "8'b"), end='')
  reg [MSG_LEN-1 : 0] msg = {1'b1, 8'b1010, 1'b0, 1'b1, 8'b1101, 1'b0, 1'b1, 8'b1110011, 1'b0, 1'b1, 8'b1110101, 1'b0, 1'b1, 8'b1101001, 1'b0, 1'b1, 8'b1101100, 1'b0, 1'b1, 8'b1100111, 1'b0, 1'b1, 8'b1110010, 1'b0, 1'b1, 8'b1100001, 1'b0, 1'b1, 8'b1000010, 1'b0, 1'b1, 8'b100000, 1'b0, 1'b1, 8'b1110011, 1'b0, 1'b1, 8'b1110101, 1'b0, 1'b1, 8'b1101001, 1'b0, 1'b1, 8'b1101100, 1'b0, 1'b1, 8'b1100111, 1'b0, 1'b1, 8'b1110010, 1'b0, 1'b1, 8'b1000001, 1'b0};

  reg [7:0] count;
  reg [7:0] index;

  always @(posedge clk) begin
    if (!rst_n) begin
       count <= 0;
       index <= 0;
       uart_out <= 1;
    end else begin
      if (count == UART_COUNTS) begin
        count <= 0;
        uart_out <= msg[index];
        if (index < MSG_LEN) begin
          index <= index + 1;
        end else begin
          index <= 0;
        end
      end else begin
        count <= count + 1;
      end
    end
  end

endmodule
