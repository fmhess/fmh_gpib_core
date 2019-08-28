-- IEEE 488.1 configuration (CF) interface function.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2019


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_CF is
	generic( num_counter_bits : in integer := 8);
	port(
		clock : in std_logic;
		acceptor_handshake_state : in AH_state;
		CFE : in std_logic;
		CFGn : in std_logic;
		CFGn_meters : in unsigned (3 downto 0);
		PCG : in std_logic;
		pon : in std_logic;

		configuration_state : out CF_state_p1;
		num_meters : out unsigned (3 downto 0);
		noninterlocked_configuration_state : out CF_state_p2
	);
 
end interface_function_CF;
 
architecture interface_function_CF_arch of interface_function_CF is
 
	signal noninterlocked_configuration_state_buffer : CF_state_p2;
begin
 
	noninterlocked_configuration_state <= noninterlocked_configuration_state_buffer;
	
	process(pon, clock) 
	begin
		if pon = '1' then
			configuration_state <= CNCS;
			noninterlocked_configuration_state_buffer <= NCIS;
			num_meters <= to_unsigned(0, num_meters'LENGTH);
		elsif rising_edge(clock) then
			
			if (acceptor_handshake_state = ACDS and to_X01(CFE) = '1') then
				configuration_state <= CNCS;
				num_meters <= to_unsigned(0, num_meters'LENGTH);
			elsif noninterlocked_configuration_state_buffer = NCAS and acceptor_handshake_state = ACDS then
				configuration_state <= CnnS;
				num_meters <= CFGn_meters;
				assert CFGn_meters /= to_unsigned(0, num_meters'LENGTH); 
			end if;

			case noninterlocked_configuration_state_buffer is
				when NCIS =>
					if (acceptor_handshake_state = ACDS and to_X01(CFE) = '1') then
						noninterlocked_configuration_state_buffer <= NCAS;
					end if;
				when NCAS =>
					if acceptor_handshake_state = ACDS and to_X01(PCG) = '1' and to_X01(CFE) = '0' then
						noninterlocked_configuration_state_buffer <= NCIS;
					end if;
			end case;
		end if;
	end process;
end interface_function_CF_arch;
