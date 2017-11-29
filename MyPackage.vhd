LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE MY_PACKAGE IS
	---------------The Constants
	--Counters 
	CONSTANT MAIN_COUNTER_OUTPUT_SIZE :INTEGER := 3;
	CONSTANT INSTRUCTION_COUNTER_OUTPUT_SIZE : INTEGER := 3;
	--IR Size 
	CONSTANT IR_SIZE: INTEGER := 16;
	--ROM Width
	CONSTANT ROM_WIDTH: INTEGER := 28;
	--Address modes
	CONSTANT REG_ADDRESSING_MODE : INTEGER := 0;
	CONSTANT AUTO_INCR_ADDRESSING_MODE : INTEGER := 1;
	CONSTANT AUTO_DECR_ADDRESSING_MODE : INTEGER := 2;
	CONSTANT INDEXED_ADDRESSING_MODE : INTEGER := 3;
	--CLK period
	CONSTANT HALF_CYCLE : TIME := 50 PS;
	--MODE CONSTANTS
	CONSTANT MODE_BITS_NUM: integer := 3;
	CONSTANT NO_INSTRUCTION:STD_LOGIC_VECTOR (MODE_BITS_NUM-1 DOWNTO 0):="000";
	CONSTANT TWO_OPERAND:STD_LOGIC_VECTOR (MODE_BITS_NUM-1 DOWNTO 0):="001";
	CONSTANT ONE_OPERAND:STD_LOGIC_VECTOR (MODE_BITS_NUM-1 DOWNTO 0):="010";
	CONSTANT ZERO_OPERAND:STD_LOGIC_VECTOR (MODE_BITS_NUM-1 DOWNTO 0):="011";
	CONSTANT BRANCH:STD_LOGIC_VECTOR (MODE_BITS_NUM-1 DOWNTO 0):="100";
	
	--Branch OP codes
	CONSTANT NO_JUMP	: INTEGER := 0;
	CONSTANT JUMP		: INTEGER := 1;
	CONSTANT BRANCH_MODE_IR_OPCODE	:INTEGER :=8;
	CONSTANT BR	:STD_LOGIC_VECTOR (BRANCH_MODE_IR_OPCODE-1 DOWNTO 0):=X"81";
	CONSTANT BNE	:STD_LOGIC_VECTOR (BRANCH_MODE_IR_OPCODE-1 DOWNTO 0):=X"82";
	CONSTANT BEQ	:STD_LOGIC_VECTOR (BRANCH_MODE_IR_OPCODE-1 DOWNTO 0):=X"83";
	CONSTANT BLO	:STD_LOGIC_VECTOR (BRANCH_MODE_IR_OPCODE-1 DOWNTO 0):=X"84";
	CONSTANT BLS	:STD_LOGIC_VECTOR (BRANCH_MODE_IR_OPCODE-1 DOWNTO 0):=X"85";
	CONSTANT BH	:STD_LOGIC_VECTOR (BRANCH_MODE_IR_OPCODE-1 DOWNTO 0):=X"86";
	CONSTANT BHS	:STD_LOGIC_VECTOR (BRANCH_MODE_IR_OPCODE-1 DOWNTO 0):=X"87";
	CONSTANT BGE	:STD_LOGIC_VECTOR (BRANCH_MODE_IR_OPCODE-1 DOWNTO 0):=X"88";
	CONSTANT BGT	:STD_LOGIC_VECTOR (BRANCH_MODE_IR_OPCODE-1 DOWNTO 0):=X"89";
	
END MY_PACKAGE;



-----------------------------------------------------------------------------------
------------------------------------Table 1----------------------------------------

-----------------------------------------
--  CODE	|	Register				|
-----------------------------------------
--	0000	|	NO Register is selected	|
--	0001	|	R0						|
--	0010	|	R1						|
--	0011	|	R2						|
--	0100	|	R3						|
--	0101	|	R4						|
--	0110	|	R5						|
--	0111	|	R6						|
--	1000	|	R7						|
--	1001	|	MAR						|
--	1010	|	MDR						|
--	1011	|	IR 						|
--	1100	|	SRC						|
--	1111	|	PLACE HOLDER (used only by the CU)
-----------------------------------------


-----------------------------------------------------------------------------------
------------------------------------Table 2----------------------------------------

-----------------------------------------
--  CODE	|	Register				|
-----------------------------------------
--	00		|	NO Register is selected	|
--	01		|	MAR						|
--	10		|	MDR						|
--	11		|	SRC						|
-----------------------------------------




