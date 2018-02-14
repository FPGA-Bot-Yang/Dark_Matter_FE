--*********************************************************
--* FILE  : LBNE_TST_PULE.VHD
--* Author: Jack Fried
--*
--* Last Modified: 06/09/2014
--*  
--* Description: LBNE_TST_PULE
--*		 		               
--*
--*
--*
--*
--*
--*
--*********************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;


--  Entity Declaration

ENTITY LBNE_TST_PULSE IS

	PORT
	(
		sys_rst     	: IN STD_LOGIC;			
		clk_50Mhz    	: IN STD_LOGIC;				-- clock
		TP_ENABLE		: IN STD_LOGIC;
		LA_SYNC		 	: IN STD_LOGIC;				
		TP_AMPL			: IN STD_LOGIC_VECTOR(4 downto 0);
		TP_DLY			: IN STD_LOGIC_VECTOR(15 downto 0);
		TP_FREQ			: IN STD_LOGIC_VECTOR(15 downto 0);
		DAC_CNTL			: OUT STD_LOGIC_VECTOR(4 downto 0)
	);
	

	END LBNE_TST_PULSE;

ARCHITECTURE behavior OF LBNE_TST_PULSE IS


 signal TP_FRQ_CNT		: STD_LOGIC_VECTOR(15 downto 0);
 signal TP_DLY_CNT		: STD_LOGIC_VECTOR(15 downto 0);
 signal TP_EN				: STD_LOGIC;
 signal LA_SYNC_event	: STD_LOGIC;
 signal LA_SYNC_D1		: STD_LOGIC;
 signal LA_SYNC_D2		: STD_LOGIC;
 
 
begin


		DAC_CNTL  <= TP_AMPL 	when (TP_EN = '0') and (TP_ENABLE = '1') else
						 b"00000";

		 
 process(clk_50Mhz,sys_rst) 
begin
	if clk_50Mhz'event and clk_50Mhz = '1' then
		LA_SYNC_D1	<= LA_SYNC;
		LA_SYNC_D2	<= LA_SYNC_D1;
	end if;
end process;

			

 process(clk_50Mhz,sys_rst) 
begin
	if  (sys_rst = '1') then
		TP_FRQ_CNT		<= x"0000";
		LA_SYNC_event	<= '0';
		TP_EN			<= '0';
		TP_DLY_CNT  <=  x"0000";	
	elsif clk_50Mhz'event and clk_50Mhz = '1' then
		if( LA_SYNC_D1 = '1' and LA_SYNC_D2 = '0') then
			TP_FRQ_CNT	<= TP_FRQ_CNT + 1;
		end if;	
		if(TP_FRQ_CNT >= TP_FREQ) then
			TP_FRQ_CNT		<= x"0000";
			LA_SYNC_event	<= '1';
		end if;
		if(LA_SYNC_event = '1') then
				TP_DLY_CNT  <=  TP_DLY_CNT + 1;
				if(TP_DLY_CNT = TP_DLY) then
					TP_EN			<= '1';
				end if;
				if(TP_DLY_CNT = (TP_DLY + 1000))  then  -- 500
					TP_EN			<= '0';
					TP_DLY_CNT  <=  x"0000";	
					LA_SYNC_event	<= '0';
				end if;					
		end if;	
	end if;
end process;


--				 
-- process(clk_50Mhz,sys_rst) 
--begin
--	if  (sys_rst = '1') then
--		TP_FRQ_CNT		<= x"0000";
--		LA_SYNC_event	<= '0';
--		TP_EN				<= '0';
--		TP_DLY_CNT  	<=  x"0000";	
--	elsif clk_50Mhz'event and clk_50Mhz = '1' then
--	
--		if(TP_ENABLE = '1') then
--			if(TP_FRQ_CNT < TP_FREQ) then
--				TP_FRQ_CNT	<= TP_FRQ_CNT + 1;
--			elsif(TP_FRQ_CNT = TP_FREQ) then
--				TP_FRQ_CNT		<= x"ffff";
--				LA_SYNC_event	<= '1';
--			end if;
--		else
--				TP_FRQ_CNT		<= x"0000";
--				LA_SYNC_event	<= '0';
--		end if;
--		
--		if(LA_SYNC_event = '1') then
--				TP_DLY_CNT  <=  TP_DLY_CNT + 1;
--				if(TP_DLY_CNT = TP_DLY) then
--					TP_EN			<= '1';
--				end if;
--				if(TP_DLY_CNT = (TP_DLY + 1000))  then  -- 500
--					TP_EN			<= '0';
--					TP_DLY_CNT  <=  x"0000";	
--					LA_SYNC_event	<= '0';
--				end if;					
--		end if;	
--	end if;
--end process;



END behavior;

	
	