`timescale 1ns / 1ps
module top(
    input clock,
    input reset,
    input enable,
    input start
    );

	wire we_wire;
	wire [9:0] d_addr_wire;
	wire [31:0] in_wire;
	wire [31:0] out_wire;
	wire [10:0] pc_wire;
	wire [31:0] ins_wire;

	CPU cpu(
		.clock(clock),
		.reset(reset),
		.enable(enable),
		.start(start),
		.we(we_wire),
		.d_addr(d_addr_wire),
		.in_data(in_wire),
		.out_data(out_wire),
		.i_addr(pc_wire),
		.ins(ins_wire)
	);

	Data_Memory d_memory(
		.address(d_addr_wire),
		.we(we_wire),
		.data_in(out_wire),
		.data_out(in_wire)
	);

	Ins_Memory i_memory(
		.address(pc_wire),
		.data_out(ins_wire)
	);

endmodule
