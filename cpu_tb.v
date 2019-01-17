`timescale 1ns / 1ps

module cpu_tb;

	// Inputs
	reg clock;
	reg reset;
	reg enable;
	reg start;
	//reg [31:0] i_in;

	// Outputs
	//wire output_data;

	// Instantiate the Unit Under Test (UUT)
	top uut (
		.clock(clock), 
		.reset(reset), 
		.enable(enable), 
		.start(start)
		//.i_in(i_in), 
		//.output_data(output_data)
	);

	initial begin
		// Initialize Inputs
		clock = 0;
		reset = 1;
		enable = 0;
		start = 0;
		

		// Wait 100 ns for global reset to finish
		#101;
		reset = 0;
		enable = 1;
		start = 1;
		// Add stimulus here

	end
	
	always #100 clock = ~clock;
      
endmodule

