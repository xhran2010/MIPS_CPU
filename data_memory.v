`timescale 1ns / 1ps

module Data_Memory(
    input [9:0] address,
    input we,
    input [31:0] data_in,
    output reg [31:0] data_out
    );
	 
	reg [31:0] data_memory [1023:0];
	
	always @ (*)
		begin
			if(we == 0) data_out <= data_memory[address];
			else if(we == 1) data_memory[address] <= data_in;
		end
	
endmodule
