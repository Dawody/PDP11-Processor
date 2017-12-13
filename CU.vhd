LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.MY_PACKAGE.ALL;

ENTITY CU IS
	PORT( --CONTROL_CLK :IN std_logic;
		IR 		: IN STD_LOGIC_VECTOR (IR_SIZE-1 DOWNTO 0);
		FLAG_REGISTER 	: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		PU_CONTROL_WORD : OUT STD_LOGIC_VECTOR (ROM_WIDTH-1 DOWNTO 0);
		PROCESSING_CLK 	: OUT STD_LOGIC );
END ENTITY CU;

ARCHITECTURE CONTROL_UNIT OF CU IS
	COMPONENT NBIT_COUNTER_WITH_INCREMENT IS
	GENERIC (N: integer := 4 );
	PORT(
		CLK, RST, ENABLE	: IN std_logic;
		INCREMENT 		: IN std_logic_vector (1 DOWNTO 0);
		DATA_OUT 		: OUT std_logic_vector(N-1 DOWNTO 0));
	END COMPONENT NBIT_COUNTER_WITH_INCREMENT;
	
	COMPONENT NBIT_COUNTER_WITH_INITIAL_VALUE IS
	GENERIC (N: integer := 4 );
	PORT(
		CLK, ENABLE 	: IN std_logic;
		DATA_IN 	: IN std_logic_vector(N-1 DOWNTO 0);
		DATA_OUT 	: OUT std_logic_vector(N-1 DOWNTO 0));
	END COMPONENT NBIT_COUNTER_WITH_INITIAL_VALUE;
	
	COMPONENT FETCH_INSTRUCTION_BLOCK IS
	PORT(
		INSTRUCTION_COUNTER	: IN STD_LOGIC_VECTOR	(INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0);
		INITIAL_ADDRESS 	: OUT STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0); 
		CONTROL_WORD		: OUT STD_LOGIC_VECTOR	(ROM_WIDTH-1 DOWNTO 0) );
	END COMPONENT FETCH_INSTRUCTION_BLOCK;
	
	COMPONENT SRC_FETCHING_BLOCK IS
	PORT (
		IR 			: IN std_logic_vector (IR_SIZE-1 DOWNTO 0);
		INSTRUCTION_COUNTER 	: IN STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0); 
		CONTROL_WORD		: OUT STD_LOGIC_VECTOR (ROM_WIDTH-1 DOWNTO 0);
		INITIAL_ADDRESS		: OUT STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0) );
	END COMPONENT SRC_FETCHING_BLOCK;
	
	COMPONENT DEST_FETCHING_BLOCK IS
	PORT (
		IR 			: IN std_logic_vector (IR_SIZE-1 DOWNTO 0);
		INSTRUCTION_COUNTER 	: IN STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0); 
		CONTROL_WORD		: OUT STD_LOGIC_VECTOR (ROM_WIDTH-1 DOWNTO 0);
		INITIAL_ADDRESS		: OUT STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0) );
	END COMPONENT DEST_FETCHING_BLOCK;
	
	COMPONENT BRANCH_BLOCK IS
	PORT (
		IR 			: IN STD_LOGIC_VECTOR (IR_SIZE-1 DOWNTO 0);
		FLAG_REGISTER 		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);		--FLAG REGISTER(3 DOWNTO 0)->(_ _ C Z)
		INITIAL_ADDRESS		: OUT STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0);
		CONTROL_WORD		: OUT STD_LOGIC_VECTOR (ROM_WIDTH-1 DOWNTO 0) );
	END COMPONENT BRANCH_BLOCK;

	COMPONENT EXECUTE_BLOCK IS
	PORT (
		IR 			: IN std_logic_vector (IR_SIZE-1 DOWNTO 0);
		INSTRUCTION_COUNTER 	: IN STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0); 
		CONTROL_WORD		: OUT STD_LOGIC_VECTOR (ROM_WIDTH-1 DOWNTO 0);
		INITIAL_ADDRESS		: OUT STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0) );
	END COMPONENT EXECUTE_BLOCK;

	--CLK SIGNAL
	SIGNAL CONTROL_CLK : std_logic;
	--TODO set NEW_INSTRUCTION bit at the end of every instruction and clear it at the start of every instruction TO RESET THE CIRCUIT
	------------------------COUNTERS SIGNALS-------------------
	--RESET THE MAIN COUNTER
	SIGNAL NEW_INSTRUCTION 			: std_logic := '0'; 
	SIGNAL ENABLE_MAIN_COUNTER 		: std_logic := '1';
	SIGNAL ENABLE_INSTRUCTION_COUNTER 	: std_logic := '0';
	SIGNAL MAIN_COUNTER_OUTPUT		: std_logic_vector (MAIN_COUNTER_OUTPUT_SIZE-1 DOWNTO 0); 
	SIGNAL INSTRUCTION_COUNTER_OUTPUT	: std_logic_vector (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0);
	SIGNAL MAIN_COUNTER_INCREMENT 		: std_logic_vector (1 DOWNTO 0);
	SIGNAL INITIAL_ADDRESS 			: std_logic_vector(INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0) := "000";
	
	--OPERATION MODE SIGNAL
	SIGNAL MODE : std_logic_vector(MODE_BITS_NUM-1 DOWNTO 0);
	---------------------ROMS Block Signals------------------
	--ROMs Blocks INSTRUCTON ADDRESS Input
	SIGNAL INSTRUCTION_FETCHING_BLOCK_INSTRUCTION_ADDRESS, SRC_FETCHING_BLOCK_INSTRUCTION_ADDRESS
		, DEST_FETCHING_BLOCK_INSTRUCTION_ADDRESS, EXECUTE_BLOCK_INSTRUCTION_ADDRESS
		, EXECUTE_BRANCH_BLOCK_INSTRUCTION_ADDRESS : STD_LOGIC_VECTOR(INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0);
	--ROMs Blocks CODE WORD Output
	SIGNAL ROM_BLOCKS_OUTPUT, INSTRUCTION_FETCHING_BLOCK_OUTPUT
		, SRC_FETCHING_BLOCK_OUTPUT
		, DEST_FETCHING_BLOCK_OUTPUT, EXECUTE_BLOCK_OUTPUT
		, EXECUTE_BRANCH_BLOCK_OUTPUT : STD_LOGIC_VECTOR (ROM_WIDTH-1 DOWNTO 0) := (OTHERS =>'0');
	--ROMs Blocks INITIAL ADDRESS Output
	SIGNAL INSTRUCTION_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT
		, SRC_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT, DEST_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT
		, EXECUTE_BLOCK_INITIAL_ADDRESS_OUTPUT
		, EXECUTE_BRANCH_BLOCK_INITIAL_ADDRESS_OUTPUT : STD_LOGIC_VECTOR (INSTRUCTION_COUNTER_OUTPUT_SIZE-1 DOWNTO 0);
	BEGIN
	-------------------------------Port Mapping-----------------------------------------------
	------------------------------------------------------------------------------------------
	--Counters
	-- MAIN_COUNTER_OUTPUT 	= 0 FETCH INSTRUCTION
	--					   	= 1 FETCH SRC
	--					   	= 2 FETCH DEST
	--						= 3 EXECUTE ( 1, 2 OR ZERO OPRAND INSTRUCTIONS)
	--						= 4 EXECUTE BRANCH INSTRUCTION 
	MAIN_COUNTER: NBIT_COUNTER_WITH_INCREMENT 
		GENERIC MAP (N => MAIN_COUNTER_OUTPUT_SIZE) 
		PORT MAP ( CLK => CONTROL_CLK , RST => NEW_INSTRUCTION, ENABLE => ENABLE_MAIN_COUNTER
			, INCREMENT => MAIN_COUNTER_INCREMENT, DATA_OUT => MAIN_COUNTER_OUTPUT  );
	INSTRUCTION_COUNTER: NBIT_COUNTER_WITH_INITIAL_VALUE 
		GENERIC MAP (N => INSTRUCTION_COUNTER_OUTPUT_SIZE) 
		PORT MAP ( CLK => CONTROL_CLK , ENABLE => ENABLE_INSTRUCTION_COUNTER
			, DATA_IN => INITIAL_ADDRESS, DATA_OUT => INSTRUCTION_COUNTER_OUTPUT );
	

	--ROMs Blocks
	INSTRUCTION_FETCH : FETCH_INSTRUCTION_BLOCK PORT MAP (INSTRUCTION_COUNTER => INSTRUCTION_FETCHING_BLOCK_INSTRUCTION_ADDRESS
		, CONTROL_WORD => INSTRUCTION_FETCHING_BLOCK_OUTPUT, INITIAL_ADDRESS => INSTRUCTION_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT);
	
	SRC_FETCH: SRC_FETCHING_BLOCK PORT MAP (IR => IR, INSTRUCTION_COUNTER => SRC_FETCHING_BLOCK_INSTRUCTION_ADDRESS
		, CONTROL_WORD => SRC_FETCHING_BLOCK_OUTPUT, INITIAL_ADDRESS => SRC_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT);
		
	DEST_FETCH: DEST_FETCHING_BLOCK PORT MAP (IR => IR, INSTRUCTION_COUNTER => DEST_FETCHING_BLOCK_INSTRUCTION_ADDRESS
		, CONTROL_WORD => DEST_FETCHING_BLOCK_OUTPUT, INITIAL_ADDRESS => DEST_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT);
		
	BRANCHING: BRANCH_BLOCK PORT MAP (IR => IR, FLAG_REGISTER => FLAG_REGISTER
		, CONTROL_WORD => EXECUTE_BRANCH_BLOCK_OUTPUT, INITIAL_ADDRESS => EXECUTE_BRANCH_BLOCK_INITIAL_ADDRESS_OUTPUT );

	EXECUTEING: EXECUTE_BLOCK PORT MAP (IR=>IR , INSTRUCTION_COUNTER => EXECUTE_BLOCK_INSTRUCTION_ADDRESS
			, CONTROL_WORD =>  EXECUTE_BLOCK_OUTPUT, INITIAL_ADDRESS => EXECUTE_BLOCK_INITIAL_ADDRESS_OUTPUT);
		
	-------------------------------Connection of Instruction Address Signals------------------
	------------------------------------------------------------------------------------------
	INSTRUCTION_FETCHING_BLOCK_INSTRUCTION_ADDRESS <= 
		INSTRUCTION_COUNTER_OUTPUT WHEN MAIN_COUNTER_OUTPUT = "000" 
		ELSE (OTHERS => '0');
		
	SRC_FETCHING_BLOCK_INSTRUCTION_ADDRESS <= 
		INSTRUCTION_COUNTER_OUTPUT WHEN MAIN_COUNTER_OUTPUT = "001" 
		ELSE (OTHERS => '0');
		
	DEST_FETCHING_BLOCK_INSTRUCTION_ADDRESS <= 
		INSTRUCTION_COUNTER_OUTPUT WHEN MAIN_COUNTER_OUTPUT = "010" 
		ELSE (OTHERS => '0');
		
	EXECUTE_BLOCK_INSTRUCTION_ADDRESS <= 
		INSTRUCTION_COUNTER_OUTPUT WHEN MAIN_COUNTER_OUTPUT = "011" 
		ELSE (OTHERS => '0');
		
	EXECUTE_BRANCH_BLOCK_INSTRUCTION_ADDRESS <= 
		INSTRUCTION_COUNTER_OUTPUT WHEN MAIN_COUNTER_OUTPUT = "100" 
		ELSE (OTHERS => '0');
		
	-------------------------------Creating the control clk-----------------------------------
	------------------------------------------------------------------------------------------
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
	
	------------------------------------------------------------------------------------------	
	----------------------------------Logic---------------------------------------------------
	------------------------------------------------------------------------------------------
	
	------------------------------------------------------------------------------------------
	-------------------------------Decode the IR for the MODE----------------------------
	-- Mode = 0 the IR wasn't fetched yet
	--		= 1 2 operands
	--		= 2 1 operands
	--		= 3 zero operand
	--		= 4 branch
	MODE <= TWO_OPERAND 	WHEN NOT (IR(IR_SIZE-1 DOWNTO 12) = X"0" OR IR(IR_SIZE-1 DOWNTO 12) = X"7" 
				OR IR(IR_SIZE-1 DOWNTO 12) = X"8" OR IR(IR_SIZE-1 DOWNTO 12) = X"F" )
	ELSE 	ONE_OPERAND 	WHEN IR(IR_SIZE-1 DOWNTO 12) = X"0" AND NOT (IR(11 DOWNTO 8) = X"0")
	ELSE 	ZERO_OPERAND 	WHEN IR(IR_SIZE-1 DOWNTO 8) = X"0" AND NOT (IR(7 DOWNTO 0) = X"01")
	ELSE 	BRANCH 		WHEN IR(IR_SIZE-1 DOWNTO 12) = X"8"
	ELSE 	NO_INSTRUCTION 	WHEN IR = X"0001";
		
	-------------------------------------------------------------------------------------------	
	----------------------------------Counters Enable Circuit----------------------------------
	--TODO FIND OUT WHEN THE COUNTER WILL BE RESET AND THE ENABLE IS SET
	-- The MAIN COUNTER enable is set if the control word has go back bit is set at the negative edge
	PROCESS (CONTROL_CLK, MAIN_COUNTER_OUTPUT)
	BEGIN
		-- The MAIN COUNTER enable is cleared after every count to allow the INSTRUCTION COUNTER to count
		IF (MAIN_COUNTER_OUTPUT'EVENT)THEN 
			ENABLE_MAIN_COUNTER <= '0';
			ENABLE_INSTRUCTION_COUNTER <= '1';
		--ROM_BLOCKS_OUTPUT(0) IS THE END SIGNAL
		ELSIF ( RISING_EDGE(CONTROL_CLK) AND ROM_BLOCKS_OUTPUT(0) = '1' ) THEN
		--TODO RESET THE IR REGISTER TO 0001
			--RESET THE MAIN COUNTER
			NEW_INSTRUCTION <= '1';
			--SET ENABLE THE MAIN COUNTER
			---------------WATCH OUT DON'T PLAY HERE------------------------
			---------------WARNING IT IS A LINE IF REMOVED ALOT WILL BE DESTROYIED AND I DON'T KNOW WHY--------
			ENABLE_MAIN_COUNTER <= '1';
			ENABLE_INSTRUCTION_COUNTER <= '0';
		--ROM_BLOCKS_OUTPUT(1) IS THE GO BACK SIGNAL
		ELSIF ( FALLING_EDGE(CONTROL_CLK) AND ROM_BLOCKS_OUTPUT(1) = '1' AND ROM_BLOCKS_OUTPUT(0) = '0') THEN 
			--SET ENABLE THE MAIN COUNTER 
			ENABLE_MAIN_COUNTER <= '1';
			ENABLE_INSTRUCTION_COUNTER <= '0';
		END IF;
		  
		IF (FALLING_EDGE(CONTROL_CLK) AND NEW_INSTRUCTION = '1') THEN 
			--RESET THE NEW INSTRUCTION SIGNAL AT THE NEGATIVE EDGE OF THE SAME CYCLE
			NEW_INSTRUCTION <='0';
		END IF;
	END PROCESS;
	
	-------------------------------------------------------------------------------------------
	-------------------MAIN COUNTER sequence for different MODES---------------------------------
	--This circuit is to calculate the operations to skip depending on the MODE and the addressing
	--mode in case of two operand operations
	PROCESS (MAIN_COUNTER_OUTPUT, MODE)
	VARIABLE RESULT : std_logic_vector (1 DOWNTO 0);
	BEGIN
		IF (MODE = X"1") THEN
			IF (MAIN_COUNTER_OUTPUT = X"0" AND IR(11 DOWNTO 9)= REG_ADDRESSING_MODE AND IR(5 DOWNTO 3)= REG_ADDRESSING_MODE) THEN
				RESULT := "10"; 
			ELSIF (MAIN_COUNTER_OUTPUT = X"0" AND IR(11 DOWNTO 9)= REG_ADDRESSING_MODE) THEN
				RESULT := "01";
			ELSIF (MAIN_COUNTER_OUTPUT = X"1" AND IR(5 DOWNTO 3)= REG_ADDRESSING_MODE) THEN
				RESULT := "01";
			ELSE 
				RESULT := "00";
			END IF;
		ELSIF (MODE = X"2") THEN 
			IF (MAIN_COUNTER_OUTPUT = X"0") THEN
				RESULT := "01";
			ELSE
				RESULT := "00";
			END IF;
		ELSIF (MODE = X"3") THEN 
			IF (MAIN_COUNTER_OUTPUT = X"0") THEN
				RESULT := "10";
			ELSE 
				RESULT := "00";
			END IF;
		ELSIF (MODE = X"4") THEN 
			IF (MAIN_COUNTER_OUTPUT = X"0") THEN
				RESULT := "11";
			ELSE
				RESULT := "00";
			END IF;
		ELSIF (MODE = X"0")THEN
			RESULT := "00";
		END IF;
		MAIN_COUNTER_INCREMENT <= RESULT;
	END PROCESS;
	
	--------------------------------------------------------------------------------------------------
	-----------------------------------Control Word MUX-----------------------------------------------
	ROM_BLOCKS_OUTPUT <= 
		INSTRUCTION_FETCHING_BLOCK_OUTPUT 	WHEN MAIN_COUNTER_OUTPUT = "000" ELSE 
		SRC_FETCHING_BLOCK_OUTPUT 		WHEN MAIN_COUNTER_OUTPUT = "001" ELSE 
		DEST_FETCHING_BLOCK_OUTPUT 		WHEN MAIN_COUNTER_OUTPUT = "010" ELSE 
		EXECUTE_BLOCK_OUTPUT 			WHEN MAIN_COUNTER_OUTPUT = "011" ELSE 
		EXECUTE_BRANCH_BLOCK_OUTPUT 		WHEN MAIN_COUNTER_OUTPUT = "100";
		
	---------------------------------------------------------------------------------------------------
	---------------------------------INITIAL ADDRESS MUX-----------------------------------------------
	INITIAL_ADDRESS <= 
		INSTRUCTION_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT 	WHEN MAIN_COUNTER_OUTPUT = "000" ELSE 
		SRC_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT 		WHEN MAIN_COUNTER_OUTPUT = "001" ELSE 
		DEST_FETCHING_BLOCK_INITIAL_ADDRESS_OUTPUT 		WHEN MAIN_COUNTER_OUTPUT = "010" ELSE 
		EXECUTE_BLOCK_INITIAL_ADDRESS_OUTPUT 			WHEN MAIN_COUNTER_OUTPUT = "011" ELSE 
		EXECUTE_BRANCH_BLOCK_INITIAL_ADDRESS_OUTPUT 		WHEN MAIN_COUNTER_OUTPUT = "100";
		
		
	--TODO FNISH THIS LINE PROBERLY
	--WHEN IR=RESET CODE, SO I OUT THE THE FOLLOWING CONTROLWORD (00000_0000_0000_0000_0000_00_11000) : ONLY READ AND WRITE SIGNALS ARE ACTIVE AND THERE IS NO ANY OTHER OPEATION NEED THIS CONTROL WORD FORMAT
	PU_CONTROL_WORD <= 
		(0 => '1' , 1 => '1' , OTHERS => '0') WHEN ROM_BLOCKS_OUTPUT(4 DOWNTO 3) = "11" ELSE 
		ROM_BLOCKS_OUTPUT(ROM_WIDTH-1 DOWNTO 2)& '0' & NEW_INSTRUCTION ; -- '0' FOR THE RESET SIGNAL OF PU
END CONTROL_UNIT;
