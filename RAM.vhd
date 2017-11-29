LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.MY_PACKAGE.

ENTITY RAM IS
	GENERIC (ADDRESS_SIZE : INTEGER :=10; CELL_SIZE : INTEGER := 16);
	PORT (
		DATA_IN :IN STD_LOGIC_VECTOR(CELL_SIZE-1 DOWNTO 0);
		--READING MODE 16 BIT IF 0 32 IF 1
		RD, WRT, READING_MODE : IN STD_LOGIC;
		DATA_OUT : OUT STD_LOGIC_VECTOR(CELL_SIZE-1 DOWNTO 0);
		--MDR_READ IS THE SIGNAL TO ENABLE THE MDR TO READ FROM THE MEMORY
		MFC, MDR_READ : OUT STD_LOGIC;
	);
END ENTITY RAM;
