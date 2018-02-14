--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: SFL_EPCS.VHD          
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 11/22/2012
--////  Modified: 11/18/2014
--////  Description:  Cyclone IV  serial flash loader interface
--////					
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2012 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;


--  Entity Declaration

ENTITY SFL_EPCS IS

	PORT
	(
		rst         : IN STD_LOGIC;				-- state machine reset
		clk         : IN STD_LOGIC;
		start_op		: IN STD_LOGIC;	
		JTAG_EEPROM	: IN STD_LOGIC;
		op_code	   : IN STD_LOGIC_VECTOR(7 downto 0);	
		address	   : IN STD_LOGIC_VECTOR(23 downto 0);	
		status		: OUT STD_LOGIC_VECTOR(31 downto 0);		
		DPM_WREN		: OUT STD_LOGIC;		
		DPM_ADDR		: OUT STD_LOGIC_VECTOR(7 downto 0);		
		DPM_Q		   : IN  STD_LOGIC_VECTOR(31 downto 0);
		DPM_D			: OUT STD_LOGIC_VECTOR(31 downto 0)		

	);
	
END SFL_EPCS;


ARCHITECTURE behavior OF SFL_EPCS IS


	
component ADV_SFL
	PORT
	(
		asdo_in						: IN STD_LOGIC ;
		asmi_access_granted		: IN STD_LOGIC ;
		dclk_in						: IN STD_LOGIC ;
		ncso_in						: IN STD_LOGIC ;
		noe_in						: IN STD_LOGIC ;
		asmi_access_request		: OUT STD_LOGIC ;
		data0_out					: OUT STD_LOGIC 
	);
end component;	
	
	
	
	type state_typ is (	s_idle,S_OP_06_04_c7, S_OP_AB, S_OP_05,S_OP_03,S_OP_02 , s_done );	
	SIGNAL STATE : state_typ;	
	

	signal	asmi_access_granted	: STD_LOGIC ;
	signal	asmi_access_request	: STD_LOGIC ;
	signal	ncso_in					: STD_LOGIC ;
	
	signal	data0_out				: STD_LOGIC ;
	signal	asdo_in					: STD_LOGIC ;
	signal	dclk_in					: STD_LOGIC ;	
	signal	data_in					: STD_LOGIC_VECTOR (3 DOWNTO 0);	--in
	signal	data_out					: STD_LOGIC_VECTOR (3 DOWNTO 0);	-- out
	signal	data_oe					: STD_LOGIC_VECTOR (3 DOWNTO 0);	-- in	
	

	signal	PI_DATA						: STD_LOGIC_VECTOR(31 downto 0);
	signal	PO_DATA						: STD_LOGIC_VECTOR(31 downto 0);	
	signal	STORE_DATA					: STD_LOGIC ;


	signal	opcode					: STD_LOGIC_VECTOR( 7 downto 0) ;
	signal 	counter					: INTEGER RANGE 0 TO 1023;
	signal 	byte						: INTEGER RANGE 0 TO 1023;
	signal	start						: STD_LOGIC ;
	signal	DPM_WREN_dly			: STD_LOGIC ;
	signal 	DPM_ADDR_r				: STD_LOGIC_VECTOR( 7 downto 0) ;
	
	signal	CLK_CNT					: STD_LOGIC_VECTOR( 7 downto 0) ;
	signal	EPCS_CLK					: STD_LOGIC;
	
begin



  process(clk) 
  begin
   if (JTAG_EEPROM = '0') then
		CLK_CNT	<=	x"00";
	elsif (clk'event  AND  clk = '0') then
		CLK_CNT	<= CLK_CNT + 1;
	end if;	
end process;



	EPCS_CLK		<= CLK_CNT(2);
	asmi_access_granted	<= asmi_access_request;
	dclk_in					<=	EPCS_CLK;
	opcode					<= op_code;	
	DPM_ADDR					<= DPM_ADDR_r;

	
	
	ADV_SFL_inst : ADV_SFL
	PORT MAP
	(

		asmi_access_granted		=> asmi_access_granted,			 --not JTAG_EEPROM,		--  SET TO PROGRAM THROUGH jtag
		noe_in						=> '0',
		asmi_access_request		=> asmi_access_request,			--OPEN, --asmi_access_request,		
		asdo_in						=> asdo_in,		
		dclk_in						=> dclk_in,
		ncso_in						=> ncso_in,		
		data0_out					=> data0_out
	);
		

  process(EPCS_CLK) 
  begin
	if (EPCS_CLK'event  AND  EPCS_CLK = '0') then
		start		<= start_op;
	end if;	
end process;


     process( EPCS_CLK , rst )
       begin
         if ( rst = '1' ) then		
		
				counter  		<=  0;
				ncso_in			<=	'1';			
				asdo_in			<= '0';
				byte 				<=  0;
				DPM_WREN			<= '0';
				DPM_WREN_dly	<= '0';
				DPM_ADDR_r		<= x"00";
				status			<= (others => '0');	
				STORE_DATA		<= '0';
				DPM_D				<= (others => '0');		
				STATE 			<= s_idle;	
         elsif rising_edge( EPCS_CLK ) then
			  DPM_WREN		<= DPM_WREN_dly;
	        case STATE is
            when s_idle =>			
					counter  		<=  0;
					ncso_in			<=	'1';			
					asdo_in			<= '0';
					byte 				<=  0;
					STORE_DATA		<= '0';
					DPM_WREN_dly	<= '0';
					DPM_ADDR_r		<= x"00";
					DPM_D				<= (others => '0');		
					STATE 			<= s_idle;					
					if (start  = '1') then
						if(opcode = x"06") or (opcode = x"04")  or (opcode = x"c7") then
							STATE 		<= S_OP_06_04_c7;
						elsif(opcode = x"AB") then
							STATE 		<= S_OP_AB;								
						elsif(opcode = x"05") then
							STATE 		<= S_OP_05;
						elsif(opcode = x"03") then
							DPM_ADDR_r	<= x"40";
							STATE 		<= S_OP_03;
						elsif(opcode = x"02") then
							DPM_ADDR_r		<= x"00";
							PI_DATA		<= DPM_Q;
							STATE 		<= S_OP_02;
						else
							STATE 		<= s_idle;	
						end if;
					
					end if;					
				when	S_OP_06_04_c7	 =>
						counter <= counter + 1;
						ncso_in <= '0';
						CASE counter IS
							when 0 =>	asdo_in	<= opcode(7);
							when 1 =>	asdo_in	<= opcode(6);
							when 2 =>	asdo_in	<= opcode(5);
							when 3 =>	asdo_in	<= opcode(4);
							when 4 =>	asdo_in	<= opcode(3);
							when 5 =>	asdo_in	<= opcode(2);
							when 6 =>	asdo_in	<= opcode(1);
							when 7 =>	asdo_in	<= opcode(0);
							when 8 =>	ncso_in	<=	'1';
											STATE 		<= s_done;	
							when others =>   
											STATE 		<= s_idle;	
						end case;	
				when	S_OP_05	 =>
						counter <= counter + 1;
						ncso_in <= '0';
						CASE counter IS
							when 0 => 	asdo_in	<= opcode(7);
							when 1 =>	asdo_in	<= opcode(6);
							when 2 =>	asdo_in	<= opcode(5);
							when 3 =>	asdo_in	<= opcode(4);
							when 4 =>	asdo_in	<= opcode(3);
							when 5 =>	asdo_in	<= opcode(2);
							when 6 =>	asdo_in	<= opcode(1);
							when 7 =>	asdo_in	<= opcode(0);
							when 8 =>	STATE 		<= S_OP_05;
							when 9 =>	status(7)	<= data0_out;
							when 10 =>	status(6)	<= data0_out;
							when 11 =>	status(5)	<= data0_out;
							when 12 =>	status(4)	<= data0_out;
							when 13 =>	status(3)	<= data0_out;
							when 14 =>	status(2)	<= data0_out;
							when 15 =>	status(1)	<= data0_out;
							when 16 =>	status(0)	<= data0_out;
											ncso_in		<=	'1';
											STATE 		<= s_done;	
							when others =>   
											STATE 		<= s_idle;	
						end case;	
				when	S_OP_AB	 =>
						counter <= counter + 1;
						ncso_in <= '0';
						CASE counter IS
							when 0 => 	asdo_in	<= opcode(7);
							when 1 =>	asdo_in	<= opcode(6);
							when 2 =>	asdo_in	<= opcode(5);
							when 3 =>	asdo_in	<= opcode(4);
							when 4 =>	asdo_in	<= opcode(3);
							when 5 =>	asdo_in	<= opcode(2);
							when 6 =>	asdo_in	<= opcode(1);
							when 7 =>	asdo_in	<= opcode(0);
							when 8 to 32 => STATE 		<= S_OP_AB;
							when 33 =>	status(7)	<= data0_out;
							when 34 =>	status(6)	<= data0_out;
							when 35 =>	status(5)	<= data0_out;
							when 36 =>	status(4)	<= data0_out;
							when 37 =>	status(3)	<= data0_out;
							when 38 =>	status(2)	<= data0_out;
							when 39 =>	status(1)	<= data0_out;
							when 40 =>	status(0)	<= data0_out;
											ncso_in		<=	'1';
											STATE 		<= s_done;	
							when others =>   
											STATE 		<= s_idle;	
						end case;							
						
				when	S_OP_02	 =>
						counter <= counter + 1;
						ncso_in <= '0';
						CASE counter IS
							when 0 => 	asdo_in	<= opcode(7);
							when 1 =>	asdo_in	<= opcode(6);
							when 2 =>	asdo_in	<= opcode(5);
							when 3 =>	asdo_in	<= opcode(4);
							when 4 =>	asdo_in	<= opcode(3);
							when 5 =>	asdo_in	<= opcode(2);
							when 6 =>	asdo_in	<= opcode(1);
							when 7 =>	asdo_in	<= opcode(0);
							when 8 =>	asdo_in	<= address(23);
							when 9 =>	asdo_in	<= address(22);
							when 10 =>	asdo_in	<= address(21);
							when 11 =>	asdo_in	<= address(20);
							when 12 =>	asdo_in	<= address(19);
							when 13 =>	asdo_in	<= address(18);
							when 14 =>	asdo_in	<= address(17);
							when 15 =>	asdo_in	<= address(16);
							when 16 =>	asdo_in	<= address(15);
							when 17 =>	asdo_in	<= address(14);
							when 18 =>	asdo_in	<= address(13);
							when 19 =>	asdo_in	<= address(12);
							when 20 =>	asdo_in	<= address(11);
							when 21 =>	asdo_in	<= address(10);
							when 22 =>	asdo_in	<= address(9);
							when 23 =>	asdo_in	<= address(8);
							when 24 =>	asdo_in	<= address(7);
							when 25 =>	asdo_in	<= address(6);
							when 26 =>	asdo_in	<= address(5);
							when 27 =>	asdo_in	<= address(4);
							when 28 =>	asdo_in	<= address(3);
							when 29 =>	asdo_in	<= address(2);
							when 30 =>	asdo_in	<= address(1);
							when 31 =>	asdo_in	<= address(0);								
							when 32 =>	asdo_in	<= PI_DATA(24);
											DPM_ADDR_r	<= DPM_ADDR_r + 1;
							when 33 =>	asdo_in	<= PI_DATA(25);
							when 34 =>	asdo_in	<= PI_DATA(26);
							when 35 =>	asdo_in	<= PI_DATA(27);
							when 36 =>	asdo_in	<= PI_DATA(28);
							when 37 =>	asdo_in	<= PI_DATA(29);
							when 38 =>	asdo_in	<= PI_DATA(30);
							when 39 =>	asdo_in	<= PI_DATA(31);
											byte 			<= byte + 1;
							when 40 =>	asdo_in	<= PI_DATA(16);
							when 41 =>	asdo_in	<= PI_DATA(17);
							when 42 =>	asdo_in	<= PI_DATA(18);
							when 43 =>	asdo_in	<= PI_DATA(19);
							when 44 =>	asdo_in	<= PI_DATA(20);
							when 45 =>	asdo_in	<= PI_DATA(21);
							when 46 =>	asdo_in	<= PI_DATA(22);
							when 47 =>	asdo_in	<= PI_DATA(23);
											byte 			<= byte + 1;
							when 48 =>	asdo_in	<= PI_DATA(8);
							when 49 =>	asdo_in	<= PI_DATA(9);
							when 50 =>	asdo_in	<= PI_DATA(10);
							when 51 =>	asdo_in	<= PI_DATA(11);
							when 52 =>	asdo_in	<= PI_DATA(12);
							when 53 =>	asdo_in	<= PI_DATA(13);
							when 54 =>	asdo_in	<= PI_DATA(14);
							when 55 =>	asdo_in	<= PI_DATA(15);
											byte 			<= byte + 1;
							when 56 =>	asdo_in	<= PI_DATA(0);
							when 57 =>	asdo_in	<= PI_DATA(1);
							when 58 =>	asdo_in	<= PI_DATA(2);
							when 59 =>	asdo_in	<= PI_DATA(3);
							when 60 =>	asdo_in	<= PI_DATA(4);
							when 61 =>	asdo_in	<= PI_DATA(5);
							when 62 =>	asdo_in	<= PI_DATA(6);
							when 63 =>	asdo_in	<= PI_DATA(7);
											PI_DATA		<= DPM_Q;
											byte 			<= byte + 1;
											counter 		<= 32;
											if (byte = 255) then
												STATE 		<= s_done;	
											end if;
							when others =>   
											STATE 		<= s_idle;	
						end case;	

			when	S_OP_03	 =>
						counter 			<= counter + 1;
						ncso_in 			<= '0';
						STORE_DATA		<= '0';
						DPM_WREN_dly	<= '1';
						CASE counter IS
							when 0 => 	asdo_in	<= opcode(7);
							when 1 =>	asdo_in	<= opcode(6);
							when 2 =>	asdo_in	<= opcode(5);
							when 3 =>	asdo_in	<= opcode(4);
							when 4 =>	asdo_in	<= opcode(3);
							when 5 =>	asdo_in	<= opcode(2);
							when 6 =>	asdo_in	<= opcode(1);
							when 7 =>	asdo_in	<= opcode(0);
							when 8 =>	asdo_in	<= address(23);
							when 9 =>	asdo_in	<= address(22);
							when 10 =>	asdo_in	<= address(21);
							when 11 =>	asdo_in	<= address(20);
							when 12 =>	asdo_in	<= address(19);
							when 13 =>	asdo_in	<= address(18);
							when 14 =>	asdo_in	<= address(17);
							when 15 =>	asdo_in	<= address(16);
							when 16 =>	asdo_in	<= address(15);
							when 17 =>	asdo_in	<= address(14);
							when 18 =>	asdo_in	<= address(13);
							when 19 =>	asdo_in	<= address(12);
							when 20 =>	asdo_in	<= address(11);
							when 21 =>	asdo_in	<= address(10);
							when 22 =>	asdo_in	<= address(9);
							when 23 =>	asdo_in	<= address(8);
							when 24 =>	asdo_in	<= address(7);
							when 25 =>	asdo_in	<= address(6);
							when 26 =>	asdo_in	<= address(5);
							when 27 =>	asdo_in	<= address(4);
							when 28 =>	asdo_in	<= address(3);
							when 29 =>	asdo_in	<= address(2);
							when 30 =>	asdo_in	<= address(1);
							when 31 =>	asdo_in	<= address(0);		
							when 32 =>  STATE 		<= S_OP_03;
							when 33 =>	PO_DATA(24)	<=	data0_out;
							when 34 =>	PO_DATA(25)	<=	data0_out;
							when 35 =>	PO_DATA(26)	<=	data0_out;
							when 36 =>	PO_DATA(27)	<=	data0_out;
							
							when 37 =>	PO_DATA(28)	<=	data0_out;
							when 38 =>	PO_DATA(29)	<=	data0_out;
							when 39 =>	PO_DATA(30)	<=	data0_out;
							when 40 =>	PO_DATA(31)	<=	data0_out;	
											if(byte /= 0) then
												DPM_ADDR_r	<= DPM_ADDR_r + 1;
											end if;
											byte 			<= byte + 1;
							when 41 =>	PO_DATA(16)	<=	data0_out;
							when 42 =>	PO_DATA(17)	<=	data0_out;
							when 43 =>	PO_DATA(18)	<=	data0_out;
							when 44 =>	PO_DATA(19)	<=	data0_out;
							
							when 45 =>	PO_DATA(20)	<=	data0_out;
							when 46 =>	PO_DATA(21)	<=	data0_out;
							when 47 =>	PO_DATA(22)	<=	data0_out;
							when 48 =>	PO_DATA(23)	<=	data0_out;							
											byte 			<= byte + 1;
							when 49 =>	PO_DATA(8)	<=	data0_out;
							when 50 =>	PO_DATA(9)	<=	data0_out;
							when 51 =>	PO_DATA(10)	<=	data0_out;
							when 52 =>	PO_DATA(11)	<=	data0_out;
							
							when 53 =>	PO_DATA(12)	<=	data0_out;
							when 54 =>	PO_DATA(13)	<=	data0_out;
							when 55 =>	PO_DATA(14)	<=	data0_out;
							when 56 =>	PO_DATA(15)	<=	data0_out;							
											byte 			<= byte + 1;
							when 57 =>	PO_DATA(0)	<=	data0_out;
							when 58 =>	PO_DATA(1)	<=	data0_out;
							when 59 =>	PO_DATA(2)	<=	data0_out;
							when 60 =>	PO_DATA(3)	<=	data0_out;
						
							when 61 =>	PO_DATA(4)	<=	data0_out;
							when 62 =>	PO_DATA(5)	<=	data0_out;
							when 63 =>	PO_DATA(6)	<=	data0_out;
							when 64 =>	PO_DATA(7)	<=	data0_out;							
											STORE_DATA	<= '1';
											if (byte = 255) then
												STATE 		<= s_done;	
											else
												byte 			<= byte + 1;
												counter 		<= 33;
											end if;
							when others =>   
											STATE 		<= s_idle;	
						end case;	
						if( STORE_DATA	= '1') then
							DPM_D				<= PO_DATA;
							DPM_WREN_dly	<= '1';
						end if;	
				when s_done => 
					DPM_WREN_dly	<= '0';
					counter  		<=  0;
					ncso_in			<=	'1';			
					asdo_in			<= '0';
					byte 				<=  0;
					if( STORE_DATA	= '1') then
						DPM_D				<= PO_DATA;
						DPM_WREN_dly	<= '1';
						STORE_DATA		<= '0';
					else
						DPM_WREN_dly	<= '0';
					end if;
					if (start  = '1' )then
						STATE 		<= s_done;
					else
						STATE 		<= s_idle;
					end if;
           when others => 
						STATE 		<= s_idle;
           end case;   
         end if;
       end process ;



END behavior;







		
