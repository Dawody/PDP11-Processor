LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.MY_PACKAGE.ALL;

--The control word format is 
-- The size is ROM WIDTH = 28 signals
	-- 27 CW 23 => ALU operation
	-- 22 CW 19 => B bus outputs, see table 1 in MY_PACKAGE
	-- 18 CW 15 => A bus outputs, see table 1 in MY_PACKAGE
	-- 14 CW 11 => B bus inputs, see table 1 in MY_PACKAGE
	-- 10 CW 5 => Z bus inputs 		
		-- 10 CW 7 => R0 to R7 and more, see table 1 in MY_PACKAGE
		-- 6 CW 5 => transperent registers, see table 2 in MY_PACKAGE
	--CW 5 => WMFC
	--CW 4 => READ
	--CW 3 => WRITE
	--CW 2 => 16/32 Memory Reading mode
	--CW 1 => (RESET) ALL REGESTERS
	--CW 0 => RESET THE IR REGISTER ONLY TO VALUE (0000000000000001)
	
ENTITY PU IS
	GENERIC (REGISTER_SIZE : INTEGER := 32);
	PORT (
		A_BUS,B_BUS,Z_BUS	:INOUT STD_LOGIC_VECTOR(REGISTER_SIZE-1 DOWNTO 0)
		--CONTROL_WORD		:IN STD_LOGIC_VECTOR (ROM_WIDTH -1 DOWNTO 0):="0000000000000000000000000011"
		--MICRO_PROGRAM		:OUT STD_LOGIC_VECTOR(30 DOWNTO 0)
	);
END ENTITY PU;

ARCHITECTURE PROCESSING_UNIT OF PU IS



-----------------------------COMPONENTS AREA------------------------------------------------

COMPONENT CU IS
	PORT( --CONTROL_CLK :IN std_logic;
		IR 		: IN STD_LOGIC_VECTOR (IR_SIZE-1 DOWNTO 0);
		FLAG_REGISTER 	: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		PU_CONTROL_WORD : OUT STD_LOGIC_VECTOR (ROM_WIDTH-1 DOWNTO 0):="0000000000000000000000000011";
		CONTROL_CLK 	: IN STD_LOGIC );
END COMPONENT;


COMPONENT ALU IS
	PORT(
   		A,B 		: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
   		OPCODE 		: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
   		FLAG_REGISTER 	: INOUT STD_LOGIC_VECTOR (3 DOWNTO 0);		--FLAG REGISTER(3 DOWNTO 0)->(_ _ C Z)
   		OUTPUT 		: OUT STD_LOGIC_VECTOR(31 downto 0)
	);
END COMPONENT;

COMPONENT REGISTER_ADDRESS_DECODER IS
	PORT (
		REG_CODE	: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		DECODER_OUT	: OUT STD_LOGIC_VECTOR (REGISTER_STATES_ON_BUS-1 DOWNTO 0)
	);
END COMPONENT;

COMPONENT REGISTER_ADDRESS_DECODER2 IS
	PORT (
		REG_CODE	: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
		DECODER_OUT	: OUT STD_LOGIC_VECTOR (REGISTER_STATES_ON_BUS-1 DOWNTO 0)
	);
END COMPONENT;

COMPONENT GENERAL_REGISTER IS
	GENERIC (REG_SIZE : INTEGER := 32);
	PORT (
		D,DX		: IN STD_LOGIC_VECTOR (REG_SIZE-1 DOWNTO 0);	--LOOK AT GENERAL_REGISTER BLOCK !
		CLK,RST,ENB,ENBX: IN STD_LOGIC;
		Q,QX 		: OUT STD_LOGIC_VECTOR (REG_SIZE-1 DOWNTO 0)
	);
END COMPONENT;

COMPONENT IR_REGISTER IS
	GENERIC (SIZE : INTEGER := 16);
	PORT (
		D		: IN STD_LOGIC_VECTOR (SIZE-1 DOWNTO 0);	--DX : IF ENB=1 INPUT=D , IF ENBX=1 INPUT=DX
		CLK,RST,ENB	: IN STD_LOGIC;
		Q 		: OUT STD_LOGIC_VECTOR (SIZE-1 DOWNTO 0)	--QX IS THE SAME AS 'Q' NO THING ELSE
	);
END COMPONENT;

COMPONENT MAR IS
	GENERIC (REG_SIZE : INTEGER := 32);
	PORT (
		D,DX		: IN STD_LOGIC_VECTOR (REG_SIZE-1 DOWNTO 0);	--DX : IF ENB=1 INPUT=D , IF ENBX=1 INPUT=DX
		CLK,RST,ENB,ENBX: IN STD_LOGIC;
		Q,QX 		: OUT STD_LOGIC_VECTOR (REG_SIZE-1 DOWNTO 0)	--QX IS THE SAME AS 'Q' NO THING ELSE
	);

END COMPONENT;

COMPONENT MDR IS
	GENERIC (MDR_SIZE : INTEGER := 32);
	PORT (
		D,DX,RAM_OUT	: IN STD_LOGIC_VECTOR (MDR_SIZE-1 DOWNTO 0);	--DX : IF ENB=1 INPUT=D , IF ENBX=1 INPUT=DX
		CLK,RST		: IN STD_LOGIC;
		ENB,ENBX,RD,TYP	: IN STD_LOGIC;
		Q,QX,RAM_IN 	: OUT STD_LOGIC_VECTOR (MDR_SIZE-1 DOWNTO 0)	--QX IS THE SAME AS 'Q' NO THING ELSE
	);
END COMPONENT;

COMPONENT RAM IS
	GENERIC (ADDRESS_SIZE : INTEGER :=11; CELL_SIZE : INTEGER := 16*2);
	PORT (
		DATA_IN 	:IN STD_LOGIC_VECTOR(CELL_SIZE-1 DOWNTO 0);
		WRT,RD	 	: IN STD_LOGIC;		
		CLK,ENB		:IN STD_LOGIC;	
		ADDRESS		:IN STD_LOGIC_VECTOR(ADDRESS_SIZE-1 DOWNTO 0);
		DATA_OUT 	: OUT STD_LOGIC_VECTOR(CELL_SIZE-1 DOWNTO 0);
		MFC, MDR_READ 	:OUT STD_LOGIC

	);
END COMPONENT;


-----------------------------------------SIGNALS AREA------------------------------------------------------------------

SIGNAL	CONTROL_WORD		:STD_LOGIC_VECTOR (ROM_WIDTH -1 DOWNTO 0):="0000000000000000000000000011";
SIGNAL	FLAGS			:STD_LOGIC_VECTOR(3 DOWNTO 0) :="0000";
SIGNAL	ALU_OPERATION		:STD_LOGIC_VECTOR(7 DOWNTO 0) :="00000000";
SIGNAL	CONTROL_CLK, PROCESSING_CLK : STD_LOGIC := '1';


-- THOSE SIGNALS FOR CARRY THE ENABLE OF EACH TRI STATE BUFFER THAT CONTROL THE REGISTERS
SIGNAL	B_OUT_STATES		:STD_LOGIC_VECTOR(REGISTER_STATES_ON_BUS-1 DOWNTO 0);
SIGNAL	A_OUT_STATES		:STD_LOGIC_VECTOR(REGISTER_STATES_ON_BUS-1 DOWNTO 0);
SIGNAL	B_IN_STATES		:STD_LOGIC_VECTOR(REGISTER_STATES_ON_BUS-1 DOWNTO 0);
SIGNAL	Z_IN_STATES_P1		:STD_LOGIC_VECTOR(REGISTER_STATES_ON_BUS-1 DOWNTO 0); -- P1 : PART1
SIGNAL	Z_IN_STATES_P2		:STD_LOGIC_VECTOR(REGISTER_STATES_ON_BUS-1 DOWNTO 0); -- P2 : PART2
SIGNAL	Z_IN_STATES		:STD_LOGIC_VECTOR(REGISTER_STATES_ON_BUS-1 DOWNTO 0);

-- THOSE SIGNALS COME FROM THE CONTROL_WORD
SIGNAL	RD,WT,TYP,BACK,RST_INS	:STD_LOGIC;	--READ , WRITE , TYPE(16 OR 32) , GO_BACK , FINISH_INSTRUCTION.
SIGNAL	RESET_ALL	:STD_LOGIC :='1';
SIGNAL	NEW_INSTRUCTION	:STD_LOGIC :='1';
-- THOSE SIGNALS (Z_IN) CARRY THE SIGNALS 
SIGNAL	R_0_Z_IN,R_0_A_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_1_Z_IN,R_1_A_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_2_Z_IN,R_2_A_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_3_Z_IN,R_3_A_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_4_Z_IN,R_4_A_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_5_Z_IN,R_5_A_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_6_Z_IN,R_6_A_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_7_Z_IN,R_7_A_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	SRC_Z_IN,SRC_A_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	MDR_Z_IN,MDR_A_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	MAR_Z_IN		:STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL	R_0_B_IN,R_0_B_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_1_B_IN,R_1_B_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_2_B_IN,R_2_B_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_3_B_IN,R_3_B_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_4_B_IN,R_4_B_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_5_B_IN,R_5_B_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_6_B_IN,R_6_B_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	R_7_B_IN,R_7_B_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	SRC_B_IN,SRC_B_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	MDR_B_IN,MDR_B_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	IR_B_IN,IR_B_OUT	:STD_LOGIC_VECTOR(31 DOWNTO 0);		--ISSUES IN SIZE OF THIS REGISTER!
SIGNAL	MAR_B_IN		:STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL MAR_OUT_ADDRESS		:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL RAM_ADDRESS		:STD_LOGIC_VECTOR(RAM_SIZE-1 DOWNTO 0);
SIGNAL MDR_TO_RAM,RAM_TO_MDR	:STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL INSTRUCTION		:STD_LOGIC_VECTOR(IR_SIZE-1 DOWNTO 0);
SIGNAL MFC_SIGNAL,MDR_READ_SIGNAL:STD_LOGIC;
SIGNAL IR_RESET			:STD_LOGIC;


BEGIN


	CONTROL_UNIT	: CU  PORT MAP (IR => INSTRUCTION , FLAG_REGISTER => FLAGS , PU_CONTROL_WORD => CONTROL_WORD , CONTROL_CLK => CONTROL_CLK);

	ALU0 		: ALU PORT MAP (A => B_BUS , B => A_BUS , OPCODE => ALU_OPERATION , FLAG_REGISTER => FLAGS, OUTPUT => Z_BUS );	-- SEND B_BUS TO (A) OPERAND & SEND A_BUS TO (B) OPERAND : BECAUSE ALU WORKS ON (A) OPERAND IN CASE OF ONE OPERAND OPERATIONS

	B_OUT		: REGISTER_ADDRESS_DECODER 	PORT MAP (REG_CODE => CONTROL_WORD(22 DOWNTO 19) , DECODER_OUT => B_OUT_STATES);
	A_OUT		: REGISTER_ADDRESS_DECODER 	PORT MAP (REG_CODE => CONTROL_WORD(18 DOWNTO 15) , DECODER_OUT => A_OUT_STATES);
	B_IN		: REGISTER_ADDRESS_DECODER 	PORT MAP (REG_CODE => CONTROL_WORD(14 DOWNTO 11) , DECODER_OUT => B_IN_STATES);
	Z_IN		: REGISTER_ADDRESS_DECODER 	PORT MAP (REG_CODE => CONTROL_WORD(10 DOWNTO 7) , DECODER_OUT => Z_IN_STATES_P1);
	Z_IN2		: REGISTER_ADDRESS_DECODER2	PORT MAP (REG_CODE => CONTROL_WORD(6 DOWNTO 5)  , DECODER_OUT => Z_IN_STATES_P2);

	R0		: GENERAL_REGISTER		PORT MAP (D => R_0_Z_IN , DX => R_0_B_IN ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(0) , ENBX => B_IN_STATES(0) , Q => R_0_A_OUT , QX => R_0_B_OUT);
	R1		: GENERAL_REGISTER		PORT MAP (D => R_1_Z_IN , DX => R_1_B_IN ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(1) , ENBX => B_IN_STATES(1) , Q => R_1_A_OUT , QX => R_1_B_OUT);
	R2		: GENERAL_REGISTER		PORT MAP (D => R_2_Z_IN , DX => R_2_B_IN ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(2) , ENBX => B_IN_STATES(2) , Q => R_2_A_OUT , QX => R_2_B_OUT);
	R3		: GENERAL_REGISTER		PORT MAP (D => R_3_Z_IN , DX => R_3_B_IN ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(3) , ENBX => B_IN_STATES(3) , Q => R_3_A_OUT , QX => R_3_B_OUT);
	R4		: GENERAL_REGISTER		PORT MAP (D => R_4_Z_IN , DX => R_4_B_IN ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(4) , ENBX => B_IN_STATES(4) , Q => R_4_A_OUT , QX => R_4_B_OUT);
	R5		: GENERAL_REGISTER		PORT MAP (D => R_5_Z_IN , DX => R_5_B_IN ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(5) , ENBX => B_IN_STATES(5) , Q => R_5_A_OUT , QX => R_5_B_OUT);
	R6		: GENERAL_REGISTER		PORT MAP (D => R_6_Z_IN , DX => R_6_B_IN ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(6) , ENBX => B_IN_STATES(6) , Q => R_6_A_OUT , QX => R_6_B_OUT);
	R7		: GENERAL_REGISTER		PORT MAP (D => R_7_Z_IN , DX => R_7_B_IN ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(7) , ENBX => B_IN_STATES(7) , Q => R_7_A_OUT , QX => R_7_B_OUT);
	SRC		: GENERAL_REGISTER		PORT MAP (D => SRC_Z_IN , DX => SRC_B_IN ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(11) , ENBX => B_IN_STATES(11), Q => SRC_A_OUT , QX => SRC_B_OUT);
--	MAR_LAB		: GENERAL_REGISTER		PORT MAP (D => MAR_Z_IN , DX => MAR_B_IN ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(8) , ENBX => B_IN_STATES(8) , Q => MAR_OUT_ADDRESS , QX => MAR_OUT_ADDRESS);
-- TRY TO FIX MDR_READ PROBLEM
	MAR_LAB		: MAR				PORT MAP (D => MAR_Z_IN , DX => MAR_B_IN ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(8) , ENBX => B_IN_STATES(8) , Q => MAR_OUT_ADDRESS , QX => MAR_OUT_ADDRESS);
	MDR_LAB		: MDR				PORT MAP (D => MDR_Z_IN , DX => MDR_B_IN , RAM_OUT => RAM_TO_MDR ,CLK => PROCESSING_CLK , RST => RESET_ALL ,ENB => Z_IN_STATES(9) , ENBX => B_IN_STATES(9) , RD => RD , TYP => TYP , Q => MDR_A_OUT , QX => MDR_B_OUT , RAM_IN => MDR_TO_RAM);
	RAM_LAB		: RAM				PORT MAP (DATA_IN => MDR_TO_RAM , WRT => WT , RD => RD , CLK => PROCESSING_CLK , ENB => '1' , ADDRESS =>RAM_ADDRESS , DATA_OUT => RAM_TO_MDR  , MFC =>MFC_SIGNAL , MDR_READ => MDR_READ_SIGNAL); -- i changed MDR_READ_SIGNAL to RD
	IR_REGISTER_LAB	: IR_REGISTER			PORT MAP (D => IR_B_IN  , CLK => PROCESSING_CLK , RST => IR_RESET , ENB => B_IN_STATES(10), Q => IR_B_OUT);
	
	

-------------------------ANY THING HERE MUST BE DELETED--------------------------
--
--
--
--
--
--
---------------------------------------------------------------------------------



----------------TRI STATES AREA---------------------------------------------------------------------------------------------
-- THE DATA BUSES NEED TRISTATE BUFFERS TO CONTROL THE SIGNAL THAT WILL WRITE ON IT COMMING FROM THE REGISTER
-- REMEMBER THAT REGISTER INPUTS FROM DAT ABUSES ARE CONTROLED USING THE REGISTER ENABLE COMMING FROM THE REGISTER ADDRESS DECODER .

 
	A_BUS <= R_0_A_OUT	WHEN A_OUT_STATES(0)='1'	ELSE (OTHERS=>'Z');
	A_BUS <= R_1_A_OUT	WHEN A_OUT_STATES(1)='1'	ELSE (OTHERS=>'Z');
	A_BUS <= R_2_A_OUT	WHEN A_OUT_STATES(2)='1'	ELSE (OTHERS=>'Z');
	A_BUS <= R_3_A_OUT	WHEN A_OUT_STATES(3)='1'	ELSE (OTHERS=>'Z');
	A_BUS <= R_4_A_OUT	WHEN A_OUT_STATES(4)='1'	ELSE (OTHERS=>'Z');
	A_BUS <= R_5_A_OUT	WHEN A_OUT_STATES(5)='1'	ELSE (OTHERS=>'Z');
	A_BUS <= R_6_A_OUT	WHEN A_OUT_STATES(6)='1'	ELSE (OTHERS=>'Z');
	A_BUS <= R_7_A_OUT	WHEN A_OUT_STATES(7)='1'	ELSE (OTHERS=>'Z');
	A_BUS <= MDR_A_OUT	WHEN A_OUT_STATES(9)='1'	ELSE (OTHERS=>'Z');
	A_BUS <= SRC_A_OUT	WHEN A_OUT_STATES(11)='1'	ELSE (OTHERS=>'Z');
	
	B_BUS <= R_0_B_OUT	WHEN B_OUT_STATES(0)='1'	ELSE (OTHERS=>'Z');
	B_BUS <= R_1_B_OUT	WHEN B_OUT_STATES(1)='1'	ELSE (OTHERS=>'Z');
	B_BUS <= R_2_B_OUT	WHEN B_OUT_STATES(2)='1'	ELSE (OTHERS=>'Z');
	B_BUS <= R_3_B_OUT	WHEN B_OUT_STATES(3)='1'	ELSE (OTHERS=>'Z');
	B_BUS <= R_4_B_OUT	WHEN B_OUT_STATES(4)='1'	ELSE (OTHERS=>'Z');
	B_BUS <= R_5_B_OUT	WHEN B_OUT_STATES(5)='1'	ELSE (OTHERS=>'Z');
	B_BUS <= R_6_B_OUT	WHEN B_OUT_STATES(6)='1'	ELSE (OTHERS=>'Z');
	B_BUS <= R_7_B_OUT	WHEN B_OUT_STATES(7)='1'	ELSE (OTHERS=>'Z');
	B_BUS <= MDR_B_OUT	WHEN B_OUT_STATES(9)='1'	ELSE (OTHERS=>'Z');
	B_BUS <= IR_B_OUT	WHEN B_OUT_STATES(10)='1'	ELSE (OTHERS=>'Z');
	B_BUS <= SRC_B_OUT	WHEN B_OUT_STATES(11)='1'	ELSE (OTHERS=>'Z');
	



---------FROM DATABUS TO SIGNALS-----------------------------------------------------------------------------------------------------



	R_0_Z_IN <= Z_BUS;
	R_1_Z_IN <= Z_BUS;
	R_2_Z_IN <= Z_BUS;
	R_3_Z_IN <= Z_BUS;
	R_4_Z_IN <= Z_BUS;
	R_5_Z_IN <= Z_BUS;
	R_6_Z_IN <= Z_BUS;
	R_7_Z_IN <= Z_BUS;
	SRC_Z_IN <= Z_BUS;
	MDR_Z_IN <= Z_BUS;
	MAR_Z_IN <= Z_BUS;

	R_0_B_IN <= B_BUS;
	R_1_B_IN <= B_BUS;
	R_2_B_IN <= B_BUS;
	R_3_B_IN <= B_BUS;
	R_4_B_IN <= B_BUS;
	R_5_B_IN <= B_BUS;
	R_6_B_IN <= B_BUS;
	R_7_B_IN <= B_BUS;
	SRC_B_IN <= B_BUS;
	MDR_B_IN <= B_BUS;
	MAR_B_IN <= B_BUS;
	IR_B_IN <= B_BUS;






---------------------------------------------------------------------------------------------------------------


	RAM_ADDRESS	<= MAR_OUT_ADDRESS(RAM_SIZE-1 DOWNTO 0);
	INSTRUCTION	<= IR_B_OUT(IR_SIZE-1 DOWNTO 0);	--THE IR IT SELF
	NEW_INSTRUCTION	<= CONTROL_WORD(0);			--SIGNAL TO SAY THAT RESET THE IR TO FETCH NEW ONE
	RESET_ALL	<= CONTROL_WORD(1);			--RESET ALL REGISTER INCLUDING THE IR .
	Z_IN_STATES	<= Z_IN_STATES_P1 OR Z_IN_STATES_P2;	--I COLLECT THE Z-IN-STATES FROM THE OUTPUT OF 4BIT DECODER AND 2BUT DECODER .. MORE DETAILS IN PAPERS 
	ALU_OPERATION	<= "000"&CONTROL_WORD(27 DOWNTO 23);
	IR_RESET	<= RESET_ALL or NEW_INSTRUCTION;
	RD		<= CONTROL_WORD(4);
	WT		<= CONTROL_WORD(3);
	TYP		<= CONTROL_WORD(2);



































	----------------------------------------------------------------------------------------
	----------------------------------CLK Generation----------------------------------------
	PROCESS 
	BEGIN 
		CONTROL_CLK <= '1';
		WAIT FOR HALF_CYCLE / 2;
		PROCESSING_CLK <= '1';
		WAIT FOR HALF_CYCLE / 2;
		CONTROL_CLK <= '0';
		WAIT FOR HALF_CYCLE / 2;
		PROCESSING_CLK <= '0';
		WAIT FOR HALF_CYCLE / 2;
	END PROCESS;
	
	----------------------------------------------------------------------------------------
	
	
END PROCESSING_UNIT;
