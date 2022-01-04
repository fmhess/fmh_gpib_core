-- Copyright 2017 Frank Mori Hess fmh6jj@gmail.com

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--    http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
------------------------------------------------------------------------------

-- IEEE 488.1 remote message decoder.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity remote_message_decoder is
	port(
		bus_DIO_inverted : in std_logic_vector(7 downto 0);
		bus_REN_inverted : in std_logic;
		bus_IFC_inverted : in std_logic;
		bus_SRQ_inverted : in std_logic;
		bus_EOI_inverted : in std_logic;
		bus_ATN_inverted : in std_logic;
		bus_NDAC_inverted : in std_logic;
		bus_NRFD_inverted : in std_logic;
		bus_DAV_inverted : in std_logic;
		configured_eos_character : in std_logic_vector(7 downto 0);
		enable_EOS_detection : in std_logic;
		ignore_eos_bit_7 : in std_logic;
		command_valid : in std_logic; -- pulsed
		command_invalid : in std_logic; -- pulsed
		
		ACG : out std_logic;
		ATN : out std_logic;
		DAC : out std_logic;
		DAV : out std_logic;
		DCL : out std_logic;
		END_msg : out std_logic;
		EOS : out std_logic;
		GET : out std_logic;
		GTL : out std_logic;
		IDY : out std_logic;
		IFC : out std_logic;
		LAG : out std_logic;
		LLO : out std_logic;
		MLA : out std_logic;
		MTA : out std_logic;
		MSA : out std_logic;
		NUL : out std_logic;
		OSA : out std_logic;
		OTA : out std_logic;
		PCG : out std_logic;
		PPC : out std_logic;
		PPE : out std_logic;
		PPE_sense : out std_logic;
		PPE_response_line : out std_logic_vector(2 downto 0);
		PPD : out std_logic;
		PPU : out std_logic;
		REN : out std_logic;
		RFD : out std_logic;
		RQS : out std_logic;
		SCG : out std_logic;
		SDC : out std_logic;
		SPD : out std_logic;
		SPE : out std_logic;
		SRQ : out std_logic;
		TCT : out std_logic;
		TAG : out std_logic;
		UCG : out std_logic;
		UNL : out std_logic;
		UNT : out std_logic;
		NIC : out std_logic;
		CFE : out std_logic;
		CFGn : out std_logic;
		CFGn_meters : out unsigned(3 downto 0);
		unrecognized_primary_command : out std_logic
	);
 
end remote_message_decoder;
 
architecture remote_message_decoder_arch of remote_message_decoder is

	signal ACG_buffer : std_logic;
	signal CFGn_buffer : std_logic;
	signal LAG_buffer : std_logic;
	signal TAG_buffer : std_logic;
	signal SCG_buffer : std_logic;
	signal UCG_buffer : std_logic;
	signal UNT_buffer : std_logic;
	signal MTA_buffer : std_logic;
	signal MSA_buffer : std_logic;
	signal PPE_buffer : std_logic;

begin

	ACG_buffer <= '1' when not bus_DIO_inverted(6 downto 4) = "000" and not bus_ATN_inverted = '1' else
		'0';
	ACG <= ACG_buffer;
	
	ATN <= not bus_ATN_inverted;
	DAC <= to_X01(bus_NDAC_inverted);
	DAV <= not bus_DAV_inverted;
	DCL <= '1' when UCG_buffer = '1' and not bus_DIO_inverted(3 downto 0) = "0100" and not bus_ATN_inverted = '1' else
		'0';
	END_msg <= to_X01(bus_ATN_inverted) and not bus_EOI_inverted;
	EOS <= '1' when enable_EOS_detection = '1' and EOS_match(not bus_DIO_inverted, configured_eos_character, ignore_eos_bit_7)
		and to_X01(bus_ATN_inverted) = '1' else
		'0';
	GET <= '1' when ACG_buffer = '1' and not bus_DIO_inverted(3 downto 0) = "1000" and not bus_ATN_inverted = '1' else
		'0';
	GTL <= '1' when ACG_buffer = '1' and not bus_DIO_inverted(3 downto 0) = "0001" and not bus_ATN_inverted = '1' else
		'0';
	IDY <= not bus_EOI_inverted;
	IFC <= not bus_IFC_inverted;

	LAG_buffer <= '1' when not bus_DIO_inverted(6 downto 5) = "01" and not bus_ATN_inverted = '1' else
		'0';
	LAG <= LAG_buffer;
	
	LLO <= '1' when UCG_buffer = '1' and not bus_DIO_inverted(3 downto 0) = "0001" and not bus_ATN_inverted = '1' else
		'0';
	MLA <= '1' when LAG_buffer = '1' and 
		command_valid = '1' else
		'0';

	MTA_buffer <= '1' when TAG_buffer = '1' and 
		command_valid = '1' else
		'0';
	MTA <= MTA_buffer;

	MSA_buffer <= '1' when SCG_buffer = '1' and 
		command_valid = '1' else
		'0';
	MSA <= MSA_buffer;

	OSA <= SCG_buffer and command_invalid;
	OTA <= TAG_buffer and (command_invalid or UNT_buffer);
	PCG <= ACG_buffer or UCG_buffer or LAG_buffer or TAG_buffer;
	PPC <= '1' when ACG_buffer = '1' and not bus_DIO_inverted(3 downto 0) = "0101" and not bus_ATN_inverted = '1' else
		'0';

	PPE_buffer <= '1' when SCG_buffer = '1' and not bus_DIO_inverted(4) = '0' and not bus_ATN_inverted = '1' else
		'0';
	PPE <= PPE_buffer;
	
	PPE_sense <= not bus_DIO_inverted(3) when PPE_buffer = '1' and not bus_ATN_inverted = '1' else
		'L';
	PPE_response_line <= not bus_DIO_inverted(2 downto 0) when PPE_buffer = '1' and not bus_ATN_inverted = '1' else
		"LLL";
	PPD <= '1' when SCG_buffer = '1' and not bus_DIO_inverted(4) = '1' and not bus_ATN_inverted = '1' else
		'0';
	PPU <= '1' when UCG_buffer = '1' and not bus_DIO_inverted(3 downto 0) = "0101" and not bus_ATN_inverted = '1' else
		'0';
	REN <= not bus_REN_inverted;
	RFD <= to_X01(bus_NRFD_inverted);
	RQS <= not bus_DIO_inverted(6) and to_X01(bus_ATN_inverted);
	
	SCG_buffer <= '1' when not bus_DIO_inverted(6 downto 5) = "11" and not bus_ATN_inverted = '1' else
		'0';
	SCG <= SCG_buffer;

	SDC <= '1' when ACG_buffer = '1' and not bus_DIO_inverted(3 downto 0) = "0100" and not bus_ATN_inverted = '1' else
		'0';
	SPD <= '1' when UCG_buffer = '1' and not bus_DIO_inverted(3 downto 0) = "1001" and not bus_ATN_inverted = '1' else
		'0';
	SPE <= '1' when UCG_buffer = '1' and not bus_DIO_inverted(3 downto 0) = "1000" and not bus_ATN_inverted = '1' else
		'0';
	SRQ <= not bus_SRQ_inverted;
	TCT <= '1' when ACG_buffer = '1' and not bus_DIO_inverted(3 downto 0) = "1001" and not bus_ATN_inverted = '1' else
		'0';
	
	TAG_buffer <= '1' when not bus_DIO_inverted(6 downto 5) = "10" and not bus_ATN_inverted = '1' else
		'0';
	TAG <= TAG_buffer;
		
	UCG_buffer <= '1' when not bus_DIO_inverted(6 downto 4) = "001" and not bus_ATN_inverted = '1' else
		'0';
	UCG <= UCG_buffer;
		
	UNL <= '1' when LAG_buffer = '1' and not bus_DIO_inverted(4 downto 0) = "11111" else
		'0';

	UNT_buffer <= '1' when TAG_buffer = '1' and not bus_DIO_inverted(4 downto 0) = "11111" else
		'0';
	UNT <= UNT_buffer;
	
	NIC <= not bus_NRFD_inverted;
	CFE <= '1' when UCG_buffer = '1' and not bus_DIO_inverted(3 downto 0) = "1111" and not bus_ATN_inverted = '1' else
		'0';

	CFGn_buffer <= '1' when SCG_buffer = '1' and not bus_DIO_inverted(4) = '0' 
		and not bus_ATN_inverted = '1' and not bus_DIO_inverted(3 downto 0) /= X"0" else
		'0';
	CFGn <= CFGn_buffer;
	CFGn_meters <= unsigned(not bus_DIO_inverted(3 downto 0)) when CFGn_buffer = '1' else
		(others => '0');
		
	NUL <= '1' when not bus_DIO_inverted = X"00" else '0';
	
	unrecognized_primary_command <= '1' when not bus_ATN_inverted = '1' and
			is_unrecognized_primary_command(not bus_DIO_inverted) else
		'0';
	
	
end remote_message_decoder_arch;
