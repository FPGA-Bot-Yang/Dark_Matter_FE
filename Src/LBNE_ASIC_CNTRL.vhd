--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: LBNE_ASIC_CNTRL.VHD          
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 10/02/2014
--////  Description:  LBNE_ASIC_CNTRL
--////					
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2014 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;


--  Entity Declaration

ENTITY LBNE_ASIC_CNTRL IS
 generic ( SPI_SPD_CNTL      : integer range 0 to 255  := 64;
			  ADC_WR_ADDR    	  : STD_LOGIC_VECTOR(7 downto 0) := x"00";  
			  ADC_RD_BK_ADDR    : STD_LOGIC_VECTOR(7 downto 0) := x"28";  			  
			  FE_WR_ADDR    	  : STD_LOGIC_VECTOR(7 downto 0) := x"00";  			  
			  FE_RD_BK_ADDR     : STD_LOGIC_VECTOR(7 downto 0) := x"28");
			  
	PORT
	(

		sys_rst     	: IN STD_LOGIC;				-- reset		
		clk_sys	    	: IN STD_LOGIC;				-- system clock 

		
		ADC_ASIC_RESET	: IN STD_LOGIC;				-- reset		
		FE_ASIC_RESET	: IN STD_LOGIC;				-- reset		
		WRITE_ADC_SPI	: IN STD_LOGIC;		
		WRITE_FE_SPI	: IN STD_LOGIC;
		
		ADC_FIFO_TM		: IN STD_LOGIC;			
		
		DPM_WREN		 	: OUT  STD_LOGIC;		
		DPM_ADDR		 	: OUT  STD_LOGIC_VECTOR(7 downto 0);		
		DPM_D			 	: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		DPM_Q				: IN STD_LOGIC_VECTOR(31 downto 0);		

		
		
		ASIC_ADC_CS				: OUT STD_LOGIC_VECTOR(7 downto 0); 
		ASIC_ADC_SDO_L			: IN STD_LOGIC;	
		ASIC_ADC_SDI_L			: OUT STD_LOGIC;		
		ASIC_ADC_CLK_STRB_L	: OUT STD_LOGIC;	
		ASIC_ADC_SDO_R			: IN STD_LOGIC;			
		ASIC_ADC_SDI_R			: OUT STD_LOGIC;
		ASIC_ADC_CLK_STRB_R	: OUT STD_LOGIC;	
	
		ASIC_FE_CS_L			: OUT STD_LOGIC;	
		ASIC_FE_RST_L			: OUT STD_LOGIC;	
		ASIC_FE_CK_L			: OUT STD_LOGIC;	
		ASIC_FE_SDI_L			: OUT STD_LOGIC;	
		ASIC_FE_SDO_L			: IN  STD_LOGIC;
		ASIC_FE_CS_R			: OUT STD_LOGIC;	
		ASIC_FE_RST_R			: OUT STD_LOGIC;	
		ASIC_FE_CK_R			: OUT STD_LOGIC;
		ASIC_FE_SDI_R			: OUT STD_LOGIC;	
		ASIC_FE_SDO_R			: IN  STD_LOGIC	
		
	);
	
	END LBNE_ASIC_CNTRL;

ARCHITECTURE behavior OF LBNE_ASIC_CNTRL IS

 
  type state_type is (S_IDLE,
							S_ADC_ASIC_RESET ,	
							S_FE_ASIC_RESET	 ,
							S_WRITE_ADC_SPI_START,	
							S_WRITE_ADC_SPI_next_bit,	
							S_WRITE_ADC_SPI_CLK_HIGH,					
							S_WRITE_ADC_SPI_CLK_LOW,					
							S_WRITE_ADC_SPI_DONE,			
							S_WRITE_FE_SPI_START,	
							S_WRITE_FE_SPI_next_bit,	
							S_WRITE_FE_SPI_CLK_HIGH,					
							S_WRITE_FE_SPI_CLK_LOW,					
							S_WRITE_FE_SPI_DONE	);
  signal state: state_type;


	signal counter		: STD_LOGIC_VECTOR(15 downto 0);  
	signal SPI_DATA_L	: STD_LOGIC_VECTOR(15 downto 0);  
   signal SPI_DATA_R	: STD_LOGIC_VECTOR(15 downto 0);  
  	signal bit_cnt		: STD_LOGIC_VECTOR(15 downto 0);  
	signal index		: INTEGER RANGE 0 TO 31; 
	signal DPM_ADDR_S	: sTD_LOGIC_VECTOR(7 downto 0);	
	signal DPM_RB_ADDR: sTD_LOGIC_VECTOR(7 downto 0);			
	signal CS			: STD_LOGIC;	
	signal SDI_L		: STD_LOGIC;					
	signal SDI_R		: STD_LOGIC;	  
	signal ADC_CLK		: STD_LOGIC;	  
	signal SPI_RB_DATA: STD_LOGIC_VECTOR(31 downto 0);  
	signal DP_ADDR_SEL: STD_LOGIC;	
	signal FE_RST		: STD_LOGIC;	
	signal FE_CS		: STD_LOGIC;	
	signal FE_CLK		: STD_LOGIC;	
	signal FE_SDI_L	: STD_LOGIC;	
	signal FE_SDI_R	: STD_LOGIC;	 

begin


		ASIC_ADC_CS(0)			<= CS;
		ASIC_ADC_CS(1)			<= CS;
		ASIC_ADC_CS(2)			<= CS;
		ASIC_ADC_CS(3)			<= CS;
		ASIC_ADC_CS(4)			<= CS;
		ASIC_ADC_CS(5)			<= CS;
		ASIC_ADC_CS(6)			<= CS;		
		ASIC_ADC_CS(7)			<= CS;
		ASIC_ADC_SDI_L			<=	SDI_L;
		ASIC_ADC_SDI_R			<= SDI_R;
		ASIC_ADC_CLK_STRB_R	<= ADC_CLK;
		ASIC_ADC_CLK_STRB_L	<= ADC_CLK;

		ASIC_FE_RST_L			<=	FE_RST;
		ASIC_FE_RST_R			<=	FE_RST;			
		ASIC_FE_CS_L			<=	FE_CS;
		ASIC_FE_CS_R			<=	FE_CS;
		ASIC_FE_CK_L			<= FE_CLK;
		ASIC_FE_CK_R			<= FE_CLK;
		ASIC_FE_SDI_L			<= FE_SDI_L;
		ASIC_FE_SDI_R			<= FE_SDI_R;	

		DPM_ADDR			<= DPM_ADDR_S when (DP_ADDR_SEL = '0') else DPM_RB_ADDR;

  process(clk_sys,sys_rst) 
  begin
	 if (sys_rst = '1') then
		CS				<=	'0';
		SDI_L			<= '0';
		SDI_R			<= '0';
		ADC_CLK		<= '0';
		FE_RST		<= '1';
		FE_CS			<= '0';
		FE_CLK		<= '0';	
		FE_SDI_L		<= '0';
		FE_SDI_R		<= '0';
		index			<= 0;
		DPM_WREN		<= '0';
		DP_ADDR_SEL	<= '0';
		DPM_ADDR_S	<= (others => '0');
		DPM_RB_ADDR	<= (others => '0');
		DPM_D			<= (others => '0');
		counter		<= X"0000";
		bit_cnt		<= X"0000";
		DP_ADDR_SEL	<= '0';		
		state 		<= S_idle;	
     elsif (clk_sys'event AND clk_sys = '1') then
			CASE state IS
			when S_IDLE =>	
				CS				<=	'0';
				SDI_L			<= '0';
				SDI_R			<= '0';
				ADC_CLK		<= ADC_FIFO_TM;
				FE_RST		<= '1';
				FE_CS			<= '0';
				FE_CLK		<= '0';	
				FE_SDI_L		<= '0';
				FE_SDI_R		<= '0';			
				counter		<= X"0000";
				index			<= 0;
				bit_cnt		<= X"0000";
				DPM_WREN		<= '0';
				DP_ADDR_SEL	<= '0';
		--		DPM_RB_ADDR	<= SPI_RD_BK_ADDR(6 DOWNTO 0);					
				DPM_ADDR_S	<= (others => '0');
			--	DPM_D			<= (others => '0');
				bit_cnt		<= (others => '0');
				if (ADC_ASIC_RESET = '1')  then					
					ADC_CLK		<= '0';
					FE_RST		<= not FE_ASIC_RESET;
					state 		<= S_ADC_ASIC_RESET;	
				elsif (FE_ASIC_RESET = '1')  then
					state 		<= S_FE_ASIC_RESET;	
				elsif (WRITE_ADC_SPI = '1')  then
					ADC_CLK		<= '0';
					DPM_ADDR_S 	<= ADC_WR_ADDR(7 DOWNTO 0);	    	
					DPM_RB_ADDR	<= ADC_RD_BK_ADDR(7 DOWNTO 0);   			  	
					state 		<= S_WRITE_ADC_SPI_START;
				elsif (WRITE_FE_SPI = '1')  then
					DPM_ADDR_S 	<=	FE_WR_ADDR(7 DOWNTO 0);	    	
					DPM_RB_ADDR	<= FE_RD_BK_ADDR(7 DOWNTO 0); 
					state 		<= S_WRITE_FE_SPI_START;		
				end if;	
			when S_ADC_ASIC_RESET =>	
				counter		<= counter + 1;
				if   (counter = 1)  then
					ADC_CLK		<= '1';
				elsif(counter = 2)  then
					CS				<=	'1';
				elsif(counter = 5)  then
					CS				<=	'0';
				elsif(counter = 10)  then
					CS				<=	'0';
					ADC_CLK		<= '0';
				elsif(counter >= 15)  then	
					state 		<= S_idle;	
				end if;
			when S_FE_ASIC_RESET	 =>
				counter		<= counter + 1;
				FE_RST		<= '0';
				if(counter >= 6)  then	
					state 		<= S_idle;	
				end if;												
			when S_WRITE_ADC_SPI_START	 =>
				SDI_L			<= '0';
				SDI_R			<= '0';
				CS				<=	'0';
				ADC_CLK		<= '0';	
				index			<= 0;			
				SPI_DATA_L	<= DPM_Q(15 downto 0);
				SPI_DATA_R	<= DPM_Q(31 downto 16);		
				state 		<= S_WRITE_ADC_SPI_next_bit;
			when	S_WRITE_ADC_SPI_next_bit	=>	
				index			<= index + 1;

				CS				<=	'1';
				ADC_CLK		<= '0';	
				SDI_L			<= SPI_DATA_L(index);
				SDI_R			<= SPI_DATA_R(index);			--	 (index+16);
				DP_ADDR_SEL	<= '0';									-- RB added				
				SPI_RB_DATA(index)		<= ASIC_ADC_SDO_L;   -- RB added
				SPI_RB_DATA(index +16)	<= ASIC_ADC_SDO_R;	-- RB added
				counter		<= X"0000";
				state 		<=	S_WRITE_ADC_SPI_CLK_HIGH;
				if( index = 15 ) then
					index <= 0;
					DPM_ADDR_S	<= DPM_ADDR_S	+ 1;
				end if;
				if( bit_cnt = 548) then
						SDI_L			<= '0';
						SDI_R			<= '0';
						state 		<=	S_WRITE_ADC_SPI_DONE;
				end if;
			when	S_WRITE_ADC_SPI_CLK_HIGH	=>				
				counter		<= counter + 1;
				ADC_CLK		<= '1';	
				if(counter >= SPI_SPD_CNTL)  then
					bit_cnt		<=	bit_cnt + 1;				
					SPI_DATA_L	<= DPM_Q(15 downto 0);
					SPI_DATA_R	<= DPM_Q(31 downto 16);		
					counter		<= X"0000";
					state 		<= S_WRITE_ADC_SPI_CLK_LOW;	
				end if;					
			when	S_WRITE_ADC_SPI_CLK_LOW	=>				
				counter		<= counter + 1;
				ADC_CLK		<= '0';	
				if(index = 0) then							-- RB added
					DPM_D			<=	SPI_RB_DATA;			-- RB added
					if( counter = 2)	then					-- RB added
						DP_ADDR_SEL	<= '1';					-- RB added
					elsif( counter = 4)	then				-- RB added
						DPM_WREN		<= '1';					-- RB added
					elsif( counter = 6)	then				-- RB added
						DPM_WREN		<= '0';					-- RB added		
					elsif( counter = 8)	then				-- RB added
						DPM_RB_ADDR	<= DPM_RB_ADDR + 1;	-- RB added
						DPM_D			<= (others => '0');	-- RB added
						SPI_RB_DATA	<= (others => '0');	-- RB added
						DP_ADDR_SEL	<= '0';					-- RB added
					end if;										-- RB added
				end if; 											-- RB added
				if(counter > SPI_SPD_CNTL)  then	
					counter		<= X"0000";
					state 		<= S_WRITE_ADC_SPI_next_bit;	
				end if;	
			when	S_WRITE_ADC_SPI_DONE	=>		
				counter		<= counter + 1;			-- RB added
				SDI_L			<= '0';
				SDI_R			<= '0';
				CS				<=	'0';
				FE_CLK		<= '0';					
				DPM_D			<=	SPI_RB_DATA;			-- RB added
				if( counter = 2)	then					-- RB added
					DP_ADDR_SEL	<= '1';					-- RB added
				elsif( counter = 4)	then				-- RB added
					DPM_WREN		<= '1';					-- RB added
				elsif( counter = 6)	then				-- RB added
					DPM_WREN		<= '0';					-- RB added		
				elsif( counter >= 8)	then				-- RB added
					DPM_RB_ADDR	<= DPM_RB_ADDR + 1;	-- RB added
					DPM_D			<= (others => '0');	-- RB added
					SPI_RB_DATA	<= (others => '0');	-- RB added
					DP_ADDR_SEL	<= '0';					-- RB added
					state 		<= S_idle;							
				end if;										-- RB added			
			when S_WRITE_FE_SPI_START	 =>

				FE_SDI_L		<= '0';
				FE_SDI_R		<= '0';
				FE_CS			<=	'0';
				FE_CLK		<= '0';	
				index			<= 0;			
				SPI_DATA_L	<= DPM_Q(15 downto 0);
				SPI_DATA_R	<= DPM_Q(31 downto 16);		
				state 		<= S_WRITE_FE_SPI_next_bit;
			when	S_WRITE_FE_SPI_next_bit	=>	
				index			<= index + 1;
				FE_CS			<=	'1';
				FE_CLK		<= '0';	
				FE_SDI_L		<= SPI_DATA_L(index);
				FE_SDI_R		<= SPI_DATA_R(index);  --  SPI_DATA_R(index+16);
				counter		<= X"0000";
				DP_ADDR_SEL	<= '0';									-- RB added				

				state 		<=	S_WRITE_FE_SPI_CLK_HIGH;
				if( index = 15 ) then
					index <= 0;
					DPM_ADDR_S		<= DPM_ADDR_S	+ 1;
				end if;
				if( bit_cnt = 544) then
						DP_ADDR_SEL		<= '1';							-- RB added
						FE_SDI_L			<= '0';
						FE_SDI_R			<= '0';
						state 			<=	S_WRITE_FE_SPI_DONE;
				end if;
			when	S_WRITE_FE_SPI_CLK_HIGH	=>				
				counter		<= counter + 1;
				FE_CLK		<= '1';	
				if(counter >= SPI_SPD_CNTL)  then
					bit_cnt		<=	bit_cnt + 1;				
					SPI_DATA_L	<= DPM_Q(15 downto 0);
					SPI_DATA_R	<= DPM_Q(31 downto 16);		
					counter		<= X"0000";	
					if(index = 0) then
						SPI_RB_DATA(15)	<= ASIC_FE_SDO_L;  	-- RB added
						SPI_RB_DATA(31)	<= ASIC_FE_SDO_R;		-- RB added							
					else
						SPI_RB_DATA(index-1)		<= ASIC_FE_SDO_L;  	-- RB added
						SPI_RB_DATA(index +15)	<= ASIC_FE_SDO_R;		-- RB added				
					end if;
					state 		<= S_WRITE_FE_SPI_CLK_LOW;	
				end if;					
			when	S_WRITE_FE_SPI_CLK_LOW	=>				
				counter		<= counter + 1;
				FE_CLK		<= '0';	
				if(index = 0) then							-- RB added
				
					if( counter = 1)	then					-- RB added
					--	SPI_RB_DATA(index-1)		<= ASIC_FE_SDO_L;  	-- RB added
					--	SPI_RB_DATA(index +15)	<= ASIC_FE_SDO_R;		-- RB added					
					elsif( counter = 2)	then
						DPM_D			<=	SPI_RB_DATA;		-- RB added
					elsif( counter = 4)	then				-- RB added
						DP_ADDR_SEL	<= '1';					-- RB added
					elsif( counter = 6)	then				-- RB added
						DPM_WREN		<= '1';					-- RB added
					elsif( counter = 8)	then				-- RB added
						DPM_WREN		<= '0';					-- RB added		
					elsif( counter = 10)	then				-- RB added
						DPM_RB_ADDR	<= DPM_RB_ADDR + 1;	-- RB added
						DP_ADDR_SEL	<= '0';					-- RB added
					end if;										-- RB added
				end if; 											-- RB added				
				
				if(counter > SPI_SPD_CNTL)  then	
					counter		<= X"0000";					
					state 		<= S_WRITE_FE_SPI_next_bit;	
				end if;	
			when	S_WRITE_FE_SPI_DONE	=>	
				counter		<= counter + 1;			-- RB added	
				DPM_WREN			<= '1';					-- RB added
				FE_SDI_L			<= '0';
				FE_SDI_R			<= '0';
				FE_CS				<=	'0';
				FE_CLK			<= '0';	
				DPM_D			<=	SPI_RB_DATA;			-- RB added
				if( counter = 2)	then					-- RB added
					DP_ADDR_SEL	<= '1';					-- RB added
				elsif( counter = 4)	then				-- RB added
					DPM_WREN		<= '1';					-- RB added
				elsif( counter = 6)	then				-- RB added
					DPM_WREN		<= '0';					-- RB added		
				elsif( counter >= 8)	then				-- RB added
					DPM_RB_ADDR	<= DPM_RB_ADDR + 1;	-- RB added
					DPM_D			<= (others => '0');	-- RB added
					SPI_RB_DATA	<= (others => '0');	-- RB added
					DP_ADDR_SEL	<= '0';					-- RB added
					state 		<= S_idle;							
				end if;										-- RB added		
			 when others =>		
					state <= S_idle;		
			 end case; 
	 end if;
end process;

END behavior;

	
	