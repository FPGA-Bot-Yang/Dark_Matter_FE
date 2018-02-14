--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: LBNE_FPGA.VHD            
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 08/08/2014 
--////  Description:  TOP LEVEL LBNE FPGA FIRMWARE For V4 ADC
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

entity LBNE_FPGA_B3 is
	port 
	(	
		-- Reset input by Ethan Connect to P1 Mezzine Connector Port 15 -> MISC_IO14(C23)
		-- Alternative: Connect to SW1 button 3, BRD_ID2 -> T14, when push down button 3, it will connect T14 pin to GND, which will initiate the reset
		rst_n				: IN STD_LOGIC;
		-- If this port is 1, signify the byte ordering process is done on the receiver
		-- Connect to P1 Port 3 -> MISC_IO2 (B23)
		byteordering_flag		: IN STD_LOGIC;
		-- If this port is 1, signify the word alignment process is done on the receiver side
		-- Connect to P1 Port 1 -> MISC_IO0 (D16)
		wordalignment_flag	: IN STD_LOGIC;
		
		
		GXB_TX_A			: OUT STD_LOGIC_VECTOR (3 DOWNTO 0);	-- 1.5V PCML
																				-- Connect DATA[0] to TX0, P:Y4, N:Y3 
																				-- Connect DATA[1] to TX1, P:V4, N:V3
																				-- Connect DATA[2] to TX2, P:T4, N:T3
																				-- Connect DATA[3] to TX3, P:P4, N:P3 

		SYS_CLK_1		: IN STD_LOGIC;	-- LVDS	  100MHz
		SYS_CLK_2		: IN STD_LOGIC;	-- LVDS
		SYS_CLK_3		: IN STD_LOGIC;	-- LVDS	  125MHz  Internal SERDES CLOCK		
		SYS_CLK_4		: IN STD_LOGIC;	-- LVDS    External SERDES CLOCK FROM MEZZ
		IO_CLK_1			: IN STD_LOGIC;	-- LVDS
		IO_CLK_2			: IN STD_LOGIC;	-- LVDS	   NOVA SYNC  SIGNAL
	
		SYNC_CLK			: IN STD_LOGIC;	-- LVDS	   NOVA CLOCK
		REG_RD_BK		: OUT STD_LOGIC;	-- LVDS	-- NOT USED ADDED 
		
		FE_CS_L			: OUT STD_LOGIC;	-- 1.8V
		FE_RST_L			: OUT STD_LOGIC;	-- 1.8V
		FE_CK_L			: OUT STD_LOGIC;	-- 1.8V
		FE_SDI_L			: OUT STD_LOGIC;	-- 1.8V
		FE_SDO_L			: IN  STD_LOGIC;	-- 1.8V
		FE_CS_R			: OUT STD_LOGIC;	-- 1.8V
		FE_RST_R			: OUT STD_LOGIC;	-- 1.8V
		FE_CK_R			: OUT STD_LOGIC;	-- 1.8V
		FE_SDI_R			: OUT STD_LOGIC;	-- 1.8V
		FE_SDO_R			: IN  STD_LOGIC;	-- 1.8V

--		MISC_L			: INOUT STD_LOGIC_VECTOR(3 downto 0);	-- 1.8V
--		MISC_R			: INOUT STD_LOGIC_VECTOR(3 downto 0);	-- 1.8V		
		
		
		
		ADC_CLK_STRB_L	: OUT STD_LOGIC;	-- LVDS  
		ADC_CLK_STRB_R	: OUT STD_LOGIC;	-- LVDS	
		ADC_SDI_L		: OUT STD_LOGIC;	-- LVDS	USED TO BE ADC_REN_L		
		ADC_SDI_R		: OUT STD_LOGIC;	-- LVDS	USED TO BE ADC_REN_R
		ADC_SDO_L		: IN STD_LOGIC;	-- LVDS	
		ADC_SDO_R		: IN STD_LOGIC;	-- LVDS			

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
		ADC_CS			: OUT STD_LOGIC_VECTOR(7 downto 0);  -- LVDS	
		ADC_CLK			: OUT STD_LOGIC_VECTOR(7 downto 0);  -- LVDS	


		BRD_ID			: IN STD_LOGIC_VECTOR(4 downto 0);				-- 2.5V		
		DAC_CNTL			: INOUT STD_LOGIC_VECTOR(4 downto 0);			-- 1.8V
		MISC_IO			: OUT STD_LOGIC_VECTOR(15 downto 0);			-- 1.8V
		
		I2C_SCL			: IN STD_LOGIC_VECTOR(3 downto 0);				-- 2.5V
		I2C_SDA			: INOUT STD_LOGIC_VECTOR(3 downto 0)			-- 2.5V
		
		

	);

end LBNE_FPGA_B3;


architecture LBNE_FPGA_arch of LBNE_FPGA_B3 is


COMPONENT sys_rst
	PORT
	(	clk 			: IN STD_LOGIC;
		reset_in 	: IN STD_LOGIC;
		start 		: OUT STD_LOGIC;
		RST_OUT 		: OUT STD_LOGIC
	);
END COMPONENT;


component alt_pll
	PORT
	(	inclk0	: IN STD_LOGIC;
		c0			: OUT STD_LOGIC ;
		c1			: OUT STD_LOGIC ;
		c2			: OUT STD_LOGIC ;
		c3			: OUT STD_LOGIC ;
		c4			: OUT STD_LOGIC 

	);
end component;








component LBNE_PLL
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC 
	);
end component;

	
component lbne_pll2
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		c1		: OUT STD_LOGIC 
	);
end component;


component LBNE_HSTX 
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
end component;



COMPONENT I2C_slave_32bit_A16
	PORT
	(	rst   	   : IN 	STD_LOGIC;				
		sys_clk	   : IN 	STD_LOGIC;		
		I2C_BRD_ADDR: IN 	STD_LOGIC_VECTOR(6 downto 0);		
		SCL         : IN 	STD_LOGIC;
		SDA         : INOUT 	STD_LOGIC;						

		REG_ADDRESS	: OUT STD_LOGIC_VECTOR(15 downto 0);
		REG_DOUT		: IN  STD_LOGIC_VECTOR(31 downto 0);
		REG_DIN		: OUT STD_LOGIC_VECTOR(31 downto 0);
		REG_WR_STRB : OUT STD_LOGIC
	);
	
END COMPONENT;



COMPONENT LBNE_Registers_v2 

	PORT
	(
		rst         : IN STD_LOGIC;				-- state machine reset
		clk         : IN STD_LOGIC;
		
		BOARD_ID			 : IN  STD_LOGIC_VECTOR(15 downto 0);
		VERSION_ID		 : IN  STD_LOGIC_VECTOR(15 downto 0);
		
		I2C_data        : IN I2C_data_type(0 to 1);
		I2C_address     : IN I2C_address_type(0 to 1);
		I2C_WR    	 	 : IN I2C_WR_type(0 to 1);
		I2C_data_out	 : OUT I2C_data_out_type(0 to 1);
		
		DPM_B_WREN		 : IN  STD_LOGIC;		
		DPM_B_ADDR		 : IN  STD_LOGIC_VECTOR(7 downto 0);		
		DPM_B_Q			 : OUT STD_LOGIC_VECTOR(31 downto 0);
		DPM_B_D			 : IN  STD_LOGIC_VECTOR(31 downto 0);	

		reg0_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg1_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg2_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg3_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg4_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg5_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg6_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg7_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg8_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg9_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg10_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg11_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg12_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg13_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg14_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg15_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg16_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg17_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg18_i		: IN  STD_LOGIC_VECTOR(31 downto 0);		
		reg19_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		reg20_i		: IN  STD_LOGIC_VECTOR(31 downto 0);	
		
		
		
		reg0_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg1_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg2_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg3_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg4_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg5_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg6_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg7_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg8_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg9_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg10_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg11_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg12_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg13_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg14_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg15_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);
		reg16_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg17_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg18_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);		
		reg19_o		: OUT  STD_LOGIC_VECTOR(31 downto 0);	
		reg20_o		: OUT  STD_LOGIC_VECTOR(31 downto 0)	

	);
	
END COMPONENT;	

COMPONENT SFL_EPCS 
	PORT
	(	rst         : IN STD_LOGIC;				-- state machine reset
		clk         : IN STD_LOGIC;
		start_op		: IN STD_LOGIC;	
		JTAG_EEPROM	: IN STD_LOGIC;
		op_code	   : IN STD_LOGIC_VECTOR(7 downto 0);	
		address	   : IN STD_LOGIC_VECTOR(23 downto 0);	
		status		: OUT STD_LOGIC_VECTOR(31 downto 0);		
		DPM_WREN		: OUT STD_LOGIC;		
		DPM_ADDR		: OUT STD_LOGIC_VECTOR(7 downto 0);		
		DPM_Q	  		: IN  STD_LOGIC_VECTOR(31 downto 0);
		DPM_D			: OUT STD_LOGIC_VECTOR(31 downto 0)		
	);
END COMPONENT;



COMPONENT LBNE_ASIC_RDOUT_V2 

	PORT
	(	sys_rst     	: IN STD_LOGIC;				-- reset		
		TS_RESET			: IN STD_LOGIC;				-- reset		
		clk_200Mhz    	: IN STD_LOGIC;				-- clock
		clk_sys	    	: IN STD_LOGIC;				-- system clock 
		clk_TS	    	: IN STD_LOGIC;				-- timestamp clock 
		
		NOVA_TIME_SYNC	: IN STD_LOGIC;				-- NOVA_SYNC_ADC		
		LBNE_ADC_RST	: IN STD_LOGIC;				-- LBNE_SYNC_ADC	
		
		sync_sel_L		: IN STD_LOGIC_VECTOR(3 downto 0); 	
		sync_sel_R		: IN STD_LOGIC_VECTOR(3 downto 0); 	
		CLK_disable		: IN STD_LOGIC_VECTOR(7 downto 0); 			
		CLK_select		: IN STD_LOGIC_VECTOR(7 downto 0); 			
		CHP_select		: IN STD_LOGIC_VECTOR(7 downto 0); 		
		CHN_select		: IN STD_LOGIC_VECTOR(7 downto 0); 
		EN_TST_MODE 	: IN STD_LOGIC;			
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
		OUT_of_SYNC	 	: OUT STD_LOGIC_VECTOR(15 downto 0);					

		DATA_VALID		: OUT STD_LOGIC;		
		LANE1_DATA		: OUT STD_LOGIC_VECTOR(15 downto 0);
		LANE2_DATA		: OUT STD_LOGIC_VECTOR(15 downto 0);
		LANE3_DATA		: OUT STD_LOGIC_VECTOR(15 downto 0);		
		LANE4_DATA		: OUT STD_LOGIC_VECTOR(15 downto 0)				
	);
END COMPONENT;




COMPONENT LBNE_TST_PULSE 
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
END COMPONENT;



COMPONENT LBNE_ASIC_CNTRL 
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
END COMPONENT;	



	
SIGNAL	clk_200Mhz 		:  STD_LOGIC;
SIGNAL	clk_125Mhz 		:  STD_LOGIC;
SIGNAL	clk_100Mhz 		:  STD_LOGIC;
SIGNAL	clk_50Mhz		:  STD_LOGIC;
SIGNAL	clk_2Mhz			:  STD_LOGIC;
SIGNAL	LOC_CLK			:  STD_LOGIC;


SIGNAL	reset 			:  STD_LOGIC;


SIGNAL	reg0_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg1_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg2_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg3_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg4_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg5_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg6_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg7_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg8_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg9_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg10_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg11_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg12_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg13_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg14_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg15_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg16_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg17_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg18_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg19_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);
SIGNAL	reg20_p 			:  STD_LOGIC_VECTOR(31  DOWNTO 0);

SIGNAL	DPM_WREN					:  STD_LOGIC;		
SIGNAL	DPM_ADDR					:  STD_LOGIC_VECTOR(7 downto 0);		
SIGNAL	DPM_Q						:  STD_LOGIC_VECTOR(31 downto 0);
SIGNAL	DPM_D						:  STD_LOGIC_VECTOR(31 downto 0);	

SIGNAL	FPGA_F_DPM_WREN		:  STD_LOGIC;		
SIGNAL	FPGA_F_DPM_ADDR		:  STD_LOGIC_VECTOR(7 downto 0);		
SIGNAL	FPGA_F_DPM_Q			:  STD_LOGIC_VECTOR(31 downto 0);
SIGNAL	FPGA_F_DPM_D			:  STD_LOGIC_VECTOR(31 downto 0);	

SIGNAL	LBNE_SPI_DPM_WREN		:  STD_LOGIC;		
SIGNAL	LBNE_SPI_DPM_ADDR		:  STD_LOGIC_VECTOR(7 downto 0);		
SIGNAL	LBNE_SPI_DPM_Q			:  STD_LOGIC_VECTOR(31 downto 0);
SIGNAL	LBNE_SPI_DPM_D			:  STD_LOGIC_VECTOR(31 downto 0);	



SIGNAL	I2C_addr0    	 		:	STD_LOGIC_VECTOR(15 downto 0); 
SIGNAL	I2C_addr1    	 		:	STD_LOGIC_VECTOR(15 downto 0); 

SIGNAL	I2C_data      	  		: I2C_data_type(0 to 1);
SIGNAL	I2C_address    	 	: I2C_address_type(0 to 1);
SIGNAL	I2C_WR    	 	 		: I2C_WR_type(0 to 1);
SIGNAL	I2C_data_out	 		: I2C_data_out_type(0 to 1);
		
		
SIGNAL	SYS_RESET				:  STD_LOGIC;
SIGNAL	REG_RESET				:  STD_LOGIC;

SIGNAL	FPGA_F_ENABLE			:  STD_LOGIC;
SIGNAL 	FPGA_F_OP_CODE			:  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL 	FPGA_F_STRT_OP			:  STD_LOGIC;
SIGNAL 	FPGA_F_ADDR				:  STD_LOGIC_VECTOR(23 DOWNTO 0);
SIGNAL 	FPGA_F_status			:  STD_LOGIC_VECTOR(31 DOWNTO 0);

SIGNAL	TS_RESET					:  STD_LOGIC;

SIGNAL	ADC_RESET				:  STD_LOGIC;
SIGNAL	FE_RESET					:  STD_LOGIC;
SIGNAL	WRITE_ADC_ASIC_SPI	:  STD_LOGIC;
SIGNAL	WRITE_FE_ASIC_SPI		:  STD_LOGIC;


SIGNAL 	CLK_select				: 	STD_LOGIC_VECTOR(7 downto 0); 		
SIGNAL 	CHP_select				:	STD_LOGIC_VECTOR(7 downto 0); 		
SIGNAL 	CHN_select				:	STD_LOGIC_VECTOR(7 downto 0); 
SIGNAL	TST_PATT_EN				:	STD_LOGIC_VECTOR(7 downto 0); 
SIGNAL	TST_PATT					:	STD_LOGIC_VECTOR(11 downto 0);
SIGNAL 	ADC_TEST_PAT_EN		:  STD_LOGIC;


SIGNAL	Header_P_event			:	STD_LOGIC_VECTOR(7 downto 0); 	-- Number of events packed per header  		
SIGNAL	LATCH_LOC_1				:	STD_LOGIC_VECTOR(7 downto 0);
SIGNAL	LATCH_LOC_2				:	STD_LOGIC_VECTOR(7 downto 0);
SIGNAL	LATCH_LOC_3				:	STD_LOGIC_VECTOR(7 downto 0);
SIGNAL	LATCH_LOC_4				:	STD_LOGIC_VECTOR(7 downto 0);	
SIGNAL	OUT_of_SYNC	 			:  STD_LOGIC_VECTOR(15 downto 0);		

SIGNAL	HS_DATA_LATCH 			:	STD_LOGIC;
SIGNAL	DATA_OUT		 			:	STD_LOGIC_VECTOR(15 downto 0);	
	
SIGNAL	LANE1_DATA		 		:	STD_LOGIC_VECTOR(15 downto 0);
SIGNAL	LANE2_DATA		 		:	STD_LOGIC_VECTOR(15 downto 0);
SIGNAL	LANE3_DATA		 		:	STD_LOGIC_VECTOR(15 downto 0);
SIGNAL	LANE4_DATA		 		:	STD_LOGIC_VECTOR(15 downto 0);


SIGNAL	TP_SYNC					: STD_LOGIC;
SIGNAL	TP_AMPL					: STD_LOGIC_VECTOR(4 downto 0);
SIGNAL	TP_DLY					: STD_LOGIC_VECTOR(7 downto 0);
SIGNAL	TP_FREQ					: STD_LOGIC_VECTOR(15 downto 0);



SIGNAL	Stream_EN				: STD_LOGIC;
SIGNAL	PRBS_EN					: STD_LOGIC;	
SIGNAL	CNT_EN					: STD_LOGIC;

SIGNAL	clk_200				: STD_LOGIC;
SIGNAL	clk_128				: STD_LOGIC;
SIGNAL	clk_64				: STD_LOGIC;

SIGNAL	TP_ENABLE			: STD_LOGIC;

SIGNAL	sync_sel_L			: STD_LOGIC_VECTOR(3 downto 0); 	
SIGNAL	sync_sel_R			: STD_LOGIC_VECTOR(3 downto 0); 	
SIGNAL	CLK_disable			: STD_LOGIC_VECTOR(7 downto 0); 	



begin

	
lbne_pll2_inst : lbne_pll2
	PORT MAP
	(
		inclk0		=> SYS_CLK_1,
		c0				=> clk_64,
		c1				=> clk_128
	);


----- register map -------

	SYS_RESET				<= reg0_p(0);							-- SYSTEM RESET
	REG_RESET				<= reg0_p(1);							-- RESISTER RESET
	TS_RESET					<= reg0_p(2);							-- TIME_STAMP RESET
	ADC_RESET				<= reg1_p(0);		
	FE_RESET					<= reg1_p(1);			
	WRITE_ADC_ASIC_SPI 	<= reg2_p(0);	 	
	WRITE_FE_ASIC_SPI 	<= reg2_p(1);	 	
	TST_PATT_EN				<= reg3_p(7 downto 0);		
	TST_PATT					<= reg3_p(27 downto 16);
	ADC_TEST_PAT_EN	 	<= reg3_p(31);	 	
	LATCH_LOC_1				<= reg4_p(7 downto 0);	
	LATCH_LOC_2				<= reg4_p(15 downto 8);	
	LATCH_LOC_3				<= reg4_p(23 downto 16);	
	LATCH_LOC_4				<= reg4_p(31 downto 24);	

	TP_ENABLE				<= reg13_p(0);	
	TP_AMPL					<= reg5_p(4 downto 0);	
	TP_FREQ		 			<= reg5_p(31 downto 16);
	TP_DLY					<= reg5_p(15 downto 8);

	
	CLK_select				<= reg6_p(7 downto 0);	
	--OUT_of_SYNC				reg6(31 downto 16);
	CHP_select				<= reg7_p(7 downto 0);	
	CHN_select				<= reg7_p(15 downto 8);	
	Header_P_event			<= reg8_p(7 downto 0);	

	Stream_EN				<= reg9_p(0);		
	PRBS_EN					<= reg9_p(1);		
	CNT_EN					<= reg9_p(2);		

	FPGA_F_OP_CODE			<= reg10_p(7 downto 0);				-- EPCS  OP CODE
	FPGA_F_STRT_OP			<= reg10_p(8);							-- START FLASH OPERATION
	--FPGA_F_ENABLE			<= reg10_p(31);						-- ENABLE EPCS PROGRAMMING 
	FPGA_F_ADDR				<= reg11_p(23 downto 0);			-- EPCS ADDRESS
	--FPGA_F_status			REG 12 
	FPGA_F_ENABLE			<= reg13_p(0);	

--	tx_digitalreset		<=	reg20_p(1);  used bellow
	CLK_disable				<= reg14_p(7 downto 0);	
	sync_sel_L				<= reg15_p(3 downto 0);		
	sync_sel_R				<= reg15_p(11 downto 8);	



-----  end of register map



sys_rst_inst : sys_rst
PORT MAP(	clk 			=> clk_50Mhz,
				reset_in 	=> SYS_RESET,
				start 		=> open,
				RST_OUT 		=> reset);
			
alt_pll_inst : alt_pll
	PORT MAP
	(
		inclk0		=> SYS_CLK_1,
		c0				=> clk_200Mhz,
		c1				=> clk_125Mhz,
		c2				=> clk_100Mhz,
		c3				=> clk_50Mhz,
		c4				=> clk_2Mhz
	);
	
	

LBNE_HSTX_INST : LBNE_HSTX
	PORT MAP
	(
		GXB_TX_A			=> GXB_TX_A,
		--rst				=> reset,
		-- Ethan modify
		rst				=> NOT rst_n,
		cal_clk_125MHz	=> clk_125Mhz,
		gxb_clk			=> SYS_CLK_3,
		Stream_EN		=> NOT Stream_EN,
		PRBS_EN			=> PRBS_EN,
		CNT_EN			=>	CNT_EN,
		DATA_CLK			=> clk_100Mhz,
		DATA_VALID		=> HS_DATA_LATCH,	
		LANE1_DATA		=> LANE1_DATA,
		LANE2_DATA		=> LANE2_DATA,
		LANE3_DATA		=> LANE3_DATA,
		LANE4_DATA		=> LANE4_DATA,
		
		-- Ethan
		byteordering_flag => byteordering_flag,
		wordalignment_flag => wordalignment_flag
	);
	
		
	LOC_CLK		<= clk_50Mhz; 
			


 I2C_slave_inst1 : I2C_slave_32bit_A16
	PORT MAP
	(
		rst   	   		=> reset,
		sys_clk	   		=> clk_50Mhz,
		I2C_BRD_ADDR		=> b"0000101",
		SCL         		=> I2C_SCL(0),
		SDA        			=> I2C_SDA(0),
		REG_ADDRESS			=> I2C_addr0,
		REG_DOUT				=> I2C_data_out(0),
		REG_DIN				=> I2C_data(0) ,
		REG_WR_STRB 		=> I2C_WR(0)
	);
	
	
	------ REDUNTANT I2C LINK----------
	
 I2C_slave_inst2 : I2C_slave_32bit_A16
	PORT MAP
	(
		rst   	   		=> reset,
		sys_clk	   		=> clk_50Mhz,
		I2C_BRD_ADDR		=> b"0000101",
		SCL         		=> I2C_SCL(1),
		SDA        			=> I2C_SDA(1),
		REG_ADDRESS			=> I2C_addr1,
		REG_DOUT				=> I2C_data_out(1),
		REG_DIN				=> I2C_data(1),
		REG_WR_STRB 		=> I2C_WR(1)
	);
----------------------------------------
	
	
	I2C_address(0)	<= I2C_addr0(11 downto 0);
	I2C_address(1)	<= I2C_addr1(11 downto 0);
	

 LBNE_Registers_inst :  LBNE_Registers_v2
	PORT MAP
	(
		rst         => reset or REG_RESET,	
		clk         => clk_50Mhz,

		BOARD_ID		=> x"00" & b"000" & BRD_ID,
		VERSION_ID	=> x"0100",
		
		I2C_data       => I2C_data,
		I2C_address    => I2C_address,
		I2C_WR    	 	=> I2C_WR , 
		I2C_data_out	=> I2C_data_out,	
		

		DPM_B_WREN		=> DPM_WREN,
		DPM_B_ADDR		=> DPM_ADDR,
		DPM_B_Q			=> DPM_Q,
		DPM_B_D			=> DPM_D,

		reg0_i 	=> reg0_p,
		reg1_i 	=> reg1_p,		 
		reg2_i 	=> reg2_p,		 
		reg3_i 	=> reg3_p,	
		reg4_i 	=> reg4_p,
		reg5_i 	=> reg5_p,
		reg6_i 	=> OUT_of_SYNC & reg6_p(15 downto 0),
		reg7_i 	=> reg7_p,
		reg8_i 	=> reg8_p,
		reg9_i 	=> reg9_p,		 
		reg10_i 	=> reg10_p,
		reg11_i 	=> reg11_p,
		reg12_i 	=> FPGA_F_status,
		reg13_i 	=> reg13_p,
		reg14_i 	=> reg14_p,
		reg15_i 	=> reg15_p,	
		reg16_i 	=> reg16_p,
		reg17_i 	=> reg17_p,
		reg18_i 	=> reg18_p,
		reg19_i 	=> reg19_p,		 
		reg20_i  => reg20_p,
	
		 		 
		reg0_o 	=> reg0_p,
		reg1_o 	=> reg1_p,		 
		reg2_o 	=> reg2_p,		 
		reg3_o 	=> reg3_p,		
		reg4_o 	=> reg4_p,
		reg5_o 	=> reg5_p,
		reg6_o 	=> reg6_p,
		reg7_o 	=> reg7_p,
		reg8_o 	=> reg8_p,
		reg9_o 	=> reg9_p,		 
		reg10_o 	=> reg10_p,
		reg11_o 	=> reg11_p,
		reg12_o 	=> reg12_p,
		reg13_o 	=> reg13_p,
		reg14_o 	=> reg14_p,
		reg15_o 	=> reg15_p,
		reg16_o 	=> reg16_p,
		reg17_o 	=> reg17_p,
		reg18_o 	=> reg18_p,
		reg19_o 	=> reg19_p,		 
		reg20_o 	=> reg20_p
	);

	
	
	DPM_WREN		<=	LBNE_SPI_DPM_WREN	when (FPGA_F_ENABLE = '0') else
						FPGA_F_DPM_WREN;
	DPM_ADDR		<= LBNE_SPI_DPM_ADDR	when (FPGA_F_ENABLE = '0') else
						FPGA_F_DPM_ADDR;
	DPM_D			<= LBNE_SPI_DPM_D	when (FPGA_F_ENABLE = '0') else
						FPGA_F_DPM_D;

	FPGA_F_DPM_Q		<= DPM_Q;	
	LBNE_SPI_DPM_Q		<= DPM_Q;



SFL_EPCS_inst	: SFL_EPCS
	PORT MAP
	(
		rst         => reset,			
		clk         => LOC_CLK,
		JTAG_EEPROM	=> FPGA_F_ENABLE,
		start_op		=> FPGA_F_STRT_OP,			
		op_code	   => FPGA_F_OP_CODE,	
		address	   => FPGA_F_ADDR, 		
		status		=> FPGA_F_status,		
		DPM_WREN		=> FPGA_F_DPM_WREN,
		DPM_ADDR		=> FPGA_F_DPM_ADDR,
		DPM_Q	  		=> FPGA_F_DPM_Q,
		DPM_D			=>	FPGA_F_DPM_D
		
	);


LBNE_ASIC_RDOUT_inst : LBNE_ASIC_RDOUT_V2
	PORT MAP
	(

		sys_rst     	=> SYS_RESET or ADC_RESET,	
		TS_RESET			=> TS_RESET,					-- reset		
		clk_200Mhz    	=> clk_200Mhz,
		clk_sys	    	=> clk_100Mhz,
		clk_TS	    	=> clk_100Mhz,


		NOVA_TIME_SYNC	=>	clk_2Mhz,--  TP_ENABLE, connect to nova 2MHz
		LBNE_ADC_RST	=>	ADC_RESET,
		
		CLK_disable		=> CLK_disable,
		sync_sel_L		=> sync_sel_L,
		sync_sel_R		=> sync_sel_R,
		TP_SYNC			=> TP_SYNC,
		ADC_SYNC_L		=> ADC_SYNC_L,
		ADC_SYNC_R		=> ADC_SYNC_R,	

		ADC_FD_1			=> ADC_FD_1,
		ADC_FD_2			=> ADC_FD_2,		
		ADC_FD_3			=> ADC_FD_3,		
		ADC_FD_4			=> ADC_FD_4,			
		ADC_FD_5			=> ADC_FD_5,		
		ADC_FD_6			=> ADC_FD_6,		
		ADC_FD_7			=> ADC_FD_7,		
		ADC_FD_8			=> ADC_FD_8,					
		
		ADC_F_CLK		=> ADC_F_CLK,
		ADC_FF			=> ADC_FF,
		ADC_FE			=> ADC_FE,
		ADC_CLK			=> ADC_CLK,
	
		CLK_select		=>	CLK_select,
		CHP_select		=>	CHP_select,			--: IN STD_LOGIC_VECTOR(7 downto 0); 		
		CHN_select		=>	CHN_select,			--: IN STD_LOGIC_VECTOR(7 downto 0); 
		TST_PATT_EN		=> TST_PATT_EN,		--: IN STD_LOGIC_VECTOR(7 downto 0); 
		TST_PATT			=> TST_PATT,			--: IN STD_LOGIC_VECTOR(11 downto 0);
		Header_P_event	=> Header_P_event,	--: IN STD_LOGIC_VECTOR(7 downto 0); 	-- Number of events packed per header  		
		LATCH_LOC_1		=> LATCH_LOC_1,		--: IN STD_LOGIC_VECTOR(7 downto 0);
		LATCH_LOC_2		=> LATCH_LOC_2,		--: IN STD_LOGIC_VECTOR(7 downto 0);
		LATCH_LOC_3		=> LATCH_LOC_3,		--: IN STD_LOGIC_VECTOR(7 downto 0);
		LATCH_LOC_4		=> LATCH_LOC_4,		--: IN STD_LOGIC_VECTOR(7 downto 0);	

		EN_TST_MODE		=> not reg9_p(3),
		OUT_of_SYNC		=> OUT_of_SYNC,
		DATA_VALID		=> HS_DATA_LATCH,
		LANE1_DATA		=> LANE1_DATA, 		-- : OUT STD_LOGIC_VECTOR(31 downto 0);
		LANE2_DATA		=> LANE2_DATA, 		-- : OUT STD_LOGIC_VECTOR(31 downto 0);
		LANE3_DATA		=> LANE3_DATA, 		-- : OUT STD_LOGIC_VECTOR(31 downto 0);
		LANE4_DATA		=> LANE4_DATA 		-- : OUT STD_LOGIC_VECTOR(31 downto 0);
		
	);	
	


 LBNE_ASIC_CNTRL_inst : LBNE_ASIC_CNTRL
	PORT MAP
	(

		sys_rst     			=> SYS_RESET ,	
		clk_sys   				=> clk_100Mhz,
		
		ADC_ASIC_RESET			=>	ADC_RESET,
		FE_ASIC_RESET			=>	FE_RESET,
		WRITE_ADC_SPI			=> WRITE_ADC_ASIC_SPI,
		WRITE_FE_SPI			=> WRITE_FE_ASIC_SPI,
		ADC_FIFO_TM				=> ADC_TEST_PAT_EN,
		
		DPM_WREN		 			=> LBNE_SPI_DPM_WREN,
		DPM_ADDR		 			=> LBNE_SPI_DPM_ADDR,
		DPM_D			 			=> LBNE_SPI_DPM_D,
		DPM_Q						=> LBNE_SPI_DPM_Q,

		ASIC_ADC_CS				=> ADC_CS,	
		ASIC_ADC_SDO_L			=> ADC_SDO_L,	
		ASIC_ADC_SDI_L			=> ADC_SDI_L,	
		ASIC_ADC_CLK_STRB_L	=> ADC_CLK_STRB_L,
		ASIC_ADC_SDO_R			=> ADC_SDO_R,	
		ASIC_ADC_SDI_R			=> ADC_SDI_R,
		ASIC_ADC_CLK_STRB_R	=> ADC_CLK_STRB_R,
	
		ASIC_FE_CS_L			=> FE_CS_L,
		ASIC_FE_RST_L			=> FE_RST_L,	
		ASIC_FE_CK_L			=> FE_CK_L,
		ASIC_FE_SDI_L			=> FE_SDI_L,
		ASIC_FE_SDO_L			=> FE_SDO_L,
		ASIC_FE_CS_R			=> FE_CS_R,
		ASIC_FE_RST_R			=> FE_RST_R,
		ASIC_FE_CK_R			=> FE_CK_R,
		ASIC_FE_SDI_R			=> FE_SDI_R,	
		ASIC_FE_SDO_R			=> FE_SDO_R
		
	);

	
				 

LBNE_TST_PULSE_inst : LBNE_TST_PULSE 
	PORT MAP 
	(
		sys_rst 				=> SYS_RESET,	
		clk_50Mhz			=> clk_50Mhz,
		TP_ENABLE			=> TP_ENABLE,
		LA_SYNC		 		=> TP_SYNC,	
		TP_AMPL				=> TP_AMPL,
		TP_DLY				=>	x"00" & TP_DLY,
		TP_FREQ				=> TP_FREQ,	 
		DAC_CNTL				=> DAC_CNTL
	);

	
	
--	REG_RD_BK <= clk_64;
	
	MISC_IO(0)	<= '0';	
	MISC_IO(2)	<= clk_200Mhz;	
	MISC_IO(4)	<= clk_64;
	MISC_IO(6)	<= clk_2Mhz;	
	MISC_IO(8)	<= 'Z';	
	MISC_IO(10)	<= 'Z';	
	MISC_IO(12)	<= 'Z';	
	MISC_IO(14)	<= 'Z';	
	MISC_IO(15)	<= '1';	


	MISC_IO(1)	<= '0';	
	MISC_IO(3)	<= '0';	
	MISC_IO(5)	<= '0';	
	MISC_IO(7)	<= '0';	
	MISC_IO(9)	<= '0';	
	MISC_IO(11)	<= '0';	
	MISC_IO(13)	<= '0';	

					
end LBNE_FPGA_arch;
