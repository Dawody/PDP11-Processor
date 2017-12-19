LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.MY_PACKAGE.ALL;

ENTITY EXECUTE_BLOCK IS
	PORT (
		IR : IN std_logic_vector (IR_SIZE-1 DOWNTO 0);
		INSTRUCTION_COUNTER : IN STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0); 
		CONTROL_WORD: OUT STD_LOGIC_VECTOR (ROM_WIDTH-1 DOWNTO 0);
		INITIAL_ADDRESS: INOUT STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0) );
END ENTITY EXECUTE_BLOCK;

ARCHITECTURE EXECUTE OF EXECUTE_BLOCK IS
	
	-----------------Signals---------
	SIGNAL ROM_OUTPUT : STD_LOGIC_VECTOR(ROM_WIDTH-1 DOWNTO 0);
	SIGNAL IR_SRC : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL IR_SRC_ADDRESS_MODE : STD_LOGIC_VECTOR (2 DOWNTO 0);
	SIGNAL IR_DEST : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL IR_DEST_ADDRESS_MODE : STD_LOGIC_VECTOR (2 DOWNTO 0);

	SIGNAL MODE : std_logic_vector(MODE_BITS_NUM-1 DOWNTO 0);
	SIGNAL INITIAL_ADDRESS_SIGNAL : STD_LOGIC_VECTOR(INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0);
	
	-----------------ROMS------------
	CONSTANT TWO_OPP_ROM_LENGTH : INTEGER := 4; --LENGTH OF THE ROM USED IN THIS BLOCK
	TYPE TWO_OPP_ROM_TYPE IS ARRAY(0 TO TWO_OPP_ROM_LENGTH - 1) OF std_logic_vector(ROM_WIDTH-1 DOWNTO 0);
	CONSTANT TWO_OPP_ROM_DATA : TWO_OPP_ROM_TYPE := 
	(
		0 => B"11111_1111_1111_0000_1111_00_00011",
		1 => B"11111_1100_1111_0000_1111_00_00011",
		2 => B"11111_1111_1010_0000_0000_10_01111",
		3 => B"11111_1100_1010_0000_0000_10_01111"
	);

	CONSTANT COMP_ROM_DATA : TWO_OPP_ROM_TYPE := 
	(
		0 => B"00011_1111_1111_0000_0000_00_00011",
		1 => B"00011_1100_1111_0000_0000_00_00011",
		2 => B"00011_1111_1010_0000_0000_00_00011",
		3 => B"00011_1100_1010_0000_0000_00_00011"
	);
	
	CONSTANT ONE_OPP_ROM_LENGTH : INTEGER := 2; --LENGTH OF THE ROM USED IN THIS BLOCK
	TYPE ONE_OPP_ROM_TYPE IS ARRAY(0 TO ONE_OPP_ROM_LENGTH - 1) OF std_logic_vector(ROM_WIDTH-1 DOWNTO 0);
	CONSTANT ONE_OPP_ROM_DATA : ONE_OPP_ROM_TYPE := 
	(
--		0 => B"11111_0000_1111_0000_1111_00_00011",
--		1 => B"11111_0000_1010_0000_0000_10_01111"
		0 => B"11111_1111_0000_0000_1111_00_00011",
		1 => B"11111_1010_0000_0000_0000_10_01111"

	);

	
	BEGIN
-----------CIRCUIT THAT CLASSIFY THE OPPERATION TYPE ACCORDING TO THE IR OPCODE-----------
	MODE <= TWO_OPERAND 	WHEN 	IR(15 DOWNTO 12) = MOV OR
					IR(15 DOWNTO 12) = ADD OR
					IR(15 DOWNTO 12) = ADC OR
					IR(15 DOWNTO 12) = SUBB OR
					IR(15 DOWNTO 12) = SBC OR
					IR(15 DOWNTO 12) = BIC OR
					IR(15 DOWNTO 12) = BIS OR
					IR(15 DOWNTO 12) = ORR OR
			 		IR(15 DOWNTO 12) = ANDD OR
			 		IR(15 DOWNTO 12) = XORR

	ELSE	COMPAIR		WHEN 	IR(15 DOWNTO 12) = COMP

	ELSE	ONE_OPERAND	WHEN	IR(15 DOWNTO 6) = INC OR
			 		IR(15 DOWNTO 6) = DEC OR
			 		IR(15 DOWNTO 6) = CLR OR
			 		IR(15 DOWNTO 6) = INV OR
			 		IR(15 DOWNTO 6) = LSR OR
			 		IR(15 DOWNTO 6) = RORR OR
			 		IR(15 DOWNTO 6) = RRC OR
			 		IR(15 DOWNTO 6) = ASR OR
			 		IR(15 DOWNTO 6) = LSL OR
			 		IR(15 DOWNTO 6) = ROLL OR
			 		IR(15 DOWNTO 6) = RLC;
			 	


	-------------------------Circuit that calculate the initial value-----------
	IR_DEST_ADDRESS_MODE <= IR(5 DOWNTO 3);
	IR_SRC_ADDRESS_MODE <= IR(11 DOWNTO 9);
	
	INITIAL_ADDRESS <=	"000" 	WHEN ( MODE = TWO_OPERAND OR MODE = COMPAIR ) AND IR_SRC_ADDRESS_MODE = REG_ADDRESSING_MODE AND IR_DEST_ADDRESS_MODE = REG_ADDRESSING_MODE	--R,R
			ELSE 	"001" 	WHEN ( MODE = TWO_OPERAND OR MODE = COMPAIR ) AND ( IR_SRC_ADDRESS_MODE = AUTO_INCR_ADDRESSING_MODE OR IR_SRC_ADDRESS_MODE = AUTO_DECR_ADDRESSING_MODE OR IR_SRC_ADDRESS_MODE = INDEXED_ADDRESSING_MODE ) AND IR_DEST_ADDRESS_MODE = REG_ADDRESSING_MODE 	--M,R
			ELSE 	"010" 	WHEN ( MODE = TWO_OPERAND OR MODE = COMPAIR ) AND IR_SRC_ADDRESS_MODE = REG_ADDRESSING_MODE AND ( IR_DEST_ADDRESS_MODE = AUTO_INCR_ADDRESSING_MODE OR IR_DEST_ADDRESS_MODE = AUTO_DECR_ADDRESSING_MODE OR IR_DEST_ADDRESS_MODE = INDEXED_ADDRESSING_MODE ) 	--R,M
			ELSE 	"011" 	WHEN ( MODE = TWO_OPERAND OR MODE = COMPAIR ) AND ( IR_SRC_ADDRESS_MODE = AUTO_INCR_ADDRESSING_MODE OR IR_SRC_ADDRESS_MODE = AUTO_DECR_ADDRESSING_MODE OR IR_SRC_ADDRESS_MODE = INDEXED_ADDRESSING_MODE ) AND ( IR_DEST_ADDRESS_MODE = AUTO_INCR_ADDRESSING_MODE OR IR_DEST_ADDRESS_MODE = AUTO_DECR_ADDRESSING_MODE OR IR_DEST_ADDRESS_MODE = INDEXED_ADDRESSING_MODE )	--M,M
			ELSE	"000"	WHEN ( MODE = ONE_OPERAND) AND IR_DEST_ADDRESS_MODE = REG_ADDRESSING_MODE	--R
			ELSE	"001"	WHEN ( MODE = ONE_OPERAND) AND ( IR_DEST_ADDRESS_MODE = AUTO_INCR_ADDRESSING_MODE OR IR_DEST_ADDRESS_MODE = AUTO_DECR_ADDRESSING_MODE OR IR_DEST_ADDRESS_MODE = INDEXED_ADDRESSING_MODE )	--M
			ELSE 	"111";	--MOSEBA


	INITIAL_ADDRESS_SIGNAL <= INITIAL_ADDRESS;

	-------------------------the ROM process-------------------------------------

--------------------------PAST CODE HAS ISSUES , TRYING TO SOLVE IT----------------------	
--	ROM_OUTPUT <=	TWO_OPP_ROM_DATA(to_integer(unsigned(INSTRUCTION_COUNTER)))	WHEN MODE = TWO_OPERAND
--		ELSE	ONE_OPP_ROM_DATA(TO_INTEGER(UNSIGNED(INSTRUCTION_COUNTER)))	WHEN MODE = ONE_OPERAND
--		ELSE	COMP_ROM_DATA(TO_INTEGER(UNSIGNED(INSTRUCTION_COUNTER)))	WHEN MODE = COMPAIR;
--------------------------------------------------------


	ROM_OUTPUT <=	TWO_OPP_ROM_DATA(to_integer(unsigned(INSTRUCTION_COUNTER)))	WHEN MODE = TWO_OPERAND AND (INSTRUCTION_COUNTER = "000" OR INSTRUCTION_COUNTER = "001" OR INSTRUCTION_COUNTER = "010" OR INSTRUCTION_COUNTER = "011")
		ELSE	TWO_OPP_ROM_DATA(TO_INTEGER(UNSIGNED(INITIAL_ADDRESS_SIGNAL)))	WHEN MODE = TWO_OPERAND AND (INSTRUCTION_COUNTER /= "000" AND INSTRUCTION_COUNTER /= "001" AND INSTRUCTION_COUNTER /= "010" AND INSTRUCTION_COUNTER /= "011")
		ELSE	ONE_OPP_ROM_DATA(TO_INTEGER(UNSIGNED(INSTRUCTION_COUNTER)))	WHEN MODE = ONE_OPERAND AND (INSTRUCTION_COUNTER = "000" OR INSTRUCTION_COUNTER = "001" OR INSTRUCTION_COUNTER = "010" OR INSTRUCTION_COUNTER = "011")
		ELSE	ONE_OPP_ROM_DATA(TO_INTEGER(UNSIGNED(INITIAL_ADDRESS_SIGNAL)))	WHEN MODE = ONE_OPERAND AND (INSTRUCTION_COUNTER /= "000" AND INSTRUCTION_COUNTER /= "001" AND INSTRUCTION_COUNTER /= "010" AND INSTRUCTION_COUNTER /= "011")
		ELSE	COMP_ROM_DATA(TO_INTEGER(UNSIGNED(INSTRUCTION_COUNTER)))	WHEN MODE = COMPAIR AND (INSTRUCTION_COUNTER = "000" OR INSTRUCTION_COUNTER = "001")
		ELSE	COMP_ROM_DATA(TO_INTEGER(UNSIGNED(INITIAL_ADDRESS_SIGNAL)))	WHEN MODE = COMPAIR AND (INSTRUCTION_COUNTER /= "000" AND INSTRUCTION_COUNTER /= "001");



	CONTROL_WORD(14 DOWNTO 11) <= ROM_OUTPUT(14 DOWNTO 11);
	CONTROL_WORD(6 DOWNTO 0) <= ROM_OUTPUT(6 DOWNTO 0);


	-------------------------Place Holder circuits-------------------------------
	--Bout : SRC &&&&  --Aout : DEST
	IR_DEST <= '0'&IR (2 DOWNTO 0);
	IR_SRC <= '0'&IR (8 DOWNTO 6);

	

	CONTROL_WORD(22 DOWNTO 19) <=	STD_LOGIC_VECTOR(UNSIGNED (IR_SRC) + 1) WHEN ROM_OUTPUT(22 DOWNTO 19) = "1111" AND (MODE = TWO_OPERAND OR MODE = COMPAIR)
		ELSE			STD_LOGIC_VECTOR(UNSIGNED (IR_DEST) + 1) WHEN ROM_OUTPUT(22 DOWNTO 19) = "1111" AND  MODE = ONE_OPERAND
		ELSE 			ROM_OUTPUT(22 DOWNTO 19) ;
	
	CONTROL_WORD(18 DOWNTO 15) <= 	STD_LOGIC_VECTOR(UNSIGNED (IR_DEST) + 1) WHEN ROM_OUTPUT(18 DOWNTO 15) = "1111"
		ELSE 			ROM_OUTPUT(18 DOWNTO 15) ;
	
	CONTROL_WORD(10 DOWNTO 7) <= 	STD_LOGIC_VECTOR(UNSIGNED (IR_DEST) + 1) WHEN ROM_OUTPUT(10 DOWNTO 7) = "1111"
		ELSE 			ROM_OUTPUT(10 DOWNTO 7) ;




------OLD CODE AND NOT USEFUL NOW : YOU CAN DELETE IT---------
--	CONTROL_WORD(22 DOWNTO 19) <= STD_LOGIC_VECTOR(UNSIGNED (IR_SRC) + 1) WHEN ROM_OUTPUT(22 DOWNTO 19) = "1111"
--		ELSE ROM_OUTPUT(22 DOWNTO 19) ;
--	
--	CONTROL_WORD(18 DOWNTO 15) <= STD_LOGIC_VECTOR(UNSIGNED (IR_DEST) + 1) WHEN ROM_OUTPUT(18 DOWNTO 15) = "1111" AND (MODE = TWO_OPERAND OR MODE = COMPAIR)
--	--	ELSE "0000" WHEN MODE = ONE_OPERAND
--		ELSE ROM_OUTPUT(18 DOWNTO 15) ;
--	
--	CONTROL_WORD(10 DOWNTO 7) <= STD_LOGIC_VECTOR(UNSIGNED (IR_DEST) + 1) WHEN ROM_OUTPUT(10 DOWNTO 7) = "1111"  AND (MODE = TWO_OPERAND OR MODE = COMPAIR)
--		ELSE  WHEN MODE = ONE_OPERAND
--		ELSE ROM_OUTPUT(10 DOWNTO 7) ;
-------------------------------------------------------------


	-----------------OPERATION DETECTOR FOR TWO OPERAND AND ONE OPERANDOPERATIONS----------------------------------------
	CONTROL_WORD(27 DOWNTO 23) <=	ADD_OP WHEN MODE = TWO_OPERAND AND IR(15 DOWNTO 12) = ADD
				ELSE	ADC_OP WHEN MODE = TWO_OPERAND AND IR(15 DOWNTO 12) = ADC
				ELSE	SUB_OP WHEN MODE = TWO_OPERAND AND IR(15 DOWNTO 12) = SUBB
				ELSE	SBC_OP WHEN MODE = TWO_OPERAND AND IR(15 DOWNTO 12) = SBC
				ELSE	MOV_OP WHEN MODE = TWO_OPERAND AND IR(15 DOWNTO 12) = MOV
				ELSE	BIC_OP WHEN MODE = TWO_OPERAND AND IR(15 DOWNTO 12) = BIC
				ELSE	BIS_OP WHEN MODE = TWO_OPERAND AND IR(15 DOWNTO 12) = BIS
				ELSE	AND_OP WHEN MODE = TWO_OPERAND AND IR(15 DOWNTO 12) = ANDD
				ELSE	OR_OP WHEN MODE = TWO_OPERAND AND IR(15 DOWNTO 12) = ORR
				ELSE	XOR_OP WHEN MODE = TWO_OPERAND AND IR(15 DOWNTO 12) = XORR
				ELSE	SUB_OP WHEN MODE = COMPAIR AND IR(15 DOWNTO 12) = COMP
				ELSE	INV_OP WHEN MODE = ONE_OPERAND AND IR(15 DOWNTO 6) = INV
				ELSE	INC1_OP WHEN MODE = ONE_OPERAND AND IR(15 DOWNTO 6) = INC
				ELSE	DEC1_OP WHEN MODE = ONE_OPERAND AND IR(15 DOWNTO 6) = DEC
				ELSE	CLR_OP WHEN MODE = ONE_OPERAND AND IR(15 DOWNTO 6) = CLR
				ELSE	LSR_OP WHEN MODE = ONE_OPERAND AND IR(15 DOWNTO 6) = LSR
				ELSE	ROR_OP WHEN MODE = ONE_OPERAND AND IR(15 DOWNTO 6) = RORR
				ELSE	RRC_OP WHEN MODE = ONE_OPERAND AND IR(15 DOWNTO 6) = RRC
				ELSE	ASR_OP WHEN MODE = ONE_OPERAND AND IR(15 DOWNTO 6) = ASR
				ELSE	LSL_OP WHEN MODE = ONE_OPERAND AND IR(15 DOWNTO 6) = LSL
				ELSE	ROL_OP WHEN MODE = ONE_OPERAND AND IR(15 DOWNTO 6) = ROLL
				ELSE	RLC_OP WHEN MODE = ONE_OPERAND AND IR(15 DOWNTO 6) = RLC;
			--	ELSE	NO_OP WHEN IR(15 DOWNTO 12) = NO


	
END EXECUTE;
