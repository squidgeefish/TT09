// Sourced from https://github.com/Gatsch/jku-tt06-ledcontroller/blob/main/src/led.v
// Modified to iterate through the data parameter in the opposite direction
//
// Copyright 2024 Mathias Garstenauer
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE−2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

`ifndef __led__
`define __led__

module led #(
	parameter CLK_SPEED = 25_000_000,		//clock speed of the chip
	parameter LED_CNT = 3,					//number of leds
	parameter CHANNELS = 3,					//number of channels per led
	parameter BITPERCHANNEL = 8,			//bits per channel
	parameter PERIOD = 0.00000125,			//period length of one bit
	parameter HIGH0 = 0.0000004,			//high time for a 0 bit
	parameter HIGH1 = 0.0000008,			//high time for a 1 bit
	parameter REFRESH_DURATION = 0.00005	//duration for reset
)(
	input wire [LED_CNT*CHANNELS*BITPERCHANNEL-1:0]data, //data
	output wire led_o,						//output for leds
	input wire clk,							//internal clock
	input wire reset						//chip reset
);
	
	
	//calculating multiple constants out of the parameters 
	localparam DATAWIDTH = LED_CNT*CHANNELS*BITPERCHANNEL;
	localparam DATACOUNTWIDTH = $clog2(DATAWIDTH);
	
	localparam REFRESH_PERIOD32 = $rtoi(CLK_SPEED*REFRESH_DURATION);
	localparam COUNT_PERIOD32 = $rtoi(CLK_SPEED*PERIOD);
	localparam COUNT_0H32 =  $rtoi(CLK_SPEED*HIGH0);
	localparam COUNT_1H32 =  $rtoi(CLK_SPEED*HIGH1);
	
	localparam COUNTWIDTH = $clog2(REFRESH_PERIOD32);
	//truncation to discard errors with operators later on
	localparam REFRESH_PERIOD = REFRESH_PERIOD32[COUNTWIDTH-1:0];
	localparam COUNT_PERIOD = COUNT_PERIOD32[COUNTWIDTH-1:0];
	localparam COUNT_0H = COUNT_0H32[COUNTWIDTH-1:0];
	localparam COUNT_1H = COUNT_1H32[COUNTWIDTH-1:0];
	
	localparam Refresh = 1'b0;
	localparam Write = 1'b1;
	
	reg [DATACOUNTWIDTH-1:0] datacounter, next_datacounter;
	reg [COUNTWIDTH-1:0] counter, next_counter;
	reg state, next_state;
	reg led_out;

	//the registers are updated each clock cylce with their new values
	always @(posedge clk) begin
		if (reset) begin
			state <= 0;
			counter <= 0;
			datacounter <= DATAWIDTH-1'b1;
		end else begin
			counter <= next_counter;
			datacounter <= next_datacounter;
			state <= next_state;
		end
		
	end
	
	//updates the leds constantly (includes a refresh period)
	always @(counter or datacounter) begin
		next_counter <= counter;
		next_datacounter <= datacounter;
		next_state <= state;
		led_out <= 1'b0;
		case (state) 
			//refresh for the leds the counter value is calculated from 
			//the internal clock as well as the needed duration
			Refresh: begin
				if (counter < REFRESH_PERIOD) begin
					next_counter <= counter + 1;
				end else begin
					next_counter <= 0;
					next_state <= Write;
				end
			end
			//writes the bits from data to the leds
			Write: begin
				if (counter < COUNT_PERIOD-1'b1) begin	//runs for one period
					next_counter <= counter + 1;
				end else begin
					next_counter <= 0;
					if (datacounter > 0) begin	//runs for all bits
						next_datacounter <= datacounter - 1;
					end else begin
						next_datacounter <= DATAWIDTH-1'b1;
						next_state <= Refresh;
					end
				end
				//set output to low at the right time according to the current bit
				if (counter < ((data[datacounter])?COUNT_1H:COUNT_0H)) begin
					led_out <= 1'b1;
				end else begin
					led_out <= 1'b0;
				end
			end
		endcase   
	end
	assign led_o = led_out;
endmodule

`endif
