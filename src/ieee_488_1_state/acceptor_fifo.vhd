-- A FIFO to hold data bytes (and EOI/EOS state) coming from noninterlocked AHE 
-- handshake.  IEEE 488.1 requires a 3 entry fifo to hold such data, since
-- the noninterlocked flow of data cannot be turned off instantly.  This
-- entity owns the rft "ready for three" local message.  This FIFO is
-- intended to sit between the physical GPIB bus lines and the rest of the
-- GPIB logic (rather than between the host computer bus and GPIB logic).
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.std_fifo;

entity acceptor_fifo is
	generic(
		-- fifo depth must be at least 4 to enable noninterlocked acceptor
		-- handshaking.  Setting it slightly larger helps avoid slowdowns
		-- caused by rft going false whenever the fifo is non-empty.
		fifo_depth : positive := 5
	);
	port(
		clock : in std_logic;
		reset : in std_logic;
		
		write_enable : in std_logic;
		data_byte_in : in std_logic_vector(7 downto 0);
		END_in : in std_logic;
		EOS_in : in std_logic;

		read_acknowledge : in std_logic;
		data_byte_out : out std_logic_vector(7 downto 0);
		END_out : out std_logic;
		EOS_out : out std_logic;

		rft : out std_logic;
		
		empty : out	std_logic;
		full : out std_logic;
		contents : out natural range 0 TO fifo_depth
	);
 
end acceptor_fifo;
 
architecture acceptor_fifo_arch of acceptor_fifo is
	signal input_entry : std_logic_vector(9 downto 0);
	signal output_entry : std_logic_vector(9 downto 0);
	signal contents_buffer : natural range 0 TO fifo_depth;
begin

	gpib_to_host_fifo: entity work.std_fifo 
		generic map(
			DATA_WIDTH => 10,
			FIFO_DEPTH => fifo_depth
		)
		port map (
			CLK => clock,
			RST => reset,
			WriteEn => write_enable,
			DataIn => input_entry,
			ReadAck => read_acknowledge,
			DataOut => output_entry,
			Empty => empty,
			Full => full,
			Contents => contents_buffer
		);
		
	input_entry(7 downto 0) <= data_byte_in;
	input_entry(8) <= END_in;
	input_entry(9) <= EOS_in;
	
	data_byte_out <= output_entry(7 downto 0);
	END_out <= output_entry(8);
	EOS_out <= output_entry(9);

	-- IEEE 488.1 has some weasly wording about how rft needs to go false
	-- before the entry into ANDS which would logically cause the
	-- "ready for three" condition to go false.  Therefore, since
	-- electronic circuits lack prescience, rtf really means 
	-- "ready for four" and we treat it as such.  We also
	rft <= '0' when fifo_depth < 4 else
		'1' when contents_buffer <= fifo_depth - 4 else
		'0';

	contents <= contents_buffer;
	
end acceptor_fifo_arch;
