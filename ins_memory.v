`timescale 1ns / 1ps

module Ins_Memory(
    input [9:0] address,
    output reg [31:0] data_out
    );
	 
	reg [31:0] i_memory [1023:0];

	initial $readmemb("i.txt",i_memory);
	
	always @ (*)
		begin
			data_out <= i_memory[address];
		end
	
endmodule
