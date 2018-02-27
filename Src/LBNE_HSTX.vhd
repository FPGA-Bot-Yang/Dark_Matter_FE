
--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: LBNE_HSTX.VHD            
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 11/04/2014 
--////  Description:  
--////					
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2014 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////

library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
USE work.LbnePkg.all;

entity LBNE_HSTX is
	PORT
	(

		GXB_TX_A			: OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
		rst				: IN STD_LOGIC;
		cal_clk_125MHz	: IN STD_LOGIC;
		gxb_clk			: IN STD_LOGIC;			
		Stream_EN		: IN STD_LOGIC;	
		PRBS_EN			: IN STD_LOGIC;	
		CNT_EN			: IN STD_LOGIC;			
		DATA_CLK			: IN STD_LOGIC;
		DATA_VALID		: IN STD_LOGIC;			
		LANE1_DATA		: IN STD_LOGIC_VECTOR(15 downto 0);
		LANE2_DATA		: IN STD_LOGIC_VECTOR(15 downto 0);
		LANE3_DATA		: IN STD_LOGIC_VECTOR(15 downto 0);		
		LANE4_DATA		: IN STD_LOGIC_VECTOR(15 downto 0);

		-- Ethan
		byteordering_flag 	: IN STD_LOGIC;
		wordalignment_flag	: IN STD_LOGIC
	);
end LBNE_HSTX;


architecture LBNE_HSTX_arch of LBNE_HSTX is

type STATE_TYPE is (SYNC, HEADER, TIMESTAMP, PAYLOAD, TAIL, IDLE);
	signal state_1, state_2, state_3, state_4 : STATE_TYPE;

component ALTGX_TX
	PORT
	(
		tx_dataout		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0);	
		tx_datain		: IN STD_LOGIC_VECTOR (63 DOWNTO 0);	
		tx_ctrlenable	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);	
		tx_digitalreset: IN STD_LOGIC_VECTOR (3 DOWNTO 0);		
		cal_blk_clk		: IN STD_LOGIC;
		pll_inclk		: IN STD_LOGIC;
		pll_locked		: OUT STD_LOGIC;
		tx_clkout		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
		tx_coreclk		: IN  STD_LOGIC_VECTOR (3 DOWNTO 0)
	);
end component;


component ADC_FIFO
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		wrfull		: OUT STD_LOGIC 
	);
end component;


SIGNAL	TX_DATA1				: STD_LOGIC_VECTOR(15 downto 0);
SIGNAL	TX_DATA2				: STD_LOGIC_VECTOR(15 downto 0);
SIGNAL	TX_DATA3				: STD_LOGIC_VECTOR(15 downto 0);
SIGNAL	TX_DATA4				: STD_LOGIC_VECTOR(15 downto 0);

SIGNAL	FIFO_DATA1			: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL	FIFO_DATA2			: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL	FIFO_DATA3			: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL	FIFO_DATA4			: STD_LOGIC_VECTOR (15 DOWNTO 0);

--SIGNAL	tx_ctrlenable		: STD_LOGIC_VECTOR (1 DOWNTO 0);
SIGNAL	tx_digitalreset	: STD_LOGIC;
SIGNAL	tx_clkout			: STD_LOGIC_VECTOR (3 DOWNTO 0);
SIGNAL	counter				: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL	prbs_data			: STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL	ADC_FIFO_EMPTY		: STD_LOGIC;


-----Ethan------
signal	tx_ctrlenable_1				: std_logic_vector (1 downto 0);
signal	tx_ctrlenable_2				: std_logic_vector (1 downto 0);
signal	tx_ctrlenable_3				: std_logic_vector (1 downto 0);
signal	tx_ctrlenable_4				: std_logic_vector (1 downto 0);
signal 	tx_ctrlenable_counter_1 	: std_logic_vector (19 downto 0);
signal 	tx_ctrlenable_counter_2 	: std_logic_vector (19 downto 0);
signal 	tx_ctrlenable_counter_3 	: std_logic_vector (19 downto 0);
signal 	tx_ctrlenable_counter_4 	: std_logic_vector (19 downto 0);
signal 	idle_counter_1 				: std_logic_vector (11 downto 0);
signal 	idle_counter_2 				: std_logic_vector (11 downto 0);
signal 	idle_counter_3 				: std_logic_vector (11 downto 0);
signal 	idle_counter_4 				: std_logic_vector (11 downto 0);
signal 	time_stamp_1 					: std_logic_vector (15 downto 0);
signal 	time_stamp_2 					: std_logic_vector (15 downto 0);
signal 	time_stamp_3 					: std_logic_vector (15 downto 0);
signal 	time_stamp_4 					: std_logic_vector (15 downto 0);


----------------

begin

-- Tranceiver IP
ALTGX_TX_inst	: ALTGX_TX
	PORT MAP
	(
		tx_dataout			=> GXB_TX_A,	
		cal_blk_clk			=>	cal_clk_125MHz,
		pll_inclk			=> gxb_clk,
		tx_ctrlenable		=> tx_ctrlenable_4 & tx_ctrlenable_3 & tx_ctrlenable_2 & tx_ctrlenable_1,	 	
		tx_datain			=> TX_DATA4 & TX_DATA3 & TX_DATA2 & TX_DATA1,	
		tx_digitalreset	=>	tx_digitalreset & tx_digitalreset & tx_digitalreset & tx_digitalreset,
		tx_clkout			=>	tx_clkout,
		pll_locked			=> open,
		tx_coreclk			=> tx_clkout
	);

	
	tx_digitalreset	<=  rst;
--	tx_ctrlenable	<= b"11"		when (Stream_EN 	= '0') else
--							b"00"		when (CNT_EN 	= '1') or (PRBS_EN 	= '1') else
--							b"00"		when (ADC_FIFO_EMPTY = '0') else
--							b"11";
														
--	TX_DATA1		<=		x"BCFB"			when (Stream_EN 	= '0') else
--							counter			when (CNT_EN 	= '1') else
--							prbs_data		when (PRBS_EN 	= '1') else
--							FIFO_DATA1	   when (ADC_FIFO_EMPTY = '0') else
--							x"BCFB";
--
--	TX_DATA2		<=		x"BCFB"			when (Stream_EN 	= '0') else
--							 counter			when (CNT_EN 	= '1') else
--							prbs_data		when (PRBS_EN 	= '1') else
--							FIFO_DATA2	   when (ADC_FIFO_EMPTY = '0') else
--							x"BCFB";
--							
--	TX_DATA3		<=		x"BCFB"			when (Stream_EN 	= '0') else
--							 counter			when (CNT_EN 	= '1') else
--							prbs_data		when (PRBS_EN 	= '1') else
--							FIFO_DATA3	   when (ADC_FIFO_EMPTY = '0') else
--							x"BCFB";		
--							
--	TX_DATA4		<=		x"BCFB"			when (Stream_EN 	= '0') else
--							 counter			when (CNT_EN 	= '1') else
--							prbs_data		when (PRBS_EN 	= '1') else
--							FIFO_DATA4	   when (ADC_FIFO_EMPTY = '0') else
--							x"BCFB";
	
	
	
	
-------------------------------------------------------------------
	-- Ethan
	-- Using the ACK signal btw FE & BE
	
--process(cal_clk_125MHz) 
--begin
--	if  (rst = '1') then
--		tx_ctrlenable 		<= b"01";
--		TX_DATA1				<= x"36BC";
--		tx_ctrlenable_counter <= x"00000";
--	elsif cal_clk_125MHz'event and cal_clk_125MHz = '1' then
--		if ((byteordering_flag = '1') and (wordalignment_flag = '1')) then
--			tx_ctrlenable 		<= b"00";
--			TX_DATA1				<= TX_DATA1 + 1;
--			tx_ctrlenable_counter <= tx_ctrlenable_counter;
--		else
--			tx_ctrlenable		<= b"01";
--			TX_DATA1				<= x"36BC";
--			tx_ctrlenable_counter <= tx_ctrlenable_counter + 1;
--		end if;
--	end if;
--end process;


-------------------------------------------------------------------
-- State machine that implements a set of dummy data from FE
-------------------------------------------------------------------
	process(tx_clkout(0))
	begin
		if (rst = '1') then
			tx_ctrlenable_1 <= b"01";						-- Signifying this is control word
			time_stamp_1 <= x"0001";
			tx_ctrlenable_counter_1 <= x"00000";		-- Counter to record how many sync signals has been sent
			idle_counter_1 <= x"000";						-- Counter to generate the idle cycle when one set of data finished sending
			TX_DATA1	<= x"36BC";							-- Sync signal
			state_1 <= SYNC;									-- State machine always starts from SYNC stage after reset
		elsif tx_clkout(0)'event and tx_clkout(0) = '1' then
			case state_1 is
				when SYNC =>
					tx_ctrlenable_counter_1 <= tx_ctrlenable_counter_1 + 1;
					time_stamp_1 <= time_stamp_1;
					idle_counter_1 <= x"000";
					tx_ctrlenable_1 <= b"01";
					TX_DATA1 <= x"36BC";
					if (tx_ctrlenable_counter_1 <= x"AFFFF") then
						state_1 <= SYNC;
					else
						state_1 <= HEADER;
					end if;
					
				when HEADER =>
					tx_ctrlenable_counter_1 <= x"00001";
					time_stamp_1 <= time_stamp_1;
					idle_counter_1 <= x"000";
					tx_ctrlenable_1 <= b"00";
					TX_DATA1 <= x"DEAD";
					state_1 <= TIMESTAMP;
				
				when TIMESTAMP =>
					tx_ctrlenable_counter_1 <= x"00001";
					time_stamp_1 <= time_stamp_1 + 1;
					idle_counter_1 <= x"000";
					tx_ctrlenable_1 <= b"00";
					TX_DATA1 <= time_stamp_1;
					state_1 <= PAYLOAD;
					
				when PAYLOAD =>
					tx_ctrlenable_counter_1 <= tx_ctrlenable_counter_1 + b"1";
					time_stamp_1 <= time_stamp_1;
					idle_counter_1 <= x"000";
					tx_ctrlenable_1 <= b"00";
					TX_DATA1 <= tx_ctrlenable_counter_1(15 downto 0);
					if (tx_ctrlenable_counter_1 < 126) then
						state_1 <= PAYLOAD;
					else
						state_1 <= TAIL;
					end if;
					
				when TAIL =>
					tx_ctrlenable_counter_1 <= x"00000";
					time_stamp_1 <= time_stamp_1;
					idle_counter_1 <= x"000";
					tx_ctrlenable_1 <= b"00";
					TX_DATA1 <= x"BEEF";
					state_1 <= IDLE;
					
				when IDLE =>
					tx_ctrlenable_counter_1 <= x"00000";
					time_stamp_1 <= time_stamp_1;
					idle_counter_1 <= idle_counter_1 + 1;
					tx_ctrlenable_1 <= b"00";
					TX_DATA1 <= x"D11D";
					if (idle_counter_1 < 500) then
						state_1 <= IDLE;
					else
						state_1 <= HEADER;
					end if;
					
				when others =>
					tx_ctrlenable_counter_1 <= x"00000";
					time_stamp_1 <= time_stamp_1;
					idle_counter_1 <= x"000";
					tx_ctrlenable_1 <= b"00";
					TX_DATA1 <= x"D11D";
					state_1 <= IDLE;
					
			end case;
		end if;
	end process;

	
	process(tx_clkout(1))
	begin
		if (rst = '1') then
			tx_ctrlenable_2 <= b"01";						-- Signifying this is control word
			time_stamp_2 <= x"0001";
			tx_ctrlenable_counter_2 <= x"00000";		-- Counter to record how many sync signals has been sent
			idle_counter_2 <= x"000";						-- Counter to generate the idle cycle when one set of data finished sending
			TX_DATA2	<= x"36BC";							-- Sync signal
			state_2 <= SYNC;									-- State machine always starts from SYNC stage after reset
		elsif tx_clkout(1)'event and tx_clkout(1) = '1' then
			case state_2 is
				when SYNC =>
					tx_ctrlenable_counter_2 <= tx_ctrlenable_counter_2 + 1;
					time_stamp_2 <= time_stamp_2;
					idle_counter_2 <= x"000";
					tx_ctrlenable_2 <= b"01";
					TX_DATA2 <= x"36BC";
					if (tx_ctrlenable_counter_2 <= x"AFFFF") then
						state_2 <= SYNC;
					else
						state_2 <= HEADER;
					end if;
					
				when HEADER =>
					tx_ctrlenable_counter_2 <= x"00001";
					time_stamp_2 <= time_stamp_2;
					idle_counter_2 <= x"000";
					tx_ctrlenable_2 <= b"00";
					TX_DATA2 <= x"DEAD";
					state_2 <= TIMESTAMP;
				
				when TIMESTAMP =>
					tx_ctrlenable_counter_2 <= x"00001";
					time_stamp_2 <= time_stamp_2 + 1;
					idle_counter_2 <= x"000";
					tx_ctrlenable_2 <= b"00";
					TX_DATA2 <= time_stamp_2;
					state_2 <= PAYLOAD;
					
				when PAYLOAD =>
					tx_ctrlenable_counter_2 <= tx_ctrlenable_counter_2 + b"1";
					time_stamp_2 <= time_stamp_2;
					idle_counter_2 <= x"000";
					tx_ctrlenable_2 <= b"00";
					TX_DATA2 <= tx_ctrlenable_counter_2(15 downto 0);
					if (tx_ctrlenable_counter_2 < 126) then
						state_2 <= PAYLOAD;
					else
						state_2 <= TAIL;
					end if;
					
				when TAIL =>
					tx_ctrlenable_counter_2 <= x"00000";
					time_stamp_2 <= time_stamp_2;
					idle_counter_2 <= x"000";
					tx_ctrlenable_2 <= b"00";
					TX_DATA2 <= x"BEEF";
					state_2 <= IDLE;
					
				when IDLE =>
					tx_ctrlenable_counter_2 <= x"00000";
					time_stamp_2 <= time_stamp_2;
					idle_counter_2 <= idle_counter_2 + 1;
					tx_ctrlenable_2 <= b"00";
					TX_DATA2 <= x"D22D";
					if (idle_counter_2 < 500) then
						state_2 <= IDLE;
					else
						state_2 <= HEADER;
					end if;
					
				when others =>
					tx_ctrlenable_counter_2 <= x"00000";
					time_stamp_2 <= time_stamp_2;
					idle_counter_2 <= x"000";
					tx_ctrlenable_2 <= b"00";
					TX_DATA2 <= x"D22D";
					state_2 <= IDLE;
					
			end case;
		end if;
	end process;
	

	process(tx_clkout(2))
	begin
		if (rst = '1') then
			tx_ctrlenable_3 <= b"01";						-- Signifying this is control word
			time_stamp_3 <= x"0001";
			tx_ctrlenable_counter_3 <= x"00000";		-- Counter to record how many sync signals has been sent
			idle_counter_3 <= x"000";						-- Counter to generate the idle cycle when one set of data finished sending
			TX_DATA3	<= x"36BC";							-- Sync signal
			state_3 <= SYNC;									-- State machine always starts from SYNC stage after reset
		elsif tx_clkout(2)'event and tx_clkout(2) = '1' then
			case state_3 is
				when SYNC =>
					tx_ctrlenable_counter_3 <= tx_ctrlenable_counter_3 + 1;
					time_stamp_3 <= time_stamp_3;
					idle_counter_3 <= x"000";
					tx_ctrlenable_3 <= b"01";
					TX_DATA3 <= x"36BC";
					if (tx_ctrlenable_counter_3 <= x"AFFFF") then
						state_3 <= SYNC;
					else
						state_3 <= HEADER;
					end if;
					
				when HEADER =>
					tx_ctrlenable_counter_3 <= x"00001";
					time_stamp_3 <= time_stamp_3;
					idle_counter_3 <= x"000";
					tx_ctrlenable_3 <= b"00";
					TX_DATA3 <= x"DEAD";
					state_3 <= TIMESTAMP;
				
				when TIMESTAMP =>
					tx_ctrlenable_counter_3 <= x"00001";
					time_stamp_3 <= time_stamp_3 + 1;
					idle_counter_3 <= x"000";
					tx_ctrlenable_3 <= b"00";
					TX_DATA3 <= time_stamp_3;
					state_3 <= PAYLOAD;
					
				when PAYLOAD =>
					tx_ctrlenable_counter_3 <= tx_ctrlenable_counter_3 + b"1";
					time_stamp_3 <= time_stamp_3;
					idle_counter_3 <= x"000";
					tx_ctrlenable_3 <= b"00";
					TX_DATA3 <= tx_ctrlenable_counter_3(15 downto 0);
					if (tx_ctrlenable_counter_3 < 126) then
						state_3 <= PAYLOAD;
					else
						state_3 <= TAIL;
					end if;
					
				when TAIL =>
					tx_ctrlenable_counter_3 <= x"00000";
					time_stamp_3 <= time_stamp_3;
					idle_counter_3 <= x"000";
					tx_ctrlenable_3 <= b"00";
					TX_DATA3 <= x"BEEF";
					state_3 <= IDLE;
					
				when IDLE =>
					tx_ctrlenable_counter_3 <= x"00000";
					time_stamp_3 <= time_stamp_3;
					idle_counter_3 <= idle_counter_3 + 1;
					tx_ctrlenable_3 <= b"00";
					TX_DATA3 <= x"D33D";
					if (idle_counter_3 < 500) then
						state_3 <= IDLE;
					else
						state_3 <= HEADER;
					end if;
					
				when others =>
					tx_ctrlenable_counter_3 <= x"00000";
					time_stamp_3 <= time_stamp_3;
					idle_counter_3 <= x"000";
					tx_ctrlenable_3 <= b"00";
					TX_DATA3 <= x"D33D";
					state_3 <= IDLE;
					
			end case;
		end if;
	end process;

	process(tx_clkout(3))
	begin
		if (rst = '1') then
			tx_ctrlenable_4 <= b"01";						-- Signifying this is control word
			time_stamp_4 <= x"0001";
			tx_ctrlenable_counter_4 <= x"00000";		-- Counter to record how many sync signals has been sent
			idle_counter_4 <= x"000";						-- Counter to generate the idle cycle when one set of data finished sending
			TX_DATA4	<= x"36BC";							-- Sync signal
			state_4 <= SYNC;									-- State machine always starts from SYNC stage after reset
		elsif tx_clkout(3)'event and tx_clkout(3) = '1' then
			case state_4 is
				when SYNC =>
					tx_ctrlenable_counter_4 <= tx_ctrlenable_counter_4 + 1;
					time_stamp_4 <= time_stamp_4;
					idle_counter_4 <= x"000";
					tx_ctrlenable_4 <= b"01";
					TX_DATA4 <= x"36BC";
					if (tx_ctrlenable_counter_4 <= x"AFFFF") then
						state_4 <= SYNC;
					else
						state_4 <= HEADER;
					end if;
					
				when HEADER =>
					tx_ctrlenable_counter_4 <= x"00001";
					time_stamp_4 <= time_stamp_4;
					idle_counter_4 <= x"000";
					tx_ctrlenable_4 <= b"00";
					TX_DATA4 <= x"DEAD";
					state_4 <= TIMESTAMP;
				
				when TIMESTAMP =>
					tx_ctrlenable_counter_4 <= x"00001";
					time_stamp_4 <= time_stamp_4 + 1;
					idle_counter_4 <= x"000";
					tx_ctrlenable_4 <= b"00";
					TX_DATA4 <= time_stamp_4;
					state_4 <= PAYLOAD;
					
				when PAYLOAD =>
					tx_ctrlenable_counter_4 <= tx_ctrlenable_counter_4 + b"1";
					time_stamp_4 <= time_stamp_4;
					idle_counter_4 <= x"000";
					tx_ctrlenable_4 <= b"00";
					TX_DATA4 <= tx_ctrlenable_counter_4(15 downto 0);
					if (tx_ctrlenable_counter_4 < 126) then
						state_4 <= PAYLOAD;
					else
						state_4 <= TAIL;
					end if;
					
				when TAIL =>
					tx_ctrlenable_counter_4 <= x"00000";
					time_stamp_4 <= time_stamp_4;
					idle_counter_4 <= x"000";
					tx_ctrlenable_4 <= b"00";
					TX_DATA4 <= x"BEEF";
					state_4 <= IDLE;
					
				when IDLE =>
					tx_ctrlenable_counter_4 <= x"00000";
					time_stamp_4 <= time_stamp_4;
					idle_counter_4 <= idle_counter_4 + 1;
					tx_ctrlenable_4 <= b"00";
					TX_DATA4 <= x"D44D";
					if (idle_counter_4 < 500) then
						state_4 <= IDLE;
					else
						state_4 <= HEADER;
					end if;
					
				when others =>
					tx_ctrlenable_counter_4 <= x"00000";
					time_stamp_4 <= time_stamp_4;
					idle_counter_4 <= x"000";
					tx_ctrlenable_4 <= b"00";
					TX_DATA4 <= x"D44D";
					state_4 <= IDLE;
					
			end case;
		end if;
	end process;
	
-------------------------------------------------------------------	
	
--	TX_DATA1		<= 	x"36BC";
--	TX_DATA2		<= 	x"37BC";
--	TX_DATA3		<= 	x"38BC";
--	TX_DATA4		<= 	x"39BC";
-----------------------------------------------------------------



ADC_FIFO_inst1 : ADC_FIFO
	PORT MAP
	(
		data		=> LANE1_DATA,
		wrclk		=>	DATA_CLK,
		wrreq		=> DATA_VALID and Stream_EN,
		rdclk		=> tx_clkout(0),
		rdreq		=> '1',
		q			=> FIFO_DATA1,
		rdempty	=> ADC_FIFO_EMPTY,
		wrfull	=> OPEN
	);		
		
			
	ADC_FIFO_inst2 : ADC_FIFO
	PORT MAP
	(
		data		=> LANE2_DATA,
		wrclk		=>	DATA_CLK,
		wrreq		=> DATA_VALID and Stream_EN,
		rdclk		=> tx_clkout(0),
		rdreq		=> '1',
		q			=> FIFO_DATA2,
		rdempty	=> OPEN,
		wrfull	=> OPEN
	);		
		
	ADC_FIFO_inst3 : ADC_FIFO
	PORT MAP
	(
		data		=> LANE3_DATA,
		wrclk		=>	DATA_CLK,
		wrreq		=> DATA_VALID and Stream_EN,
		rdclk		=> tx_clkout(0),
		rdreq		=> '1',
		q			=> FIFO_DATA3,
		rdempty	=> OPEN,
		wrfull	=> OPEN
	);		
	
	ADC_FIFO_inst4 : ADC_FIFO
	PORT MAP
	(
		data		=> LANE4_DATA,
		wrclk		=>	DATA_CLK,
		wrreq		=> DATA_VALID and Stream_EN,
		rdclk		=> tx_clkout(0),
		rdreq		=> '1',
		q			=> FIFO_DATA4,
		rdempty	=> OPEN,
		wrfull	=> OPEN
	);			

process(tx_clkout(0),rst) 
begin
	if  (rst = '1') then
		counter 		<= (others => '0');
		prbs_data	<= (others => '0');
	elsif tx_clkout(0)'event and tx_clkout(0) = '1' then
			counter		<= counter + 1;
			prbs_data	<= PRBS_GEN(prbs_data);
	end if;
end process;
	
end LBNE_HSTX_arch;
