LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.MY_PACKAGE.ALL;

ENTITY REGISTER_ADDRESS_DECODER2 IS
	PORT (
		REG_CODE	: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
		DECODER_OUT	: OUT STD_LOGIC_VECTOR (REGISTER_STATES_ON_BUS-1 DOWNTO 0)
	);

END ENTITY REGISTER_ADDRESS_DECODER2;



architecture REGISTER_ADDRESS_DECODER_ARCH2 of REGISTER_ADDRESS_DECODER2 is
begin

	DECODER_OUT <=	(OTHERS=>'0')		WHEN  REG_CODE = "00"	--NO REGISTER
	ELSE		(8=>'1',OTHERS=>'0')	WHEN  REG_CODE = "01"	--MAR
	ELSE		(9=>'1',OTHERS=>'0')	WHEN  REG_CODE = "10"	--MDR
	ELSE		(11=>'1',OTHERS=>'0')	WHEN  REG_CODE = "11"	--SRC
	ELSE		(others=>'1');	--THE IMPOSIBLE CASE (IT WILL OPEN ALL TRI-STATES) ,IT WILL BE LIKE "FARA7 EL-3OMDA"




end REGISTER_ADDRESS_DECODER_ARCH2;