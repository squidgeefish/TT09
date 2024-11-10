/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_wokwi_413387065339458561 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire not_reset;
  assign not_reset = ~rst_n;

  // Easier to shuffle than if I'd made a single giant wire
  wire [23:0] pixel_0;
  wire [23:0] pixel_1;
  wire [23:0] pixel_2;
  wire [23:0] pixel_3;
  wire [23:0] pixel_4;
  wire [23:0] pixel_5;
  wire [23:0] pixel_6;

  apa102_in spi_in(
    .clk(clk),
    .rst_n(rst_n),
    .sck(ui_in[0]),
    .sda(ui_in[1]),
    .data_out({pixel_0, pixel_1, pixel_2, pixel_3, pixel_4, pixel_5, pixel_6})
  );
  // data_out is a pruned version of the SPI stream that loses the first 8 bits (intensity value)
  // of each 32-bit pixel value so we don't have to discard them via routing - this saves like 8%

  // APA102s are BGR; WS2812s expect GRB. So we have to shuffle the subpixel order.
  led #( .LED_CNT(7) ) ws2812_out (
    .clk(clk),
    .reset(not_reset),
    .led_o(uo_out[0]),
    .data({
      pixel_0[15:8], pixel_0[7:0], pixel_0[23:16],
      pixel_1[15:8], pixel_1[7:0], pixel_1[23:16],
      pixel_2[15:8], pixel_2[7:0], pixel_2[23:16],
      pixel_3[15:8], pixel_3[7:0], pixel_3[23:16],
      pixel_4[15:8], pixel_4[7:0], pixel_4[23:16],
      pixel_5[15:8], pixel_5[7:0], pixel_5[23:16],
      pixel_6[15:8], pixel_6[7:0], pixel_6[23:16]
      })
  );

  uart_printer uart_output (
    .clk(clk),
    .rst_n(rst_n),
    .uart_out(uo_out[1])
  );

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out = 8'b0;
  assign uio_oe  = 0;
  assign uo_out[7:2]  = 6'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ui_in[7:2], ena, uio_in[7:0], rst_n, 1'b0}; 

endmodule
