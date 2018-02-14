--*********************************************************
--* FILE  : LA_fifo_cntl.VHD
--* Author: Jack Fried
--*
--* Last Modified: 03/07/2011
--*  
--* Description: LA_CLK GEN TEST
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
USE work.LbnePkg.all;

--  Entity Declaration

ENTITY LBNE_ASIC_DATA_V4 IS

	PORT
	(	
		clk_200Mhz    	: IN STD_LOGIC;				-- clock
		clk_sys	    	: IN STD_LOGIC;				-- system clock 
		sys_rst     	: IN STD_LOGIC;				-- reset		
		CHN_select		: IN STD_LOGIC_VECTOR(7 downto 0); 
		LATCH_LOC		: IN STD_LOGIC_VECTOR(3 downto 0); 		
		ADC_FD			: IN STD_LOGIC_VECTOR(1 downto 0);	-- LVDS
		ADC_FE			: IN STD_LOGIC;	-- LVDS
		ADC_TST_PATT_EN: IN STD_LOGIC; 
		ADC_TST_PATT	: IN STD_LOGIC_VECTOR(11 downto 0); 
		ADC_SYNC		 	: OUT STD_LOGIC;							-- LATCH FIFO DATA IN TO SHIFT REGISTER	
		ADC_header_out	: OUT STD_LOGIC_VECTOR(7 downto 0);
		HS_DATA_LATCH 	: OUT STD_LOGIC;
		DATA_OUT	 		: OUT STD_LOGIC_VECTOR(15 downto 0);
		ADCData        : OUT ADC_array(0 to 15)	
	);
	
	END LBNE_ASIC_DATA_V4;

ARCHITECTURE behavior OF LBNE_ASIC_DATA_V4 IS

  
  type state_type is (S_IDLE,  S_READ_SDATA);
  signal state: state_type;

 
 signal ADC_D_ASIC	: ADC_array(0 to 15);
  
 signal EMPTY  		: STD_LOGIC;
 signal EMPTY1  		: STD_LOGIC;  
 signal EMPTY2  		: STD_LOGIC;  
 signal FF_SYNC 		: STD_LOGIC;
 signal FF_EMPTY 		: STD_LOGIC; 
 
 
 signal SHIFT_CNT		: STD_LOGIC_VECTOR(7 downto 0);   
 signal WRD_CNT		: STD_LOGIC_VECTOR(7 downto 0);   
 signal BIT_CNT	 	: STD_LOGIC_VECTOR(7 downto 0);
 signal ADC_CNT		: INTEGER RANGE 0 TO 15; 

 signal sys_sync		: STD_LOGIC;  
 signal asic_empty_rst 		: STD_LOGIC;  
 signal asic_empty_rst_s 	: STD_LOGIC;  
 
 
 
 
 signal SR_A_ADC1		: STD_LOGIC_VECTOR(99 downto 0); 
 signal SR_B_ADC1		: STD_LOGIC_VECTOR(99 downto 0); 
 signal SR_A_ADC1_L	: STD_LOGIC_VECTOR(99 downto 0); 
 signal SR_B_ADC1_L	: STD_LOGIC_VECTOR(99 downto 0); 
 

 signal ADC_header	: STD_LOGIC_VECTOR(7 downto 0); 


 
 signal SHIFT_latch			: STD_LOGIC;  
 signal SHIFT_latch_req		: STD_LOGIC;
 signal SHIFT_latch_ack		: STD_LOGIC;
 signal SHIFT_latch_req_s	: STD_LOGIC;
 signal Data_Latch			: STD_LOGIC;
 
 signal CHN_select_s	: STD_LOGIC_VECTOR(3 downto 0); 

 
begin


		ADC_SYNC			<= FF_SYNC;
		HS_DATA_LATCH 	<= Data_Latch;
		FF_EMPTY			<= ADC_FE;
					
  process(clk_sys) 	
  begin
	if (clk_sys'event AND clk_sys = '1') then		
			CHN_select_s	<= CHN_select(3 downto 0);
	end if;
end process;	
					
					
		DATA_OUT	  	  <= x"0" & ADC_D_ASIC(0)   			when (CHN_select_s = x"0") else 
							  x"1" & ADC_D_ASIC(1)   			when (CHN_select_s = x"1") else
							  x"2" & ADC_D_ASIC(2)   			when (CHN_select_s = x"2") else 
							  x"3" & ADC_D_ASIC(3)   			when (CHN_select_s = x"3") else
							  x"4" & ADC_D_ASIC(4)   			when (CHN_select_s = x"4") else 
							  x"5" & ADC_D_ASIC(5)   			when (CHN_select_s = x"5") else
							  x"6" & ADC_D_ASIC(6)   			when (CHN_select_s = x"6") else 
							  x"7" & ADC_D_ASIC(7)   			when (CHN_select_s = x"7") else
							  x"8" & ADC_D_ASIC(8)   			when (CHN_select_s = x"8") else 
							  x"9" & ADC_D_ASIC(9) 			   when (CHN_select_s = x"9") else
							  x"a" & ADC_D_ASIC(10)  			when (CHN_select_s = x"a") else 
							  x"b" & ADC_D_ASIC(11)  			when (CHN_select_s = x"b") else						 
							  x"c" & ADC_D_ASIC(12)  			when (CHN_select_s = x"c") else 
							  x"d" & ADC_D_ASIC(13)  			when (CHN_select_s = x"d") else						 
							  x"e" & ADC_D_ASIC(14)  			when (CHN_select_s = x"e") else 
							  x"f" & ADC_D_ASIC(15);  							
							  							  				
									
  process(clk_200Mhz) 
  begin
	if (clk_200Mhz'event AND clk_200Mhz = '1') then		
		EMPTY1			<= FF_EMPTY;
		EMPTY2		   <= EMPTY1;
		EMPTY			   <= EMPTY2;
	end if;
end process;	
			
	
process(clk_sys) 
begin
	if clk_sys'event and clk_sys = '1' then	
			asic_empty_rst_s <= asic_empty_rst;	
			ADC_header_out	  <= ADC_header;
	end if;	
end process;	
	

	
 process(clk_sys,sys_rst) 
begin

	if clk_sys'event and clk_sys = '1' then
		if  (sys_rst = '1') then
			ADC_D_ASIC			<= ((others=> (others=>'0')));
			Data_Latch			<= '0';
			SHIFT_latch_ack	<= '1';	
		else
			Data_Latch			<= '0';
			SHIFT_latch_ack	<= '0';
			if(SHIFT_latch_req_s = '1')then
				SHIFT_latch_ack	<= '1';					
				if(ADC_TST_PATT_EN = '0') then 
					ADC_D_ASIC(0) 	<= SR_A_ADC1_L(95 downto 84);
					ADC_D_ASIC(1)  <= SR_A_ADC1_L(83 downto 72);
					ADC_D_ASIC(2) 	<= SR_A_ADC1_L(71 downto 60);
					ADC_D_ASIC(3)  <= SR_A_ADC1_L(59 downto 48);
					ADC_D_ASIC(4) 	<= SR_A_ADC1_L(47 downto 36);
					ADC_D_ASIC(5)  <= SR_A_ADC1_L(35 downto 24);
					ADC_D_ASIC(6) 	<= SR_A_ADC1_L(23 downto 12);
					ADC_D_ASIC(7)  <= SR_A_ADC1_L(11 downto 0);
					ADC_D_ASIC(8) 	<= SR_B_ADC1_L(95 downto 84);
					ADC_D_ASIC(9) 	<= SR_B_ADC1_L(83 downto 72);
					ADC_D_ASIC(10) <= SR_B_ADC1_L(71 downto 60);
					ADC_D_ASIC(11) <= SR_B_ADC1_L(59 downto 48);
					ADC_D_ASIC(12) <= SR_B_ADC1_L(47 downto 36);
					ADC_D_ASIC(13) <= SR_B_ADC1_L(35 downto 24);				
					ADC_D_ASIC(14) <= SR_B_ADC1_L(23 downto 12);
					ADC_D_ASIC(15) <= SR_B_ADC1_L(11 downto 0);		
					ADC_header(3 downto 0)	<= SR_A_ADC1(99 downto 96);
					ADC_header(7 downto 4) 	<= SR_B_ADC1(99 downto 96);					
							
				else
					ADC_D_ASIC(0) 	 	  <= ADC_TST_PATT;
					ADC_D_ASIC(1) 	 	  <= ADC_TST_PATT;
					ADC_D_ASIC(2) 	 	  <= ADC_TST_PATT;
					ADC_D_ASIC(3) 	 	  <= ADC_TST_PATT;
					ADC_D_ASIC(4) 	 	  <= ADC_TST_PATT;
					ADC_D_ASIC(5) 	 	  <= ADC_TST_PATT;
					ADC_D_ASIC(6) 	 	  <= ADC_TST_PATT;
					ADC_D_ASIC(7) 	 	  <= ADC_TST_PATT;
					ADC_D_ASIC(8) 	 	  <= ADC_TST_PATT;
					ADC_D_ASIC(9) 	 	  <= ADC_TST_PATT;
					ADC_D_ASIC(10)  	  <= ADC_TST_PATT;
					ADC_D_ASIC(11)  	  <= ADC_TST_PATT;
					ADC_D_ASIC(12)  	  <= ADC_TST_PATT;
					ADC_D_ASIC(13)  	  <= ADC_TST_PATT;
					ADC_D_ASIC(14)  	  <= ADC_TST_PATT;
					ADC_D_ASIC(15)  	  <= ADC_TST_PATT;

				end if;	
			end if;		
			if( SHIFT_latch_ack = '1') then
				Data_Latch		<= '1';
				ADC_CNT			<= 0;
				ADCData			<= ADC_D_ASIC;
			end if;
		end if;
	end if;	
end process;



 process(SHIFT_latch,sys_rst,SHIFT_latch_ack) 
begin
	if  (sys_rst = '1') or (SHIFT_latch_ack = '1') then	
		SHIFT_latch_req	<= '0';
	elsif SHIFT_latch'event and SHIFT_latch = '1' then
		SHIFT_latch_req	<= '1';
	end if;
end process;

		
process(clk_sys,sys_rst,SHIFT_latch_ack) 
begin
	if  (sys_rst = '1') or (SHIFT_latch_ack = '1') then	
		SHIFT_latch_req_s	<= '0';
	elsif clk_sys'event and clk_sys = '0' then
		SHIFT_latch_req_s	<= SHIFT_latch_req;
	end if;
end process;




process(clk_200Mhz,sys_rst) 
begin
	if  (sys_rst = '1') then
		SR_A_ADC1  <=(others => '0');
		SR_B_ADC1  <=(others => '0');
	elsif clk_200Mhz'event and clk_200Mhz = '1' then
		SR_A_ADC1	<= SR_A_ADC1(98 downto 0) & ADC_FD(1);
		SR_B_ADC1	<= SR_B_ADC1(98 downto 0) & ADC_FD(0);		
	end if;
end process;


 process(clk_200Mhz,sys_rst) 
begin
	if  (sys_rst = '1') then
		SHIFT_CNT	<= x"00";
		SHIFT_latch	<= '0';
	elsif clk_200Mhz'event and clk_200Mhz = '1' then
		SHIFT_latch	<= '0';
			
		if(SHIFT_CNT <= x"63")then
			SHIFT_CNT	<= SHIFT_CNT + 1;
		end if;
		if(SHIFT_CNT = x"63")then
			SR_A_ADC1_L	<= SR_A_ADC1;
			SR_B_ADC1_L	<= SR_B_ADC1;		
			SHIFT_latch	<= '1';
		end if;
		if(sys_sync = '1') then
			SHIFT_CNT	<= x"00";
		end if;
	end if;
end process;



  process(clk_200Mhz,sys_rst) 
  begin
	 if (sys_rst = '1') then
	 
		FF_SYNC		<= '0';
		sys_sync		<= '0';
		BIT_CNT		<= x"00";
		state 		<= S_idle;	
     elsif (clk_200Mhz'event AND clk_200Mhz = '1') then
			CASE state IS
			when S_IDLE =>	
				FF_SYNC		<= '0';
				BIT_CNT		<= x"00";
				sys_sync		<= '0';
				if (EMPTY = '1') and (EMPTY2 = '0')  then
					  FF_SYNC		<= '1';  
					  state 			<= S_READ_SDATA;
				end if;		  
		   when S_READ_SDATA =>	
					BIT_CNT		<= BIT_CNT + 1;
					FF_SYNC		<= '1';
					sys_sync		<= '0';
					if (BIT_CNT >= x"30") then
						FF_SYNC		<= '0';
					else
						FF_SYNC		<= '1';
					end if;
					if(BIT_CNT = LATCH_LOC) then
						sys_sync		<= '1';
					end if;
					if (BIT_CNT >= x"63")  then
						if (EMPTY = '0')  then
							FF_SYNC		<= '1';  
							BIT_CNT		<= x"00";
							state 		<= S_READ_SDATA;
						else
							state 		<= S_idle;
						end if;
					end if;		
			 when others =>		
					state <= S_idle;		
			 end case; 
	 end if;
end process;
END behavior;

	
	