-- Some shared code for testbenches
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package test_common is
	procedure wait_for_ticks (num_clock_cycles : in integer;
		signal clock : in std_logic);

	-- write a byte from gpib bus to device
	procedure gpib_write (data_byte : in std_logic_vector(7 downto 0);
		assert_eoi : in boolean;
		signal DIO_inverted : out std_logic_vector(7 downto 0);
		signal DAV_inverted : out std_logic;
		signal EOI_inverted : out std_logic;
		signal NDAC_inverted : in std_logic;
		signal NRFD_inverted : in std_logic
	);

	-- read a byte sent from device to gpib bus
	procedure gpib_read (data_byte : out std_logic_vector(7 downto 0);
		eoi : out std_logic;
		signal DIO_inverted : in std_logic_vector(7 downto 0);
		signal DAV_inverted : in std_logic;
		signal EOI_inverted : in std_logic;
		signal NDAC_inverted : out std_logic;
		signal NRFD_inverted : out std_logic
	);

	procedure gpib_setup_bus (assert_ATN : boolean; 
		talk_enable : in boolean;
		signal DIO_inverted : out std_logic_vector(7 downto 0);
		signal ATN_inverted : out std_logic;
		signal DAV_inverted : out std_logic;
		signal EOI_inverted : out std_logic;
		signal NDAC_inverted : out std_logic;
		signal NRFD_inverted : out std_logic;
		signal SRQ_inverted : out std_logic
	);
	
	-- write a byte from host to device register
	procedure host_write (addr: in std_logic_vector;
		byte : in std_logic_vector(7 downto 0);
		signal clock : in std_logic;
		signal chip_select_inverted : in std_logic;
		signal address : out std_logic_vector;
		signal write_inverted : in std_logic;
		signal host_data_bus : out std_logic_vector(7 downto 0)
	);

	-- read a byte from device register
	procedure host_read (addr: in std_logic_vector;
		result: out std_logic_vector(7 downto 0);
		signal clock : in std_logic;
		signal chip_select_inverted : out std_logic;
		signal address : out std_logic_vector;
		signal read_inverted : out std_logic;
		signal host_data_bus : in std_logic_vector(7 downto 0)
	);
	
end test_common;

package body test_common is

	-- wait for N clock cycles
	procedure wait_for_ticks (num_clock_cycles : in integer;
		signal clock : in std_logic) is
	begin
		for i in 1 to num_clock_cycles loop
			wait until rising_edge(clock);
		end loop;
	end procedure wait_for_ticks;

	procedure gpib_write (data_byte : in std_logic_vector(7 downto 0);
		assert_eoi : in boolean;
		signal DIO_inverted : out std_logic_vector(7 downto 0);
		signal DAV_inverted : out std_logic;
		signal EOI_inverted : out std_logic;
		signal NDAC_inverted : in std_logic;
		signal NRFD_inverted : in std_logic
	) is
	begin
		if (to_X01(NRFD_inverted) /= '1' or to_X01(NDAC_inverted) /= '0') then
				wait until (to_X01(NRFD_inverted) = '1' and to_X01(NDAC_inverted) = '0');
		end if;
		wait for 110ns;
		DIO_inverted <= not data_byte;
		if assert_eoi then
				EOI_inverted <= '0';
		else 
			EOI_inverted <= 'H';
		end if;
		wait for 510ns;
		DAV_inverted <='0';
		if (to_X01(NRFD_inverted) /= '0' or to_X01(NDAC_inverted) /= '1') then
				wait until (to_X01(NRFD_inverted) = '0' and to_X01(NDAC_inverted) = '1');
		end if;
		wait for 110ns;
		DAV_inverted <='H';
		EOI_inverted <= 'H';
		DIO_inverted <= "HHHHHHHH";
		if (to_X01(NDAC_inverted) /= '1') then
				wait until (to_X01(NDAC_inverted) = '1');
		wait for 110ns;
		end if;
	end procedure gpib_write;

	procedure gpib_read (data_byte : out std_logic_vector(7 downto 0);
		eoi : out std_logic;
		signal DIO_inverted : in std_logic_vector(7 downto 0);
		signal DAV_inverted : in std_logic;
		signal EOI_inverted : in std_logic;
		signal NDAC_inverted : out std_logic;
		signal NRFD_inverted : out std_logic
	) is
	begin
		wait for 110ns;
		NDAC_inverted <= '0';
		NRFD_inverted <= '0';
		wait for 110ns;
		NRFD_inverted <= 'H';
		if (to_bit(DAV_inverted) /= '0') then
				wait until (to_bit(DAV_inverted) = '0');
		end if;
		wait for 110ns;
		NRFD_inverted <= '0';
		data_byte := not DIO_inverted;
		eoi := not EOI_inverted;
		wait for 110ns;
		NDAC_inverted <= 'H';
		if (to_bit(DAV_inverted) /= '1') then
				wait until (to_bit(DAV_inverted) = '1');
		end if;
		wait for 110ns;
		NRFD_inverted <= 'H';
		wait for 110ns;
		NDAC_inverted <= 'H';
		wait for 110ns;
	end procedure gpib_read;

	procedure gpib_setup_bus (assert_ATN : boolean; 
		talk_enable : in boolean;
		signal DIO_inverted : out std_logic_vector(7 downto 0);
		signal ATN_inverted : out std_logic;
		signal DAV_inverted : out std_logic;
		signal EOI_inverted : out std_logic;
		signal NDAC_inverted : out std_logic;
		signal NRFD_inverted : out std_logic;
		signal SRQ_inverted : out std_logic
	) is
	begin
		wait for 110ns;
		if assert_ATN then
			ATN_inverted <= '0';
			NDAC_inverted <= 'H';
			NRFD_inverted <= 'H';
			SRQ_inverted <= 'H';
		else
			ATN_inverted <= 'H';
		end if;
		if talk_enable then
			NDAC_inverted <= 'Z';
			NRFD_inverted <= 'Z';
		else
			DIO_inverted <= (others => 'Z');
			DAV_inverted <= 'Z';
			EOI_inverted <= 'Z';
		end if;
		wait for 110ns;
	end procedure gpib_setup_bus;
	
	procedure host_write (addr: in std_logic_vector;
		byte : in std_logic_vector(7 downto 0);
		signal clock : in std_logic;
		signal chip_select_inverted : out std_logic;
		signal address : out std_logic_vector;
		signal write_inverted : out std_logic;
		signal host_data_bus : out std_logic_vector(7 downto 0)
	) is
	begin
		wait until rising_edge(clock);
		write_inverted <= '0';
		chip_select_inverted <= '0';
		address <= addr;
		host_data_bus <= byte;
		wait_for_ticks(2, clock);

		write_inverted <= '1';
		chip_select_inverted <= '1';
		for i in address'LOW to address'HIGH loop
			address(i) <= '0';
		end loop;
		host_data_bus <= (others => 'Z');
		wait until rising_edge(clock);
	end procedure host_write;

	procedure host_read (addr: in std_logic_vector;
		result: out std_logic_vector(7 downto 0);
		signal clock : in std_logic;
		signal chip_select_inverted : out std_logic;
		signal address : out std_logic_vector;
		signal read_inverted : out std_logic;
		signal host_data_bus : in std_logic_vector(7 downto 0)
	) is
	begin
		wait until rising_edge(clock);
		read_inverted <= '0';
		chip_select_inverted <= '0';
		address <= addr;
		wait_for_ticks(3, clock);

		read_inverted <= '1';
		chip_select_inverted <= '1';
		for i in address'LOW to address'HIGH loop
			address(i) <= '0';
		end loop;
		result := host_data_bus;
		wait until rising_edge(clock);
	end procedure host_read;
end package body test_common;
