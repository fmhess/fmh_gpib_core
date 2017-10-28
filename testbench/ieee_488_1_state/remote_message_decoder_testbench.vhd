-- testbench for remote message decoder.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity remote_message_decoder_testbench is
end remote_message_decoder_testbench;
     
architecture behav of remote_message_decoder_testbench is
	signal bus_DIO : std_logic_vector(7 downto 0);
	signal bus_REN : std_logic;
	signal bus_IFC : std_logic;
	signal bus_SRQ : std_logic;
	signal bus_EOI : std_logic;
	signal bus_ATN : std_logic;
	signal bus_NDAC : std_logic;
	signal bus_NRFD : std_logic;
	signal bus_DAV : std_logic;
	signal configured_eos_character : std_logic_vector(7 downto 0);
	signal ignore_eos_bit_7 : std_logic;
	signal configured_primary_address : std_logic_vector(4 downto 0);
	signal configured_secondary_address :std_logic_vector(4 downto 0);
	signal ACG : std_logic;
	signal ATN : std_logic;
	signal DAC : std_logic;
	signal DAV : std_logic;
	signal DCL : std_logic;
	signal END_msg: std_logic;
	signal EOS: std_logic;
	signal GET : std_logic;
	signal GTL : std_logic;
	signal IDY : std_logic;
	signal IFC : std_logic;
	signal LAG : std_logic;
	signal LLO : std_logic;
	signal MLA : std_logic;
	signal MTA : std_logic;
	signal MSA : std_logic;
	signal OSA : std_logic;
	signal OTA : std_logic;
	signal PCG : std_logic;
	signal PPC : std_logic;
	signal PPE : std_logic;
	signal PPE_sense : std_logic;
	signal PPE_response_line : std_logic_vector(2 downto 0);
	signal PPD : std_logic;
	signal PPU : std_logic;
	signal REN : std_logic;
	signal RFD : std_logic;
	signal RQS : std_logic;
	signal SCG : std_logic;
	signal SDC : std_logic;
	signal SPD : std_logic;
	signal SPE : std_logic;
	signal SRQ : std_logic;
	signal TCT : std_logic;
	signal TAG : std_logic;
	signal UCG : std_logic;
	signal UNL : std_logic;
	signal UNT : std_logic;
	signal NIC : std_logic;
	signal CFE : std_logic;
	
	shared variable test_finished : boolean := false;

	begin
	my_decoder: entity work.remote_message_decoder 
		port map (
			bus_DIO => bus_DIO,
			bus_REN => bus_REN,
			bus_IFC => bus_IFC,
			bus_SRQ => bus_SRQ,
			bus_EOI => bus_EOI,
			bus_ATN => bus_ATN,
			bus_NDAC => bus_NDAC,
			bus_NRFD => bus_NRFD,
			bus_DAV => bus_DAV,
			configured_eos_character => configured_eos_character,
			ignore_eos_bit_7 => ignore_eos_bit_7,
			configured_primary_address => configured_primary_address,
			configured_secondary_address => configured_secondary_address,
			ACG => ACG,
			ATN => ATN,
			DAC => DAC,
			DAV => DAV,
			DCL => DCL,
			END_msg => END_msg,
			EOS => EOS,
			GET => GET,
			GTL => GTL,
			IDY => IDY,
			IFC => IFC,
			LAG => LAG,
			LLO => LLO,
			MLA => MLA,
			MTA => MTA,
			MSA => MSA,
			OSA => OSA,
			OTA => OTA,
			PCG => PCG,
			PPC => PPC,
			PPE => PPE,
			PPE_sense => PPE_sense,
			PPE_response_line => PPE_response_line,
			PPD => PPD,
			PPU => PPU,
			REN => REN,
			RFD => RFD,
			RQS => RQS,
			SCG => SCG,
			SDC => SDC,
			SPD => SPD,
			SPE => SPE,
			SRQ => SRQ,
			TCT => TCT,
			TAG => TAG,
			UCG => UCG,
			UNL => UNL,
			UNT => UNT,
			NIC => NIC,
			CFE => CFE
		);
	
	process		
	begin
		bus_DIO <= X"00";
		bus_REN <= 'L';
		bus_IFC <= 'L';
		bus_SRQ <= 'L';
		bus_EOI <= 'L';
		bus_ATN <= 'L';
		bus_NDAC <= 'L';
		bus_NRFD <= 'L';
		bus_DAV <= 'L';
		configured_eos_character <= X"00";
		ignore_eos_bit_7 <= '0';
		configured_primary_address <= "11111";
		configured_secondary_address <= "11111";
				
		wait for 100ns;	

		bus_DIO <= X"0f";		
		bus_ATN <= '1';		
		wait for 100ns;	
		assert ACG = '1';
		assert ATN = '1';
		
		bus_DIO <= "10010100";		
		wait for 100ns;	
		assert ACG = '0';
		assert DCL = '1';

		configured_eos_character <= X"9b";
		ignore_eos_bit_7 <= '1';
		bus_DIO <= X"1b";		
		bus_ATN <= '0';
		wait for 100ns;	
		assert EOS = '1';
		
		ignore_eos_bit_7 <= '0';
		wait for 100ns;	
		assert EOS = '0';
		
		bus_ATN <= '0';
		bus_EOI <= '1';
		wait for 100ns;	
		assert END_msg = '1';

		bus_EOI <= '0';
		bus_ATN <= '1';
		bus_DIO <= "11100101";
		wait for 100ns;	
		assert PPE = '1';
		assert PPE_sense = '0';
		assert to_bitvector(PPE_response_line) = "101";
		
		wait for 100ns;	
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;
end behav;
