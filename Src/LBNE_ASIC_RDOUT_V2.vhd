--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: LBNE_ASIC_RDOUT.VHD          
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 10/01/2014
--////  Description:  LBNE_ASIC_RDOUT
--////					
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2013 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.LbnePkg.all;

--  Entity Declaration

ENTITY LBNE_ASIC_RDOUT_V2 IS

	PORT
	(
		sys_rst     	: IN STD_LOGIC;				-- reset		
		TS_RESET			: IN STD_LOGIC;				-- reset		
		clk_200Mhz    	: IN STD_LOGIC;				-- clock
		clk_sys	    	: IN STD_LOGIC;				-- system clock 
		clk_TS	    	: IN STD_LOGIC;				-- timestamp clock 

		
		NOVA_TIME_SYNC			: IN STD_LOGIC;				-- NOVA_SYNC_ADC		
		LBNE_ADC_RST			: IN STD_LOGIC;				-- LBNE_SYNC_ADC				
	
		sync_sel_L		: IN STD_LOGIC_VECTOR(3 downto 0); 	
		sync_sel_R		: IN STD_LOGIC_VECTOR(3 downto 0); 	
		CLK_disable		: IN STD_LOGIC_VECTOR(7 downto 0); 	
		CLK_select		: IN STD_LOGIC_VECTOR(7 downto 0); 		
		CHP_select		: IN STD_LOGIC_VECTOR(7 downto 0); 	
		CHN_select		: IN STD_LOGIC_VECTOR(7 downto 0); 
		TST_PATT_EN		: IN STD_LOGIC_VECTOR(7 downto 0); 
		TST_PATT			: IN STD_LOGIC_VECTOR(11 downto 0);
		Header_P_event	: IN STD_LOGIC_VECTOR(7 downto 0); 	-- Number of events packed per header  		
		LATCH_LOC_1		: IN STD_LOGIC_VECTOR(7 downto 0);
		LATCH_LOC_2		: IN STD_LOGIC_VECTOR(7 downto 0);
		LATCH_LOC_3		: IN STD_LOGIC_VECTOR(7 downto 0);
		LATCH_LOC_4		: IN STD_LOGIC_VECTOR(7 downto 0); 		

		TP_SYNC			: OUT STD_LOGIC;
		ADC_SYNC_L		: OUT STD_LOGIC;	-- LVDS		USE TO BE ADC_RCK_L
		ADC_SYNC_R		: OUT STD_LOGIC;	-- LVDS		USE TO BE ADC_RCK_R		
		
		ADC_FD_1			: IN STD_LOGIC_VECTOR(1 downto 0);	-- LVDS
		ADC_FD_2			: IN STD_LOGIC_VECTOR(1 downto 0);	-- LVDS
		ADC_FD_3			: IN STD_LOGIC_VECTOR(1 downto 0);	-- LVDS
		ADC_FD_4			: IN STD_LOGIC_VECTOR(1 downto 0);	-- LVDS		
		ADC_FD_5			: IN STD_LOGIC_VECTOR(1 downto 0);	-- LVDS
		ADC_FD_6			: IN STD_LOGIC_VECTOR(1 downto 0);	-- LVDS
		ADC_FD_7			: IN STD_LOGIC_VECTOR(1 downto 0);	-- LVDS
		ADC_FD_8			: IN STD_LOGIC_VECTOR(1 downto 0);	-- LVDS				
		
		ADC_F_CLK		: IN  STD_LOGIC_VECTOR(7 downto 0);  -- LVDS	 USE TO BE ADC_FD_x
		ADC_FF			: IN  STD_LOGIC_VECTOR(7 downto 0);  -- LVDS	
		ADC_FE			: IN  STD_LOGIC_VECTOR(7 downto 0);  -- LVDS	
		ADC_CLK			: OUT STD_LOGIC_VECTOR(7 downto 0);  -- LVDS	
	
	
	
		EN_TST_MODE 	: IN STD_LOGIC;
		OUT_of_SYNC	 	: OUT STD_LOGIC_VECTOR(15 downto 0);		
		DATA_VALID		: OUT STD_LOGIC;		
		LANE1_DATA		: OUT STD_LOGIC_VECTOR(15 downto 0);
		LANE2_DATA		: OUT STD_LOGIC_VECTOR(15 downto 0);
		LANE3_DATA		: OUT STD_LOGIC_VECTOR(15 downto 0);		
		LANE4_DATA		: OUT STD_LOGIC_VECTOR(15 downto 0)		

	);
	
	END LBNE_ASIC_RDOUT_V2;

ARCHITECTURE behavior OF LBNE_ASIC_RDOUT_V2 IS

 
 
   constant pat_1 : STD_LOGIC_VECTOR(2 downto 0) := b"010";

	type 		state_type2 	is (S_IDLE,  S_DATA);
	signal 	state_D			: state_type2;
   SIGNAL 	Header_cnt		:  STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL	DVALID			:	STD_LOGIC;

	SIGNAL 	TIME_STAMP		:  STD_LOGIC_VECTOR(31 downto 0);  


	SIGNAL	TST_DATA			:  tst_D_array (0 to 7);
	SIGNAL	TST_DATA_O		:  STD_LOGIC_VECTOR(15 DOWNTO 0);		
	SIGNAL	TST_LATCH		:  STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL	TST_DATA_LATCH	:	STD_LOGIC;	
	
	
	SIGNAL 	CLK_select_s	: 	STD_LOGIC_VECTOR(7 downto 0); 		
	SIGNAL 	CHP_select_s	: 	STD_LOGIC_VECTOR(7 downto 0); 	
	
	SIGNAL	ADC_header_1	:  STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	ADC_header_2	:  STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	ADC_header_3	:  STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	ADC_header_4	:  STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL	ADCData_L1	   :  ADC_array(0 to 31);	
	SIGNAL	ADCData_L2	   :  ADC_array(0 to 31);	
	SIGNAL	ADCData_L3	   :  ADC_array(0 to 31);	
	SIGNAL	ADCData_L4	   :  ADC_array(0 to 31);		
	SIGNAL	DATA_PACK_A1A	:  STD_LOGIC_VECTOR(95 downto 0);	
	SIGNAL	DATA_PACK_A2A	:  STD_LOGIC_VECTOR(95 downto 0);		
	SIGNAL	DATA_PACK_A3A	:  STD_LOGIC_VECTOR(95 downto 0);	
	SIGNAL	DATA_PACK_A4A	:  STD_LOGIC_VECTOR(95 downto 0);		
	SIGNAL	DATA_PACK_A5A	:  STD_LOGIC_VECTOR(95 downto 0);	
	SIGNAL	DATA_PACK_A6A	:  STD_LOGIC_VECTOR(95 downto 0);		
	SIGNAL	DATA_PACK_A7A	:  STD_LOGIC_VECTOR(95 downto 0);	
	SIGNAL	DATA_PACK_A8A	:  STD_LOGIC_VECTOR(95 downto 0);			
	SIGNAL	DATA_PACK_A1B	:  STD_LOGIC_VECTOR(95 downto 0);	
	SIGNAL	DATA_PACK_A2B	:  STD_LOGIC_VECTOR(95 downto 0);		
	SIGNAL	DATA_PACK_A3B	:  STD_LOGIC_VECTOR(95 downto 0);	
	SIGNAL	DATA_PACK_A4B	:  STD_LOGIC_VECTOR(95 downto 0);		
	SIGNAL	DATA_PACK_A5B	:  STD_LOGIC_VECTOR(95 downto 0);	
	SIGNAL	DATA_PACK_A6B	:  STD_LOGIC_VECTOR(95 downto 0);		
	SIGNAL	DATA_PACK_A7B	:  STD_LOGIC_VECTOR(95 downto 0);	
	SIGNAL	DATA_PACK_A8B	:  STD_LOGIC_VECTOR(95 downto 0);	
	SIGNAL	data_sel			:  STD_LOGIC_VECTOR(7 downto 0);	
	SIGNAL	HEADER_A			:  STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL	HEADER_B			:  STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL	HEADER_C			:  STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL	HEADER_D			:  STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL	ADC_SYNC			:  STD_LOGIC_VECTOR(7 downto 0);	
	SIGNAL	ADC_SYNC_CLK	:	STD_LOGIC;
	SIGNAL	SYNC_TO_SYSTEM	:	STD_LOGIC;	
	SIGNAL	NOVA_TIME_SYNC_dly :	STD_LOGIC;
	
begin

			  		  
			  process(clk_sys) 	
			  begin
				if (clk_sys'event AND clk_sys = '1') then		
						CLK_select_s	<= CLK_select;
						CHP_select_s	<= CHP_select;
				end if;
			end process;	


			  process(clk_TS) 	
			  begin
				if (clk_TS'event AND clk_TS = '1') then		
					if(TS_RESET	 = '1') THEN 
						TIME_STAMP <= x"00000000";
					else
						TIME_STAMP <= TIME_STAMP + 1;
					end if;
				end if;
			end process;	

		
			
			  process(clk_200Mhz,LBNE_ADC_RST,NOVA_TIME_SYNC) 	
			  begin
				if (clk_200Mhz'event AND clk_200Mhz = '1') then	
					NOVA_TIME_SYNC_dly <= NOVA_TIME_SYNC;
					if(NOVA_TIME_SYNC	 = '1') and (NOVA_TIME_SYNC_dly = '0') THEN 
						SYNC_TO_SYSTEM	<= '0';
					end if;
					if(LBNE_ADC_RST	 = '1') THEN 
						SYNC_TO_SYSTEM	<= '1';
					end if;
				end if;
			end process;	
		
	
			ADC_SYNC_CLK	<= clk_200Mhz   when (SYNC_TO_SYSTEM = '0') else '0';
			ADC_CLK(0)		<= '0'			when  (CLK_disable(0)  = '1') else
									ADC_SYNC_CLK when (CLK_select_s(0) = '0') else not ADC_SYNC_CLK ;		
			ADC_CLK(1)		<= '0'			when  (CLK_disable(1)  = '1') else
									 ADC_SYNC_CLK when (CLK_select_s(1) = '0') else not ADC_SYNC_CLK ;	
			ADC_CLK(2)		<= '0'			when  (CLK_disable(2)  = '1') else
									 ADC_SYNC_CLK when (CLK_select_s(2) = '0') else not ADC_SYNC_CLK ;		
			ADC_CLK(3)		<= '0'			when  (CLK_disable(3)  = '1') else
									 ADC_SYNC_CLK when (CLK_select_s(3) = '0') else not ADC_SYNC_CLK ;		
			ADC_CLK(4)		<= '0'			when  (CLK_disable(4)  = '1') else
									 ADC_SYNC_CLK when (CLK_select_s(4) = '0') else not ADC_SYNC_CLK ;			
			ADC_CLK(5)		<= '0'			when  (CLK_disable(5)  = '1') else
									 ADC_SYNC_CLK when (CLK_select_s(5) = '0') else not ADC_SYNC_CLK ;	
			ADC_CLK(6)		<= '0'			when  (CLK_disable(6)  = '1') else
									 ADC_SYNC_CLK when (CLK_select_s(6) = '0') else not ADC_SYNC_CLK ;		
			ADC_CLK(7)		<= '0'			when  (CLK_disable(7)  = '1') else
									 ADC_SYNC_CLK when (CLK_select_s(7) = '0') else not ADC_SYNC_CLK ;					
			
			
			
			
			TST_DATA_O	<= TST_DATA(0) when (CHP_select_s = x"0") else
								TST_DATA(1) when (CHP_select_s = x"1") else
								TST_DATA(2) when (CHP_select_s = x"2") else
								TST_DATA(3) when (CHP_select_s = x"3") else																
								TST_DATA(4) when (CHP_select_s = x"4") else
								TST_DATA(5) when (CHP_select_s = x"5") else
								TST_DATA(6) when (CHP_select_s = x"6") else
								TST_DATA(7) when (CHP_select_s = x"7") else
								x"0000";
		
			TST_DATA_LATCH	<= TST_LATCH(0) when (CHP_select_s = x"0") else
									TST_LATCH(1) when (CHP_select_s = x"1") else
									TST_LATCH(2) when (CHP_select_s = x"2") else
									TST_LATCH(3) when (CHP_select_s = x"3") else
									TST_LATCH(4) when (CHP_select_s = x"4") else
									TST_LATCH(5) when (CHP_select_s = x"5") else
									TST_LATCH(6) when (CHP_select_s = x"6") else
									TST_LATCH(7) when (CHP_select_s = x"7") else
									'0';

						

								
						
			
			OUT_of_SYNC(0)		<=  '0' when (ADC_header_1(2  downto 0)  = pat_1) else '1';
			OUT_of_SYNC(1)		<=  '0' when (ADC_header_1(6  downto 4)  = pat_1) else '1';
			OUT_of_SYNC(2)		<=  '0' when (ADC_header_1(10 downto 8)  = pat_1) else '1';
			OUT_of_SYNC(3)		<=  '0' when (ADC_header_1(14 downto 12) = pat_1) else '1';
			OUT_of_SYNC(4)		<=  '0' when (ADC_header_2(2  downto 0)  = pat_1) else '1';
			OUT_of_SYNC(5)		<=  '0' when (ADC_header_2(6  downto 4)  = pat_1) else '1';
			OUT_of_SYNC(6)		<=  '0' when (ADC_header_2(10 downto 8)  = pat_1) else '1';
			OUT_of_SYNC(7)		<=  '0' when (ADC_header_2(14 downto 12) = pat_1) else '1';
			OUT_of_SYNC(8)		<=  '0' when (ADC_header_3(2  downto 0)  = pat_1) else '1';
			OUT_of_SYNC(9)		<=  '0' when (ADC_header_3(6  downto 4)  = pat_1) else '1';
			OUT_of_SYNC(10)	<=  '0' when (ADC_header_3(10 downto 8)  = pat_1) else '1';
			OUT_of_SYNC(11)	<=  '0' when (ADC_header_3(14 downto 12) = pat_1) else '1';
			OUT_of_SYNC(12)	<=  '0' when (ADC_header_4(2  downto 0)  = pat_1) else '1';
			OUT_of_SYNC(13)	<=  '0' when (ADC_header_4(6  downto 4)  = pat_1) else '1';
			OUT_of_SYNC(14)	<=  '0' when (ADC_header_4(10 downto 8)  = pat_1) else '1';
			OUT_of_SYNC(15)	<=  '0' when (ADC_header_4(14 downto 12) = pat_1) else '1';


			
DATA_PACK_A1A	<= ADCData_L1(7)  & ADCData_L1(6)  & ADCData_L1(5)  & ADCData_L1(4)  & ADCData_L1(3)  & ADCData_L1(2)  & ADCData_L1(1)  & ADCData_L1(0);
DATA_PACK_A1B	<= ADCData_L1(15) & ADCData_L1(14) & ADCData_L1(13) & ADCData_L1(12) & ADCData_L1(11) & ADCData_L1(10) & ADCData_L1(9)  & ADCData_L1(8);
DATA_PACK_A2A	<= ADCData_L1(23) & ADCData_L1(22) & ADCData_L1(21) & ADCData_L1(20) & ADCData_L1(19) & ADCData_L1(18) & ADCData_L1(17) & ADCData_L1(16);
DATA_PACK_A2B	<= ADCData_L1(31) & ADCData_L1(30) & ADCData_L1(29) & ADCData_L1(28) & ADCData_L1(27) & ADCData_L1(26) & ADCData_L1(25) & ADCData_L1(24);
DATA_PACK_A3A	<= ADCData_L2(7)  & ADCData_L2(6)  & ADCData_L2(5)  & ADCData_L2(4)  & ADCData_L2(3)  & ADCData_L2(2)  & ADCData_L2(1)  & ADCData_L2(0);
DATA_PACK_A3B	<= ADCData_L2(15) & ADCData_L2(14) & ADCData_L2(13) & ADCData_L2(12) & ADCData_L2(11) & ADCData_L2(10) & ADCData_L2(9)  & ADCData_L2(8);
DATA_PACK_A4A	<= ADCData_L2(23) & ADCData_L2(22) & ADCData_L2(21) & ADCData_L2(20) & ADCData_L2(19) & ADCData_L2(18) & ADCData_L2(17) & ADCData_L2(16);
DATA_PACK_A4B	<= ADCData_L2(31) & ADCData_L2(30) & ADCData_L2(29) & ADCData_L2(28) & ADCData_L2(27) & ADCData_L2(26) & ADCData_L2(25) & ADCData_L2(24);
DATA_PACK_A5A	<= ADCData_L3(7)  & ADCData_L3(6)  & ADCData_L3(5)  & ADCData_L3(4)  & ADCData_L3(3)  & ADCData_L3(2)  & ADCData_L3(1)  & ADCData_L3(0);
DATA_PACK_A5B	<= ADCData_L3(15) & ADCData_L3(14) & ADCData_L3(13) & ADCData_L3(12) & ADCData_L3(11) & ADCData_L3(10) & ADCData_L3(9)  & ADCData_L3(8);
DATA_PACK_A6A	<= ADCData_L3(23) & ADCData_L3(22) & ADCData_L3(21) & ADCData_L3(20) & ADCData_L3(19) & ADCData_L3(18) & ADCData_L3(17) & ADCData_L3(16);
DATA_PACK_A6B	<= ADCData_L3(31) & ADCData_L3(30) & ADCData_L3(29) & ADCData_L3(28) & ADCData_L3(27) & ADCData_L3(26) & ADCData_L3(25) & ADCData_L3(24);
DATA_PACK_A7A	<= ADCData_L4(7)  & ADCData_L4(6)  & ADCData_L4(5)  & ADCData_L4(4)  & ADCData_L4(3)  & ADCData_L4(2)  & ADCData_L4(1)  & ADCData_L4(0);
DATA_PACK_A7B	<= ADCData_L4(15) & ADCData_L4(14) & ADCData_L4(13) & ADCData_L4(12) & ADCData_L4(11) & ADCData_L4(10) & ADCData_L4(9)  & ADCData_L4(8);
DATA_PACK_A8A	<= ADCData_L4(23) & ADCData_L4(22) & ADCData_L4(21) & ADCData_L4(20) & ADCData_L4(19) & ADCData_L4(18) & ADCData_L4(17) & ADCData_L4(16);
DATA_PACK_A8B	<= ADCData_L4(31) & ADCData_L4(30) & ADCData_L4(29) & ADCData_L4(28) & ADCData_L4(27) & ADCData_L4(26) & ADCData_L4(25) & ADCData_L4(24);


			DATA_VALID		<= DVALID	when (EN_TST_MODE = '0') else
									TST_DATA_LATCH;

			LANE1_DATA		<= TST_DATA_O						 when (EN_TST_MODE = '1') else
									TIME_STAMP(15 downto 0)		 when (data_sel = x"00") else
									TIME_STAMP(31 downto 16)	 when (data_sel = x"01") else
									HEADER_C 						 when (data_sel = x"02") else
									HEADER_D 						 when (data_sel = x"03") else
									DATA_PACK_A1A(15 downto 0)	 when (data_sel = x"04") else
									DATA_PACK_A1A(31 downto 16) when (data_sel = x"05") else
									DATA_PACK_A1A(47 downto 32) when (data_sel = x"06") else
									DATA_PACK_A1A(63 downto 48) when (data_sel = x"07") else
									DATA_PACK_A1A(79 downto 64) when (data_sel = x"08") else
									DATA_PACK_A1A(95 downto 80) when (data_sel = x"09") else									
									DATA_PACK_A1B(15 downto 0)	 when (data_sel = x"0a") else
									DATA_PACK_A1B(31 downto 16) when (data_sel = x"0b") else
									DATA_PACK_A1B(47 downto 32) when (data_sel = x"0c") else
									DATA_PACK_A1B(63 downto 48) when (data_sel = x"0d") else
									DATA_PACK_A1B(79 downto 64) when (data_sel = x"0e") else
									DATA_PACK_A1B(95 downto 80) when (data_sel = x"0f") else
									DATA_PACK_A2A(15 downto 0)	 when (data_sel = x"10") else
									DATA_PACK_A2A(31 downto 16) when (data_sel = x"11") else
									DATA_PACK_A2A(47 downto 32) when (data_sel = x"12") else
									DATA_PACK_A2A(63 downto 48) when (data_sel = x"13") else
									DATA_PACK_A2A(79 downto 64) when (data_sel = x"14") else
									DATA_PACK_A2A(95 downto 80) when (data_sel = x"15") else									
									DATA_PACK_A2B(15 downto 0)	 when (data_sel = x"16") else
									DATA_PACK_A2B(31 downto 16) when (data_sel = x"17") else
									DATA_PACK_A2B(47 downto 32) when (data_sel = x"18") else
									DATA_PACK_A2B(63 downto 48) when (data_sel = x"19") else
									DATA_PACK_A2B(79 downto 64) when (data_sel = x"20") else
									DATA_PACK_A2B(95 downto 80) when (data_sel = x"21");								
									
									
			LANE2_DATA		<= TST_DATA_O						 when (EN_TST_MODE = '1') else
									TIME_STAMP(15 downto 0)		 when (data_sel = x"00") else
									TIME_STAMP(31 downto 16)	 when (data_sel = x"01") else
									HEADER_C 						 when (data_sel = x"02") else
									HEADER_D 						 when (data_sel = x"03") else
									DATA_PACK_A3A(15 downto 0)	 when (data_sel = x"04") else
									DATA_PACK_A3A(31 downto 16) when (data_sel = x"05") else
									DATA_PACK_A3A(47 downto 32) when (data_sel = x"06") else
									DATA_PACK_A3A(63 downto 48) when (data_sel = x"07") else
									DATA_PACK_A3A(79 downto 64) when (data_sel = x"08") else
									DATA_PACK_A3A(95 downto 80) when (data_sel = x"09") else									
									DATA_PACK_A3B(15 downto 0)	 when (data_sel = x"0a") else
									DATA_PACK_A3B(31 downto 16) when (data_sel = x"0b") else
									DATA_PACK_A3B(47 downto 32) when (data_sel = x"0c") else
									DATA_PACK_A3B(63 downto 48) when (data_sel = x"0d") else
									DATA_PACK_A3B(79 downto 64) when (data_sel = x"0e") else
									DATA_PACK_A3B(95 downto 80) when (data_sel = x"0f") else
									DATA_PACK_A4A(15 downto 0)	 when (data_sel = x"10") else
									DATA_PACK_A4A(31 downto 16) when (data_sel = x"11") else
									DATA_PACK_A4A(47 downto 32) when (data_sel = x"12") else
									DATA_PACK_A4A(63 downto 48) when (data_sel = x"13") else
									DATA_PACK_A4A(79 downto 64) when (data_sel = x"14") else
									DATA_PACK_A4A(95 downto 80) when (data_sel = x"15") else									
									DATA_PACK_A4B(15 downto 0)	 when (data_sel = x"16") else
									DATA_PACK_A4B(31 downto 16) when (data_sel = x"17") else
									DATA_PACK_A4B(47 downto 32) when (data_sel = x"18") else
									DATA_PACK_A4B(63 downto 48) when (data_sel = x"19") else
									DATA_PACK_A4B(79 downto 64) when (data_sel = x"20") else
									DATA_PACK_A4B(95 downto 80) when (data_sel = x"21");											
									
									
			LANE3_DATA		<= TST_DATA_O						 when (EN_TST_MODE = '1') else
									TIME_STAMP(15 downto 0)		 when (data_sel = x"00") else
									TIME_STAMP(31 downto 16)	 when (data_sel = x"01") else
									HEADER_C 						 when (data_sel = x"02") else
									HEADER_D 						 when (data_sel = x"03") else
									DATA_PACK_A5A(15 downto 0)	 when (data_sel = x"04") else
									DATA_PACK_A5A(31 downto 16) when (data_sel = x"05") else
									DATA_PACK_A5A(47 downto 32) when (data_sel = x"06") else
									DATA_PACK_A5A(63 downto 48) when (data_sel = x"07") else
									DATA_PACK_A5A(79 downto 64) when (data_sel = x"08") else
									DATA_PACK_A5A(95 downto 80) when (data_sel = x"09") else									
									DATA_PACK_A5B(15 downto 0)	 when (data_sel = x"0a") else
									DATA_PACK_A5B(31 downto 16) when (data_sel = x"0b") else
									DATA_PACK_A5B(47 downto 32) when (data_sel = x"0c") else
									DATA_PACK_A5B(63 downto 48) when (data_sel = x"0d") else
									DATA_PACK_A5B(79 downto 64) when (data_sel = x"0e") else
									DATA_PACK_A5B(95 downto 80) when (data_sel = x"0f") else
									DATA_PACK_A6A(15 downto 0)	 when (data_sel = x"10") else
									DATA_PACK_A6A(31 downto 16) when (data_sel = x"11") else
									DATA_PACK_A6A(47 downto 32) when (data_sel = x"12") else
									DATA_PACK_A6A(63 downto 48) when (data_sel = x"13") else
									DATA_PACK_A6A(79 downto 64) when (data_sel = x"14") else
									DATA_PACK_A6A(95 downto 80) when (data_sel = x"15") else									
									DATA_PACK_A6B(15 downto 0)	 when (data_sel = x"16") else
									DATA_PACK_A6B(31 downto 16) when (data_sel = x"17") else
									DATA_PACK_A6B(47 downto 32) when (data_sel = x"18") else
									DATA_PACK_A6B(63 downto 48) when (data_sel = x"19") else
									DATA_PACK_A6B(79 downto 64) when (data_sel = x"20") else
									DATA_PACK_A6B(95 downto 80) when (data_sel = x"21");																				
								
			LANE4_DATA		<= TST_DATA_O						 when (EN_TST_MODE = '1') else
									TIME_STAMP(15 downto 0)		 when (data_sel = x"00") else
									TIME_STAMP(31 downto 16)	 when (data_sel = x"01") else
									HEADER_C 						 when (data_sel = x"02") else
									HEADER_D 						 when (data_sel = x"03") else
									DATA_PACK_A7A(15 downto 0)	 when (data_sel = x"04") else
									DATA_PACK_A7A(31 downto 16) when (data_sel = x"05") else
									DATA_PACK_A7A(47 downto 32) when (data_sel = x"06") else
									DATA_PACK_A7A(63 downto 48) when (data_sel = x"07") else
									DATA_PACK_A7A(79 downto 64) when (data_sel = x"08") else
									DATA_PACK_A7A(95 downto 80) when (data_sel = x"09") else									
									DATA_PACK_A7B(15 downto 0)	 when (data_sel = x"0a") else
									DATA_PACK_A7B(31 downto 16) when (data_sel = x"0b") else
									DATA_PACK_A7B(47 downto 32) when (data_sel = x"0c") else
									DATA_PACK_A7B(63 downto 48) when (data_sel = x"0d") else
									DATA_PACK_A7B(79 downto 64) when (data_sel = x"0e") else
									DATA_PACK_A7B(95 downto 80) when (data_sel = x"0f") else
									DATA_PACK_A8A(15 downto 0)	 when (data_sel = x"10") else
									DATA_PACK_A8A(31 downto 16) when (data_sel = x"11") else
									DATA_PACK_A8A(47 downto 32) when (data_sel = x"12") else
									DATA_PACK_A8A(63 downto 48) when (data_sel = x"13") else
									DATA_PACK_A8A(79 downto 64) when (data_sel = x"14") else
									DATA_PACK_A8A(95 downto 80) when (data_sel = x"15") else									
									DATA_PACK_A8B(15 downto 0)	 when (data_sel = x"16") else
									DATA_PACK_A8B(31 downto 16) when (data_sel = x"17") else
									DATA_PACK_A8B(47 downto 32) when (data_sel = x"18") else
									DATA_PACK_A8B(63 downto 48) when (data_sel = x"19") else
									DATA_PACK_A8B(79 downto 64) when (data_sel = x"20") else
									DATA_PACK_A8B(95 downto 80) when (data_sel = x"21") else
									x"5a5a";			
									



 process(clk_sys,sys_rst) 
begin
	if  (sys_rst = '1') then
		Header_cnt		<= Header_P_event;
		data_sel			<= x"00";
		DVALID	   	<= '0';
		state_D			<= S_idle;	
	elsif clk_sys'event and clk_sys = '1' then
	CASE state_D IS
		when S_IDLE =>		
			DVALID	 		<= '0';
			data_sel		 	<= x"00";
			if(TST_LATCH(0) = '1') then
					if(Header_cnt	=  x"00") then
						data_sel		 	<= x"00";
						Header_cnt		<= Header_P_event;
						DVALID	   	<= '1';
						state_D			<= S_DATA;
					else
						Header_cnt		<= Header_cnt - 1;
						DVALID	   	<= '1';
						data_sel		 	<= x"04";
						state_D			<= S_DATA;
					end if;
			end if;
		when S_DATA	  =>							
					data_sel			 <= data_sel + 1;
					DVALID 			 <= '1';
					IF( data_sel = x"21" ) THEN
						DVALID	  	 	<= '0';
						state_D			<= S_idle;	
					END IF;
		 when others =>		
				state_D <= S_idle;		
		 end case; 		
	
	end if;
end process;

	

	ADC_SYNC_L		<= ADC_SYNC(0) WHEN sync_sel_L = X"0" ELSE
							ADC_SYNC(1) WHEN sync_sel_L = X"1" ELSE
							ADC_SYNC(2) WHEN sync_sel_L = X"2" ELSE
							ADC_SYNC(3) WHEN sync_sel_L = X"3" ELSE
							ADC_SYNC(0);

	
	ADC_SYNC_R		<= ADC_SYNC(4) WHEN sync_sel_R = X"0" ELSE
							ADC_SYNC(5) WHEN sync_sel_R = X"1" ELSE
							ADC_SYNC(6) WHEN sync_sel_R = X"2" ELSE
							ADC_SYNC(7) WHEN sync_sel_R = X"3" ELSE
							ADC_SYNC(4);
	
	TP_SYNC			<= ADC_SYNC(1);
	


--CHK: for i in 0 to 1  generate 
--
--
-- LBNE_ADC_ASIC : entity work.LBNE_ASIC_DATA_V3
--	PORT MAP
--	(
--			clk_200Mhz		=> clk_200Mhz,
--			clk_sys			=> clk_sys,	
--			sys_rst 			=> sys_rst,
--			ADC_FD			=> ADC_FD_1,
--			ADC_FE			=> ADC_FE(i),
--			CHN_select		=> CHN_select,	
--			LATCH_LOC		=> LATCH_LOC_1(((i*4)+3) downto (i*4)),							
--			ADC_TST_PATT_EN=> TST_PATT_EN(i),
--			ADC_TST_PATT	=> TST_PATT,
--			ADC_header_out =>	ADC_header_1(((i*8)+7) downto (i*8)),			
--			ADC_SYNC		 	=> ADC_SYNC(i),	 -- ADC_SYNC_L,	
--			HS_DATA_LATCH 	=> TST_LATCH(i),
--			DATA_OUT 		=> TST_DATA(i),
--			ADCData			=>	ADCData_L1((i*16) to ((i*16)+15))
--	);
--	 
--end generate;




									
 LBNE_ADC_ASIC_1 : entity work.LBNE_ASIC_DATA_V3
	PORT MAP
	(
			clk_200Mhz		=> clk_200Mhz,
			clk_sys			=> clk_sys,	
			sys_rst 			=> sys_rst,
			ADC_FD			=> ADC_FD_1,
			ADC_FE			=> ADC_FE(0),
			CHN_select		=> CHN_select,	
			LATCH_LOC		=> LATCH_LOC_1(3 downto 0),							
			ADC_TST_PATT_EN=> TST_PATT_EN(0),
			ADC_TST_PATT	=> TST_PATT,
			ADC_header_out =>	ADC_header_1(7 downto 0),			
			ADC_SYNC		 	=> ADC_SYNC(0),	 -- ADC_SYNC_L,	
			HS_DATA_LATCH 	=> TST_LATCH(0),
			DATA_OUT 		=> TST_DATA(0),
			ADCData			=>	ADCData_L1(0 to 15)
	);
	 
	 
	 
	 
  LBNE_ADC_ASIC_2 : entity work.LBNE_ASIC_DATA_V3
	PORT MAP
	(
			clk_200Mhz		=> clk_200Mhz,
			clk_sys			=> clk_sys,	
			sys_rst 			=> sys_rst,
			ADC_FD			=> ADC_FD_2,
			ADC_FE			=> ADC_FE(1),
			CHN_select		=> CHN_select,	
			LATCH_LOC		=> LATCH_LOC_1(7 downto 4),							
			ADC_TST_PATT_EN=> TST_PATT_EN(1),
			ADC_TST_PATT	=> TST_PATT,
			ADC_header_out =>	ADC_header_1(15 downto 8),			
			ADC_SYNC		 	=> ADC_SYNC(1),	 -- ADC_SYNC_L,	
			HS_DATA_LATCH 	=> TST_LATCH(1),
			DATA_OUT 		=> TST_DATA(1),
			ADCData			=>	ADCData_L1(16 to 31)
	);
	 

 
 LBNE_ADC_ASIC_3 : entity work.LBNE_ASIC_DATA_V3
	PORT MAP
	(
			clk_200Mhz		=> clk_200Mhz,
			clk_sys			=> clk_sys,	
			sys_rst 			=> sys_rst,
			ADC_FD			=> ADC_FD_3,
			ADC_FE			=> ADC_FE(2),
			CHN_select		=> CHN_select,	
			LATCH_LOC		=> LATCH_LOC_2(3 downto 0),							
			ADC_TST_PATT_EN=> TST_PATT_EN(2),
			ADC_TST_PATT	=> TST_PATT,
			ADC_header_out =>	ADC_header_2(7 downto 0),			
			ADC_SYNC		 	=> ADC_SYNC(2),	 -- ADC_SYNC_L,	
			HS_DATA_LATCH 	=> TST_LATCH(2),
			DATA_OUT 		=> TST_DATA(2),
			ADCData			=>	ADCData_L2(0 to 15)
	);
	 
	 
  LBNE_ADC_ASIC_4 : entity work.LBNE_ASIC_DATA_V3
	PORT MAP
	(
			clk_200Mhz		=> clk_200Mhz,
			clk_sys			=> clk_sys,	
			sys_rst 			=> sys_rst,
			ADC_FD			=> ADC_FD_4,
			ADC_FE			=> ADC_FE(3),
			CHN_select		=> CHN_select,	
			LATCH_LOC		=> LATCH_LOC_2(7 downto 4),							
			ADC_TST_PATT_EN=> TST_PATT_EN(3),
			ADC_TST_PATT	=> TST_PATT,
			ADC_header_out =>	ADC_header_2(15 downto 8),			
			ADC_SYNC		 	=> ADC_SYNC(3),	 -- ADC_SYNC_L,	
			HS_DATA_LATCH 	=> TST_LATCH(3),
			DATA_OUT 		=> TST_DATA(3),
			ADCData			=>	ADCData_L2(16 to 31)
	);
	 
 
 
 
									
 LBNE_ADC_ASIC_5 : entity work.LBNE_ASIC_DATA_V3
	PORT MAP
	(
			clk_200Mhz		=> clk_200Mhz,
			clk_sys			=> clk_sys,	
			sys_rst 			=> sys_rst,
			ADC_FD			=> ADC_FD_5,
			ADC_FE			=> ADC_FE(4),
			CHN_select		=> CHN_select,	
			LATCH_LOC		=> LATCH_LOC_3(3 downto 0),							
			ADC_TST_PATT_EN=> TST_PATT_EN(4),
			ADC_TST_PATT	=> TST_PATT,
			ADC_header_out =>	ADC_header_3(7 downto 0),			
			ADC_SYNC		 	=> ADC_SYNC(4),	 -- ADC_SYNC_L,	
			HS_DATA_LATCH 	=> TST_LATCH(4),
			DATA_OUT 		=> TST_DATA(4),
			ADCData			=>	ADCData_L3(0 to 15)
	);
	 
	 
  LBNE_ADC_ASIC_6 : entity work.LBNE_ASIC_DATA_V3
	PORT MAP
	(
			clk_200Mhz		=> clk_200Mhz,
			clk_sys			=> clk_sys,	
			sys_rst 			=> sys_rst,
			ADC_FD			=> ADC_FD_6,
			ADC_FE			=> ADC_FE(5),
			CHN_select		=> CHN_select,	
			LATCH_LOC		=> LATCH_LOC_3(7 downto 4),							
			ADC_TST_PATT_EN=> TST_PATT_EN(5),
			ADC_TST_PATT	=> TST_PATT,
			ADC_header_out =>	ADC_header_3(15 downto 8),			
			ADC_SYNC		 	=> ADC_SYNC(5),	 -- ADC_SYNC_L,	
			HS_DATA_LATCH 	=> TST_LATCH(5),
			DATA_OUT 		=> TST_DATA(5),
			ADCData			=>	ADCData_L3(16 to 31)
	);
	 

 
 LBNE_ADC_ASIC_7 : entity work.LBNE_ASIC_DATA_V3
	PORT MAP
	(
			clk_200Mhz		=> clk_200Mhz,
			clk_sys			=> clk_sys,	
			sys_rst 			=> sys_rst,
			ADC_FD			=> ADC_FD_7,
			ADC_FE			=> ADC_FE(6),
			CHN_select		=> CHN_select,	
			LATCH_LOC		=> LATCH_LOC_4(3 downto 0),							
			ADC_TST_PATT_EN=> TST_PATT_EN(6),
			ADC_TST_PATT	=> TST_PATT,
			ADC_header_out =>	ADC_header_4(7 downto 0),			
			ADC_SYNC		 	=> ADC_SYNC(6),	 -- ADC_SYNC_L,	
			HS_DATA_LATCH 	=> TST_LATCH(6),
			DATA_OUT 		=> TST_DATA(6),
			ADCData			=>	ADCData_L4(0 to 15)
	);
	 
	 
  LBNE_ADC_ASIC_8 : entity work.LBNE_ASIC_DATA_V3
	PORT MAP
	(
			clk_200Mhz		=> clk_200Mhz,
			clk_sys			=> clk_sys,	
			sys_rst 			=> sys_rst,
			ADC_FD			=> ADC_FD_8,
			ADC_FE			=> ADC_FE(7),
			CHN_select		=> CHN_select,	
			LATCH_LOC		=> LATCH_LOC_4(7 downto 4),							
			ADC_TST_PATT_EN=> TST_PATT_EN(7),
			ADC_TST_PATT	=> TST_PATT,
			ADC_header_out =>	ADC_header_4(15 downto 8),			
			ADC_SYNC		 	=> ADC_SYNC(7),	 -- ADC_SYNC_L,	
			HS_DATA_LATCH 	=> TST_LATCH(7),
			DATA_OUT 		=> TST_DATA(7),
			ADCData			=>	ADCData_L4(16 to 31)
	);
	 
 
 
END behavior;

	
	