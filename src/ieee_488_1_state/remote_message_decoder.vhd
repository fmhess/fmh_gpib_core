-- IEEE 488.1 remote message decoder.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_states.all;

entity remote_message_decoder is
	port(
		bus_DIO : in std_logic_vector(7 downto 0);
		bus_REN : in std_logic;
		bus_IFC : in std_logic;
		bus_SRQ : in std_logic;
		bus_EOI : in std_logic;
		bus_ATN : in std_logic;
		bus_NDAC : in std_logic;
		bus_NRFD : in std_logic;
		bus_DAV : in std_logic;
		configured_eos_character : in std_logic_vector(7 downto 0);
		ignore_eos_bit_7 : in std_logic;
		configured_primary_address : in std_logic_vector(4 downto 0);
		configured_secondary_address : in std_logic_vector(4 downto 0);
		
		ACG : out std_logic;
		ATN : out std_logic;
		DAC : out std_logic;
		DAV : out std_logic;
		DCL : out std_logic;
		END_msg: out std_logic;
		EOS: out std_logic;
		GET : out std_logic;
		GTL : out std_logic;
		IDY : out std_logic;
		IFC : out std_logic;
		LAG : out std_logic;
		LLO : out std_logic;
		MLA : out std_logic;
		MTA : out std_logic;
		MSA : out std_logic;
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
		CFE : out std_logic
	);
 
end remote_message_decoder;
 
architecture remote_message_decoder_arch of remote_message_decoder is

	signal ACG_buffer : std_logic;
	signal LAG_buffer : std_logic;
	signal TAG_buffer : std_logic;
	signal SCG_buffer : std_logic;
	signal UCG_buffer : std_logic;
	signal MTA_buffer : std_logic;
	signal MSA_buffer : std_logic;
	signal PPE_buffer : std_logic;

begin

	ACG_buffer <= '1' when to_bitvector(bus_DIO(7 downto 5)) = "000" and to_bit(bus_ATN) = '1'else
		'0';
	ACG <= ACG_buffer;
	
	ATN <= bus_ATN;
	DAC <= not bus_NDAC;
	DAV <= bus_DAV;
	DCL <= '1' when UCG_buffer = '1' and to_bitvector(bus_DIO(3 downto 0)) = "0100" and to_bit(bus_ATN) = '1' else
		'0';
	END_msg <= not bus_ATN and bus_EOI;
	EOS <= '1' when  
		to_bitvector(bus_DIO(6 downto 0)) = to_bitvector(configured_eos_character(6 downto 0)) and
		(to_bit(ignore_eos_bit_7) = '1' or to_bit(bus_DIO(7)) = to_bit(configured_eos_character(7))) and
		bus_ATN = '0' else
		'0';
	GET <= '1' when ACG_buffer <= '1' and to_bitvector(bus_DIO(3 downto 0)) = "1000" and to_bit(bus_ATN) = '1' else
		'0';
	GTL <= '1' when ACG_buffer <= '1' and to_bitvector(bus_DIO(3 downto 0)) = "0001" and to_bit(bus_ATN) = '1' else
		'0';
	IDY <= bus_EOI;
	IFC <= bus_IFC;

	LAG_buffer <= '1' when to_bitvector(bus_DIO(6 downto 5)) = "01" and to_bit(bus_ATN) = '1' else
		'0';
	LAG <= LAG_buffer;
	
	LLO <= '1' when UCG_buffer = '1' and to_bitvector(bus_DIO(3 downto 0)) = "0001" and to_bit(bus_ATN) = '1' else
		'0';
	MLA <= '1' when LAG_buffer = '1' and 
		to_bitvector(bus_DIO(4 downto 0)) = to_bitvector(configured_primary_address) and
		to_bitvector(configured_primary_address) /= NO_ADDRESS_CONFIGURED and
		to_bit(bus_ATN) = '1' else
		'0';

	MTA_buffer <= '1' when TAG_buffer = '1' and 
		to_bitvector(bus_DIO(4 downto 0)) = to_bitvector(configured_primary_address) and
		to_bitvector(configured_primary_address) /= NO_ADDRESS_CONFIGURED and
		to_bit(bus_ATN) = '1' else
		'0';
	MTA <= MTA_buffer;

	MSA_buffer <= '1' when SCG_buffer = '1' and 
		to_bitvector(bus_DIO(4 downto 0)) = to_bitvector(configured_secondary_address) and
		to_bitvector(configured_secondary_address) /= NO_ADDRESS_CONFIGURED and
		to_bit(bus_ATN) = '1' else
		'0';
	MSA <= MSA_buffer;

	OSA <= SCG_buffer and not MSA_buffer;
	OTA <= TAG_buffer and not MTA_buffer;
	PCG <= ACG_buffer or UCG_buffer or LAG_buffer or TAG_buffer;
	PPC <= '1' when ACG_buffer <= '1' and to_bitvector(bus_DIO(3 downto 0)) = "0101" and to_bit(bus_ATN) = '1' else
		'0';

	PPE_buffer <= '1' when to_bitvector(bus_DIO(6 downto 4)) = "110" and to_bit(bus_ATN) = '1' else
		'0';
	PPE <= PPE_buffer;
	
	PPE_sense <= bus_DIO(3) when PPE_buffer = '1' and to_bit(bus_ATN) = '1' else
		'Z';
	PPE_response_line <= bus_DIO(2 downto 0) when PPE_buffer = '1' and to_bit(bus_ATN) = '1' else
		"ZZZ";
	PPD <= '1' when to_bitvector(bus_DIO(6 downto 4)) = "111" and to_bit(bus_ATN) = '1' else
		'0';
	PPU <= '1' when UCG_buffer = '1' and to_bitvector(bus_DIO(3 downto 0)) = "0101" and to_bit(bus_ATN) = '1' else
		'0';
	REN <= bus_REN;
	RFD <= not bus_NRFD;
	RQS <= bus_DIO(6) and not bus_ATN;
	
	SCG_buffer <= '1' when to_bitvector(bus_DIO(6 downto 5)) = "11" and to_bit(bus_ATN) = '1' else
		'0';
	SCG <= SCG_buffer;

	SDC <= '1' when ACG_buffer <= '1' and to_bitvector(bus_DIO(3 downto 0)) = "0100" and to_bit(bus_ATN) = '1' else
		'0';
	SPD <= '1' when UCG_buffer = '1' and to_bitvector(bus_DIO(3 downto 0)) = "1001" and to_bit(bus_ATN) = '1' else
		'0';
	SPE <= '1' when UCG_buffer = '1' and to_bitvector(bus_DIO(3 downto 0)) = "1000" and to_bit(bus_ATN) = '1' else
		'0';
	SRQ <= bus_SRQ;
	TCT <= '1' when ACG_buffer <= '1' and to_bitvector(bus_DIO(3 downto 0)) = "1001" and to_bit(bus_ATN) = '1' else
		'0';
	
	TAG_buffer <= '1' when to_bitvector(bus_DIO(6 downto 5)) = "10" and to_bit(bus_ATN) = '1' else
		'0';
	TAG <= TAG_buffer;
		
	UCG_buffer <= '1' when to_bitvector(bus_DIO(6 downto 4)) = "001" and to_bit(bus_ATN) = '1' else
		'0';
	UCG <= UCG_buffer;
		
	UNL <= '1' when to_bitvector(bus_DIO(6 downto 0)) = "0111111" and to_bit(bus_ATN) = '1' else
		'0';
	UNT <= '1' when to_bitvector(bus_DIO(6 downto 0)) = "1011111" and to_bit(bus_ATN) = '1' else
		'0';
	NIC <= bus_NRFD;
	CFE <= '1' when UCG_buffer = '1' and to_bitvector(bus_DIO(3 downto 0)) = "1111" and to_bit(bus_ATN) = '1' else
		'0';
	
end remote_message_decoder_arch;
