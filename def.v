//status
`define idle	1'b0
`define exec	1'b1

//Instructions
`define NOP		6'b0_00000
`define ORI		6'b0_00001
`define LW		6'b0_00010
`define SW   	6'b0_00011
`define ADDI    6'b0_00100
`define R       6'b0_00101
`define SLTI    6'b0_00110
`define ANDI	6'b0_00111
`define BEQ		6'b0_01000
`define XORI	6'b0_01001
`define LUI		6'b0_01010
`define J 		6'b0_01011
`define BGTZ	6'b0_01100
`define BGEZ	6'b0_01101
`define BNE		6'b0_01110

//R funct
`define ADD 	6'b0_00000
`define SLL		6'b0_00001
`define JR      6'b0_00010
`define AND 	6'b0_00011
`define OR 		6'b0_00100
`define XOR 	6'b0_00101
`define SRL		6'b0_00110
`define SRA 	6'b0_00111
`define SLLV	6'b0_01000
`define SRLV	6'b0_01001
`define SRAV	6'b0_01010
`define MOVZ	6'b0_01011
`define SUB		6'b0_01100
`define SLT 	6'b0_01101
`define MULT	6'b0_01110

//Global Regs
`define gr0		5'b00000
`define gr1		5'b00001
`define gr2		5'b00010
`define gr3		5'b00011
`define gr4		5'b00100
`define gr5		5'b00101
`define gr6		5'b00110
`define gr7		5'b00111
`define gr8		5'b01000
`define gr9		5'b01001
`define gr10	5'b01010
`define gr11	5'b01011
`define gr12	5'b01100
`define gr13	5'b01101
`define gr14	5'b01110
`define gr15	5'b01111
`define gr16	5'b10000
`define gr17	5'b10001
`define gr18	5'b10010
`define gr19	5'b10011
`define gr20	5'b10100
`define gr21	5'b10101
`define gr22	5'b10110
`define gr23	5'b10111
`define gr24	5'b11000
`define gr25	5'b11001
`define gr26	5'b11010
`define gr27	5'b11011
`define gr28	5'b11100
`define gr29	5'b11101
`define gr30	5'b11110
`define gr31	5'b11111