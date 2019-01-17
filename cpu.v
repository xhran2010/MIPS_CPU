`timescale 1ns / 1ps
`include "def.v"
module CPU(
	input clock,
	input reset,
	input enable,
	input start,
	input [31:0] in_data,
	input [31:0] ins,
	output [31:0] out_data,
	output we,
	output [9:0] d_addr,
	output [9:0] i_addr
    );
	 
	reg state = 0, next_state = 0;
	reg dw;
	reg sf,zf,cf_temp,cf;
	reg branch_second;
	reg [31:0] pc;
	reg [31:0] IR,ex_reg,mem_reg,wb_reg;
	reg [31:0] reg_A,reg_B,reg_C,reg_Imm,reg_Shamt,reg_funct;
	reg [25:0] reg_Addr;
	reg [31:0] gr[31:0];
	reg [31:0] ALUo,ALUo_ext,LMD,ALU_data,ALU_data_ext,ALU_data_next,ALU_data_next_ext,HI,LO;
	reg [31:0] MEMo;
	reg [9:0] MEMaddr;
	reg [31:0] store_data,store_data_next;
	

	// initial cpu
	always @(posedge clock) begin
		if (reset == 1) begin
			// reset
			IR<=0; pc<=0; ex_reg<=0; mem_reg<=0; wb_reg<=0;
			reg_A<=0; reg_B<=0; reg_C<=0; reg_Imm<=0; reg_Shamt<=0; reg_funct<=0;
			gr[0] <= 0;gr[1] <= 32'b0000000000000000000000000000001;gr[2] <= 32'b0000010000110000001000111000001;
			gr[3] <= 32'b01111000000000000000000000000000;
			gr[4] <= 32'b00000010000110000001000111000000;gr[5] <= 0;gr[6] <= 0;gr[7] <= 0;
			gr[8] <= 0;gr[9] <= 0;gr[10] <= 0;gr[11] <= 0;
			gr[12] <= 0;gr[13] <= 0;gr[14] <= 0;gr[15] <= 0;
			gr[16] <= 0;gr[17] <= 0;gr[18] <= 0;gr[19] <= 0;
			gr[20] <= 0;gr[21] <= 0;gr[22] <= 0;gr[23] <= 0;
			gr[24] <= 0;gr[25] <= 0;gr[26] <= 0;gr[27] <= 0;
			gr[28] <= 0;gr[29] <= 0;gr[30] <= 0;gr[31] <= 0;
			ALUo<=0; LMD<=0; ALU_data<=0; ALU_data_next<=0;HI<=0;LO<=0;
			store_data<=0; store_data_next<=0;
		end
	end

	// CPU Control
	always @(posedge clock)
		begin
			if(reset == 1)
				state <= `idle;
			else
				state <= next_state;
		end
	
	always @(*)
		begin
			case (state)
				`idle:
					if ((enable == 1'b1) && (start == 1'b1)) next_state <= `exec;
					else next_state <= `idle;
				`exec:
					if (enable == 1'b0) next_state <= `idle;
					else next_state <= `exec;
			endcase
		end

	// IF
	assign i_addr = pc[9:0];
	always @(posedge clock)
		begin
			if(state == `exec)
				begin
					IR <= ins;
					pc = pc + 1;
				end
		end
	
	// ID
	
	always @(posedge clock)
		begin
			if(state == `exec)
				begin
					ex_reg <= IR;
					// 处理控制冲突
					if (isBranchType(IR[31:26])) begin
						pc <= pc - 1;// or PC <= PC;
						IR <= {`NOP,26'b00000000000000000000000000};
						branch_second <= 1;
					end
					if (branch_second == 1) begin
						pc <= pc - 1;
						IR <= {`NOP,26'b00000000000000000000000000};
						branch_second <= 0;
					end
					// 处理LOAD引起的冲突
					if (IR[31:26] == `LW && ( (isRIALU(ins[31:26]) && ins[25:21] == IR[20:16]) || ( ins[31:26==`R] && (ins[25:21] == IR[20:16] || ins[20:16] == IR[20:16] ) ) ) )  begin
						pc <= pc - 1;
						IR <= {`NOP,26'b00000000000000000000000000};
					end
					if(isItype(IR[31:26]))
						begin
							if(IR[31:26] == `SW) store_data <= gr[IR[20:16]]; // ? 存疑, store需要处理吗?
							// Data Forwarding 处理冲突
							if(isDFConflict(ex_reg[31:26])&& (isRIALU(ex_reg[31:26]) && IR[25:21] == ex_reg[20:16]) || (ex_reg[31:26] == `R && IR[25:21] == ex_reg[15:11]))  
								reg_A <= ALUo;
							else if (isDFConflict(mem_reg[31:26])&& ( (isRIALU(mem_reg[31:26] && IR[25:21] == mem_reg[20:16])) || (mem_reg[31:26] == `R && IR[25:21] == mem_reg[15:11]) 
								|| (mem_reg[31:26] == `LW && IR[25:21] == mem_reg[20:16]) )) begin
								if (mem_reg[31:26] == `LW) reg_A <= in_data;
								else reg_A <= ALU_data;
							end
							else if (isDFConflict(wb_reg[31:26])&& (isRIALU(wb_reg[31:26]) && IR[25:21] == wb_reg[20:16]) || (wb_reg[31:26] == `R && IR[25:21] == wb_reg[15:11]))  
								reg_A <= ALU_data_next;
							else reg_A <= gr[IR[25:21]];
							reg_B <= gr[IR[20:16]];
							// 符号位扩展
							if(isSignType(IR[31:26]) && IR[15] == 1'b1) reg_Imm <= {16'b1111111111111111,IR[15:0]};
							else reg_Imm <= {16'b0000000000000000,IR[15:0]};
						end
					else if(IR[31:26] == `R)
						begin
							// ***** 若当前指令是R类指令，Data Forwarding相关代码
							if (isDFConflict(ex_reg[31:26])) begin
								if (ex_reg[31:26] == `R) begin
									if(IR[25:21] == ex_reg[15:11]) begin
										reg_A <= ALUo;
										reg_B <= gr[IR[20:16]];
									end 
									else if(IR[20:16] == ex_reg[15:11]) begin
										reg_A <= gr[IR[25:21]];
										reg_B <= ALUo;
									end
									else begin
										reg_A <= gr[IR[25:21]];
										reg_B <= gr[IR[20:16]];
									end
								end
								else if (isRIALU(ex_reg[31:26])) begin
									if(IR[25:21] == ex_reg[20:16]) begin
										reg_A <= ALUo;
										reg_B <= gr[IR[20:16]];
									end 
									else if(IR[20:16] == ex_reg[20:16]) begin
										reg_A <= gr[IR[25:21]];
										reg_B <= ALUo;
									end 
									else begin
										reg_A <= gr[IR[25:21]];
										reg_B <= gr[IR[20:16]];
									end
								end
							end
							else if (isDFConflict(mem_reg[31:26])) begin
								if (mem_reg[31:26] == `R) begin //前条指令为R类指令
									if(IR[25:21] == mem_reg[15:11]) begin
										reg_A <= ALU_data;
										reg_B <= gr[IR[20:16]];
									end 
									else if(IR[20:16] == mem_reg[15:11]) begin
										reg_A <= gr[IR[25:21]];
										reg_B <= ALU_data;
									end 
									else begin
										reg_A <= gr[IR[25:21]];
										reg_B <= gr[IR[20:16]];
									end
								end
								else if (isRIALU(mem_reg[31:26]) || mem_reg[31:26] == `LW) begin 
									if(IR[25:21] == mem_reg[20:16]) begin
										if(mem_reg[31:26] == `LW) reg_A<=in_data;
										else reg_A <= ALU_data;
										reg_B <= gr[IR[20:16]];
									end 
									else if(IR[20:16] == mem_reg[20:16]) begin
										reg_A <= gr[IR[25:21]];
										if(mem_reg[31:26] == `LW) reg_B<=in_data;
										else reg_B <= ALU_data;
									end 
									else begin
										reg_A <= gr[IR[25:21]];
										reg_B <= gr[IR[20:16]];
									end
								end
							end
							else if (isDFConflict(wb_reg[31:26])) begin
								if (wb_reg[31:26] == `R) begin
									if(IR[25:21] == wb_reg[15:11]) begin
										reg_A <= ALU_data_next;
										reg_B <= gr[IR[20:16]];
									end 
									else if(IR[20:16] == wb_reg[15:11]) begin
										reg_A <= gr[IR[25:21]];
										reg_B <= ALU_data_next;
									end 
									else begin
										reg_A <= gr[IR[25:21]];
										reg_B <= gr[IR[20:16]];
									end
								end
								else if (isRIALU(wb_reg[31:26])) begin
									if(IR[25:21] == wb_reg[20:16]) begin
										reg_A <= ALU_data_next;
										reg_B <= gr[IR[20:16]];
									end 
									else if(IR[20:16] == wb_reg[20:16]) begin
										reg_A <= gr[IR[25:21]];
										reg_B <= ALU_data_next;
									end 
									else begin
										reg_A <= gr[IR[25:21]];
										reg_B <= gr[IR[20:16]];
									end
								end
							end
							else begin
								reg_A <= gr[IR[25:21]];
								reg_B <= gr[IR[20:16]];
							end
							// ******** Data Forwarding 结束
							reg_C <= gr[IR[15:11]];
							reg_Shamt <= IR[10:6];
							reg_funct <= IR[5:0];
					end
					else if(IR[31:26] == `J) begin
						reg_Addr <= IR[25:0];
					end
				end
		end
	
	// EX
	always @(posedge clock)
		begin
			if(state == `exec)
				begin
					mem_reg <= ex_reg;
					//确定传到下一个周期的值
					if(ex_reg[31:26] == `LUI) begin
						ALU_data[31:16] <= reg_Imm[15:0];
						ALU_data[15:0] <= 16'b0000000000000000;
					end
					else if(ex_reg[31:26] == `R && ex_reg[5:0] == `MOVZ && reg_B == 0) ALU_data <= reg_A;
					//else if(ex_reg[31:26] == `R && reg_funct == `MULT) {ALU_data,ALU_data_ext} <= {ALUo,ALUo_ext};
					else {ALU_data,ALU_data_ext} <= {ALUo,ALUo_ext};
					// 标志位的判断和更新
					if (ALUo == 0) zf <=1;  else zf <= 0;
					if (ALUo[31] == 1) sf <= 1; else sf <= 0;
					cf <= cf_temp;
					// JUMP或JUMPR指令的处理
					if (ex_reg[31:26] == `R && reg_funct == `JR) pc <= reg_A;
					else if(ex_reg [31:26] == `J) pc <= { pc[31:28],reg_Addr,2'b00 };
					// STORE指令的处理
					if (ex_reg[31:26] == `SW) begin
						dw <= 1;
						store_data_next <= store_data;
					end
					else begin
						dw <= 0;
						store_data_next <= store_data_next;
					end
				end
		end
	
	// MEM
	assign d_addr = ALU_data[9:0];
	assign we = dw;
	assign out_data = store_data_next;
	always @(posedge clock)
		begin
			if(state == `exec)
				begin
					wb_reg <= mem_reg;
					if(mem_reg[31:26] == `SLTI || ( mem_reg[31:26] == `R && mem_reg[5:0] == `SLT )) begin
						ALU_data_next <= cf;
					end
					else if(mem_reg[31:26] == `ADD && cf == 1) ALU_data_next <= 0; 
					else {ALU_data_next,ALU_data_next_ext} <= {ALU_data,ALU_data_ext};
					// 分支指令改变PC值的处理
					if (mem_reg[31:26] == `BEQ && zf == 1) pc <= pc + reg_Imm - 1;
					if (mem_reg[31:26] == `BGTZ && cf == 0 && zf == 0) pc <= pc + reg_Imm - 1;
					if (mem_reg[31:26] == `BGEZ && cf == 0) pc <= pc + reg_Imm -1;
					if (mem_reg[31:26] == `LW) LMD <= in_data;
				end
		end
	
	// WB
	always @(posedge clock)
		begin
			if(state == `exec)
				begin
					if(wb_reg[31:26] == `LW) gr[wb_reg[20:16]] <= LMD;
					else if(isRIALU(wb_reg[31:26]) || wb_reg[31:26] == `LUI) gr[wb_reg[20:16]] <= ALU_data_next;
					else if(wb_reg[31:26] == `R) begin
						if(wb_reg[5:0] == `MULT) {HI,LO} <= {ALU_data_next,ALU_data_next_ext};
						else gr[wb_reg[15:11]] <= ALU_data_next;
					end 
				end
		end
	
	// 函数
	
	function isItype;// 判断是否为I类指令
		input [5:0] op;
		begin
			isItype = (
			(op == `LW) || (op == `SW) || (op == `ADDI) ||
			(op == `SLTI) || (op == `ANDI) || (op == `BEQ) ||
			(op == `ORI) || (op == `XORI) || (op == `LUI) ||
			(op == `BGTZ) || (op == `BGEZ)
			);
		end
	endfunction

	function isSignType; // 判断是否为有符号数计算
		input [5:0] op;
		begin
			isSignType = (
			(op == `ADDI) || (op == `SLTI) || (op == `ADD) || (op == `SUB) || (op == `MULT)
			);
		end
	endfunction
	
	function isRIALU;// 判断是否为立即数类计算指令
		input [5:0] op;
		begin
			isRIALU = (
			(op == `ADDI) || (op == `SLTI) || (op == `ANDI) ||
			(op == `ORI) || (op == `XORI)
			);
		end
	endfunction

	function isDFConflict;// 判断是否可能造成数据冲突并可以使用DF解决的
		input [5:0] op;
		begin
			isDFConflict = (
			(op == `R) || isRIALU(op) || (op == `LW)
			);
		end
	endfunction

	function isBranchType;
		input [5:0] op;
		begin
			isBranchType = (
			(op == `BEQ) || (op == `BGTZ) || (op == `BGEZ)
			);
		end
	endfunction

	// ALU
	always @(*)
		begin
			if (ex_reg[31:26] == `LW || ex_reg[31:26] == `SW || ex_reg[31:26] == `ADDI) ALUo <= reg_A + reg_Imm;
			else if(ex_reg[31:26] == `SLTI) {cf_temp,ALUo} <= reg_A - reg_Imm;
			else if(ex_reg[31:26] == `ANDI) ALUo <= reg_A & reg_Imm;
			else if(ex_reg[31:26] == `ORI) ALUo <= reg_A | reg_Imm;
			else if(ex_reg[31:26] == `XORI) ALUo <= reg_A ^ reg_B;
			else if (ex_reg[31:26] == `BEQ) ALUo <= reg_A - reg_B;
			else if(ex_reg[31:26] == `BGTZ || ex_reg[31:26] == `BGEZ) {cf_temp,ALUo} <= reg_A - 32'b00000000000000000000000000000000;
			else if(ex_reg[31:26] == `R) begin
				if(reg_funct == `ADD) {cf_temp,ALUo} <= reg_A + reg_B;
				else if (reg_funct == `SUB || reg_funct == `SLT) {cf_temp,ALUo} <= reg_A - reg_B;
				else if (reg_funct == `MULT) {ALUo,ALUo_ext} <= reg_A * reg_B;
				else if (reg_funct == `SLL && reg_A == 0) ALUo <= reg_B << reg_Shamt;
				else if (reg_funct == `SRL && reg_A == 0) ALUo <= reg_B >> reg_Shamt;
				else if (reg_funct == `SRA && reg_A == 0) ALUo <= ($signed(reg_B)) >>> reg_Shamt;
				else if (reg_funct == `SLLV) ALUo <= reg_B << reg_A[4:0];
				else if (reg_funct == `SRLV) ALUo <= reg_B >> reg_A[4:0];
				else if (reg_funct == `SRAV) ALUo <= ($signed(reg_B)) >>> reg_A[4:0];
				else if (reg_funct == `AND) ALUo <= reg_A & reg_B;
				else if (reg_funct == `OR) ALUo <= reg_A | reg_B;
				else if (reg_funct == `XOR) ALUo <= reg_A ^ reg_B;
			end
		end
endmodule