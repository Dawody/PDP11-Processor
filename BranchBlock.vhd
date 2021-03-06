LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.MY_PACKAGE.ALL;

ENTITY BRANCH_BLOCK IS
	PORT (
		IR 			: IN STD_LOGIC_VECTOR (IR_SIZE-1 DOWNTO 0);
		FLAG_REGISTER 		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);		--FLAG REGISTER(3 DOWNTO 0)->(_ _ C Z)
		INITIAL_ADDRESS		: OUT STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0);
		CONTROL_WORD		: OUT STD_LOGIC_VECTOR (ROM_WIDTH-1 DOWNTO 0) );
END ENTITY BRANCH_BLOCK;

ARCHITECTURE BRANCH OF BRANCH_BLOCK IS
	-----------------Signals---------
	SIGNAL ROM_OUTPUT 		: STD_LOGIC_VECTOR(ROM_WIDTH-1 DOWNTO 0);
	SIGNAL INSTRUCTION_COUNTER	: STD_LOGIC_VECTOR(0 DOWNTO 0) :="0";
	-----------------ROM------------
	CONSTANT ROM_LENGTH : INTEGER := 2; --LENGTH OF THE ROM USED IN THIS BLOCK
	TYPE ROM_TYPE IS ARRAY(0 TO ROM_LENGTH - 1) OF std_logic_vector(ROM_WIDTH-1 DOWNTO 0);
	CONSTANT ROM_DATA : ROM_TYPE := 
	(
		0 => B"00000_0000_0000_0000_0000_00_00011",	--NO BRANCH	: CONDITION = FALSE
		1 => B"00001_1011_1000_0000_1000_00_00011"	--BRANCH	: CONDITION = TRUE
	);
	BEGIN

	-------------------------circuit to checK the jumping condition depending on the flag register---------------
	

	INSTRUCTION_COUNTER <= 
		"1" WHEN IR(IR_SIZE-1 DOWNTO 8) = BR OR 
			( IR(IR_SIZE-1 DOWNTO 8) = BNE 	AND FLAG_REGISTER(0)<='0' )							OR
			(IR(IR_SIZE-1 DOWNTO 8) = BEQ 	AND FLAG_REGISTER(0)<='1' ) 						OR 
			(IR(IR_SIZE-1 DOWNTO 8) = BLO 	AND FLAG_REGISTER(1)<='1')							OR
			(IR(IR_SIZE-1 DOWNTO 8) = BLS 	AND (FLAG_REGISTER(0) OR FLAG_REGISTER(1))<='1')	OR
			(IR(IR_SIZE-1 DOWNTO 8) = BH 	AND (FLAG_REGISTER(0) OR FLAG_REGISTER(1))<='0')	OR
			(IR(IR_SIZE-1 DOWNTO 8) = BHS 	AND FLAG_REGISTER(1)<='0')							OR
			(IR(IR_SIZE-1 DOWNTO 8) = BGT)														OR	--AND CONDITION
			(IR(IR_SIZE-1 DOWNTO 8) = BGE)															--AND CONDITION
			ELSE	"0";
		



	-------------------------the ROM process---------------
	
	ROM_OUTPUT <= ROM_DATA(to_integer(unsigned(INSTRUCTION_COUNTER)));
	CONTROL_WORD <= ROM_OUTPUT;
	INITIAL_ADDRESS <= (OTHERS => '0');



END BRANCH;


