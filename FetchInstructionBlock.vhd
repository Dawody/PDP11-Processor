LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.MY_PACKAGE.ALL;

ENTITY FETCH_INSTRUCTION_BLOCK IS
	PORT(
		INSTRUCTION_COUNTER	: IN STD_LOGIC_VECTOR	(INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0);
		INITIAL_ADDRESS 	: OUT STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0); 
		CONTROL_WORD		: OUT STD_LOGIC_VECTOR	(ROM_WIDTH-1 DOWNTO 0) );
END ENTITY FETCH_INSTRUCTION_BLOCK;

ARCHITECTURE FETCH_INSTRUCTION OF FETCH_INSTRUCTION_BLOCK IS
	-----------------Signals---------
	SIGNAL ROM_OUTPUT : STD_LOGIC_VECTOR(ROM_WIDTH-1 DOWNTO 0);
	-----------------ROM------------
	CONSTANT ROM_LENGTH : INTEGER := 2; --LENGTH OF THE ROM USED IN THIS BLOCK
	TYPE ROM_TYPE IS ARRAY(0 TO ROM_LENGTH - 1) OF std_logic_vector(ROM_WIDTH-1 DOWNTO 0);
	CONSTANT ROM_DATA : ROM_TYPE := 
	(
		0 => B"01100_1000_0000_1001_1000_00_10000",
		1 => B"00000_1010_0000_1011_0000_00_00010"
	);
	BEGIN
-------------------------the ROM process---------------
	ROM_OUTPUT <= ROM_DATA(to_integer(unsigned(INSTRUCTION_COUNTER)));
	CONTROL_WORD <= ROM_OUTPUT;
	INITIAL_ADDRESS <= (OTHERS => '0');

END FETCH_INSTRUCTION;
