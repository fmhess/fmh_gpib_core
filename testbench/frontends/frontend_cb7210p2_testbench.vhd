-- testbench for integrated interface functions.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;
use work.frontend_cb7210p2.all;

entity frontend_cb7210p2_testbench is
end frontend_cb7210p2_testbench;
     
architecture behav of frontend_cb7210p2_testbench is
	signal clock : std_logic;
	signal gpib_ATN_inverted : std_logic;
	signal gpib_DAV_inverted : std_logic;
	signal gpib_EOI_inverted : std_logic;
	signal gpib_IFC_inverted : std_logic;
	signal gpib_NDAC_inverted : std_logic;
	signal gpib_NRFD_inverted : std_logic;
	signal gpib_REN_inverted : std_logic;
	signal gpib_SRQ_inverted : std_logic;
	signal gpib_DIO_inverted : std_logic_vector(7 downto 0);
	signal chip_select_inverted : std_logic;
	signal dma_ack_inverted : std_logic;
	signal read_inverted : std_logic;
	signal reset : std_logic;
	signal address : std_logic_vector(2 downto 0);
	signal write_inverted : std_logic;
	signal tr1 : std_logic;
	signal tr2 : std_logic;
	signal tr3 : std_logic;
	signal interrupt : std_logic;
	signal dma_request : std_logic;
	signal host_data_bus : std_logic_vector(7 downto 0);
	
	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	begin
	my_frontend_cb7210p2: entity work.frontend_cb7210p2 
		port map (
			clock => clock,
			chip_select_inverted => chip_select_inverted, 
			dma_ack_inverted => dma_ack_inverted,
			read_inverted => read_inverted,
			reset => reset,
			address => address,  
			write_inverted => write_inverted, 
			tr1  => tr1,
			tr2  => tr2, 
			tr3  => tr3,
			interrupt  => interrupt, 
			dma_request  => dma_request, 
			host_data_bus_in  => host_data_bus, 
			gpib_ATN_inverted_in  => gpib_ATN_inverted,
			gpib_DAV_inverted_in  => gpib_DAV_inverted, 
			gpib_EOI_inverted_in  => gpib_EOI_inverted, 
			gpib_IFC_inverted_in  => gpib_IFC_inverted, 
			gpib_NDAC_inverted_in  => gpib_NDAC_inverted,  
			gpib_NRFD_inverted_in  => gpib_NRFD_inverted, 
			gpib_REN_inverted_in  => gpib_REN_inverted,
			gpib_SRQ_inverted_in  => gpib_SRQ_inverted, 
			gpib_DIO_inverted_in  => gpib_DIO_inverted, 
			host_data_bus_out  => host_data_bus, 
			gpib_ATN_inverted_out  => gpib_ATN_inverted,
			gpib_DAV_inverted_out  => gpib_DAV_inverted, 
			gpib_EOI_inverted_out  => gpib_EOI_inverted, 
			gpib_IFC_inverted_out  => gpib_IFC_inverted, 
			gpib_NDAC_inverted_out  => gpib_NDAC_inverted,  
			gpib_NRFD_inverted_out  => gpib_NRFD_inverted, 
			gpib_REN_inverted_out  => gpib_REN_inverted,
			gpib_SRQ_inverted_out  => gpib_SRQ_inverted, 
			gpib_DIO_inverted_out  => gpib_DIO_inverted 
		);
	
	process
	begin
		if(test_finished) then
			wait;
		end if;
		
		clock <= '0';
		wait for clock_half_period;
		clock <= '1';
		wait for clock_half_period;
	end process;

	process
		-- wait wait for a condition with a hard coded timeout to avoid infinite test loops on failure
		procedure wait_for_ticks (num_clock_cycles : in integer) is
			begin
				for i in 1 to num_clock_cycles loop
					wait until rising_edge(clock);
				end loop;
			end procedure wait_for_ticks;

		-- write a byte from gpib bus to device
		procedure gpib_write (data_byte : in std_logic_vector(7 downto 0);
			assert_eoi : in boolean) is
			begin
					gpib_NRFD_inverted <= 'Z';
					gpib_NDAC_inverted <= 'Z';
					if (to_bit(gpib_NRFD_inverted) /= '1' or to_bit(gpib_NDAC_inverted) /= '0') then
							wait until (to_bit(gpib_NRFD_inverted) = '1' and to_bit(gpib_NDAC_inverted) = '0');
					end if;
					wait for 99ns;
					gpib_DIO_inverted <= not data_byte;
					if assert_eoi then
							gpib_EOI_inverted <= '0';
					else 
						gpib_EOI_inverted <= 'H';
					end if;
					wait for 499ns;
					gpib_DAV_inverted <='0';
					if (to_bit(gpib_NRFD_inverted) /= '0' or to_bit(gpib_NDAC_inverted) /= '1') then
							wait until (to_bit(gpib_NRFD_inverted) = '0' and to_bit(gpib_NDAC_inverted) = '1');
					end if;
					wait for 99ns;
					gpib_DAV_inverted <='H';
					gpib_EOI_inverted <= 'H';
					gpib_DIO_inverted <= "HHHHHHHH";
					if (to_bit(gpib_NDAC_inverted) /= '1') then
							wait until (to_bit(gpib_NDAC_inverted) = '1');
					end if;
					wait for 99ns;
			end procedure gpib_write;

			procedure gpib_read (data_byte : out integer;
					eoi : out boolean) is
			begin
					gpib_DAV_inverted <= 'Z';
					gpib_NDAC_inverted <= '0';
					wait for 99ns;
					gpib_NRFD_inverted <= 'H';
					if (to_bit(gpib_DAV_inverted) /= '0') then
							wait until (to_bit(gpib_DAV_inverted) = '0');
					end if;
					wait for 99ns;
					gpib_NRFD_inverted <= '0';
					data_byte := to_integer(unsigned(gpib_DIO_inverted));
					eoi := to_bit(gpib_EOI_inverted) = '0';
					wait for 99ns;
					gpib_NDAC_inverted <= 'H';
					if (to_bit(gpib_DAV_inverted) /= '1') then
							wait until (to_bit(gpib_DAV_inverted) = '1');
					end if;
					wait for 99ns;
					gpib_NDAC_inverted <= 'H';
					wait for 99ns;
			end procedure gpib_read;

		variable gpib_read_result : integer;
		variable gpib_read_eoi : boolean;
	
	begin
		gpib_DIO_inverted <= "HHHHHHHH";
		gpib_REN_inverted <= 'H';
		gpib_IFC_inverted <= 'H';
		gpib_SRQ_inverted <= 'H';
		gpib_EOI_inverted <= 'H';
		gpib_ATN_inverted <= 'H';
		gpib_NDAC_inverted <= 'H';
		gpib_NRFD_inverted <= 'H';
		gpib_DAV_inverted <= 'H';
		reset <= '0';

		wait until rising_edge(clock);	
		reset <= '1';
		wait until rising_edge(clock);	
		reset <= '0';
		wait until rising_edge(clock);	
		

		wait until rising_edge(clock);	
		assert false report "end of test" severity note;
		test_finished := true;
		wait;
	end process;
end behav;
