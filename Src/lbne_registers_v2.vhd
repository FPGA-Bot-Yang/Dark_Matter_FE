--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: LBNE_Registers.VHD          
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 07/10/2014
--////  Description:  LBNE PGP, I2C  and DPM register interface
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

ENTITY LBNE_Registers_v2 IS

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
	
END LBNE_Registers_v2;


ARCHITECTURE Behavior OF LBNE_Registers_v2 IS


component DPM_LBNE_REG
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock				: IN STD_LOGIC  := '1';
		data_a			: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		data_b			: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		wren_a			: IN STD_LOGIC  := '0';
		wren_b			: IN STD_LOGIC  := '0';
		q_a				: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		q_b				: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;



signal	DP_A_data 			: STD_LOGIC_VECTOR (31 DOWNTO 0);
signal	DP_A_WR				: STD_LOGIC;
signal	DP_A_Q				: STD_LOGIC_VECTOR (31 DOWNTO 0);
signal	DP_A_ADDR 			: STD_LOGIC_VECTOR (7 DOWNTO 0);

SIGNAL	I2C_SEL				: integer;
SIGNAL	SCRATCH_PAD			: STD_LOGIC_VECTOR (31 DOWNTO 0);

begin


DPM_LBNE_REG_inst : DPM_LBNE_REG
	PORT MAP
	(
		address_a		=> DP_A_ADDR,
		address_b		=> DPM_B_ADDR,
		clock				=> clk,
		data_a			=> DP_A_data,
		data_b			=> DPM_B_D,
		wren_a			=> DP_A_WR,
		wren_b			=> DPM_B_WREN,
		q_a				=> DP_A_Q,
		q_b				=> DPM_B_Q
	);

	
			DP_A_ADDR		<= (I2C_address(I2C_SEL)(7 downto 0) - 64);  --WHEN (I2C_SEL = n) ELSE	
--								(I2C_address(0)(7 downto 0) - 64);
	
	
generate_label : 	
	for n in 1 downto 0 generate	
	


								
	  I2C_data_out(n)	<=	 	reg0_i 	when (I2C_address(n) = x"000")	else
									 reg1_i 	when (I2C_address(n) = x"001")	else
									 reg2_i 	when (I2C_address(n) = x"002")	else
									 reg3_i 	when (I2C_address(n) = x"003")	else
									 reg4_i 	when (I2C_address(n) = x"004")	else
									 reg5_i 	when (I2C_address(n) = x"005")	else
									 reg6_i 	when (I2C_address(n) = x"006")	else
									 reg7_i 	when (I2C_address(n) = x"007")	else
									 reg8_i 	when (I2C_address(n) = x"008")	else
									 reg9_i 	when (I2C_address(n) = x"009")	else
									 reg10_i	when (I2C_address(n) = x"00a")	else
									 reg11_i	when (I2C_address(n) = x"00b")	else
									 reg12_i	when (I2C_address(n) = x"00c")	else
									 reg13_i	when (I2C_address(n) = x"00d")	else
									 reg14_i	when (I2C_address(n) = x"00e")	else
									 reg15_i	when (I2C_address(n) = x"00f")	else
									 reg16_i	when (I2C_address(n) = x"010")	else
									 reg17_i	when (I2C_address(n) = x"011")	else
									 reg18_i	when (I2C_address(n) = x"012")	else
									 reg19_i	when (I2C_address(n) = x"013")	else
									 reg20_i	when (I2C_address(n) = x"014")	else
									 SCRATCH_PAD					when (I2C_address(n) = x"03E")	else
									 BOARD_ID	& VERSION_ID	when (I2C_address(n) = x"03F")	else
									 DP_A_Q 							when (I2C_address(n) >= x"040")	else
									 X"00000000";		 
		end generate;	 
		 
		 
		 
		 					 
  process(clk,rst) 
  begin
		if (rst = '1') then
			I2C_SEL		<= 0;
			reg0_o		<= X"00000000";		
			reg1_o		<= X"00000000";	
			reg2_o		<= X"00000000";	
			reg3_o		<= X"00000000";	
			reg4_o		<= X"00000000";	
			reg5_o		<= X"00000000";	
			reg6_o		<= X"00000000";	
			reg7_o		<= X"00000000";	
			reg8_o		<= X"00000000";		
			reg9_o		<= X"00000000";	
			reg10_o		<= X"00000000";	
			reg11_o		<= X"00000000";	
			reg12_o		<= X"00000000";		
			reg13_o		<= X"00000000";
			reg14_o		<= X"00000000";	
			reg15_o		<= X"00000000";
			reg16_o		<= X"00000000";	
			reg17_o		<= X"00000000";	
			reg18_o		<= X"00000000";		
			reg19_o		<= X"00000000";	
			reg20_o		<= X"00000000";				
		elsif (clk'event  AND  clk = '1') then				

		reg0_o					<= X"00000000";	-- AUTO CLEAR REG 
		reg1_o(1 downto 0)	<= B"00";	
		reg2_o(1 downto 0)	<= B"00";	
		DP_A_WR					<= '0';		
		
	 for n in 1 downto 0 loop	
	 	 
			if (I2C_SEL = n) then
				DP_A_data			<= I2C_data(n);
				if (I2C_WR(n) = '1') and (I2C_address(n) >= x"040") then
					DP_A_WR				<= '1';		
				end if;		
			end if;
			
			if (I2C_WR(n) = '1') then
				I2C_SEL		<= n;
				CASE I2C_address(n) IS
					when x"000" => 	reg0_o   <= I2C_data(n);
					when x"001" => 	reg1_o   <= I2C_data(n);	
					when x"002" => 	reg2_o   <= I2C_data(n);
					when x"003" => 	reg3_o   <= I2C_data(n);
					when x"004" => 	reg4_o   <= I2C_data(n);
					when x"005" => 	reg5_o   <= I2C_data(n);
					when x"006" => 	reg6_o   <= I2C_data(n);
					when x"007" => 	reg7_o   <= I2C_data(n);
					when x"008" => 	reg8_o   <= I2C_data(n);
					when x"009" => 	reg9_o   <= I2C_data(n);	
					when x"00A" => 	reg10_o   <= I2C_data(n);
					when x"00B" => 	reg11_o   <= I2C_data(n);
					when x"00C" => 	reg12_o   <= I2C_data(n);
					when x"00D" => 	reg13_o   <= I2C_data(n);
					when x"00E" => 	reg14_o   <= I2C_data(n);
					when x"00F" => 	reg15_o   <= I2C_data(n);		
					when x"010" => 	reg16_o   <= I2C_data(n);
					when x"011" => 	reg17_o   <= I2C_data(n);
					when x"012" => 	reg18_o   <= I2C_data(n);
					when x"013" => 	reg19_o   <= I2C_data(n);	
					when x"014" => 	reg20_o   <= I2C_data(n);	
					when x"03E" =>	SCRATCH_PAD	<= I2C_data(n);	
					WHEN OTHERS =>  
				end case;  
			end if;		
  end loop;		 
		
		

	end if;
end process;
	

END behavior;
