-- this fifo testbench is based on public domain code from
-- http://www.deathbylogic.com/2013/07/vhdl-standard-fifo
--

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use work.std_fifo;

ENTITY std_fifo_testbench IS
END std_fifo_testbench;

ARCHITECTURE behavior OF std_fifo_testbench IS 

	--Inputs
	signal CLK		: std_logic := '0';
	signal RST		: std_logic := '0';
	signal DataIn	: std_logic_vector(7 downto 0) := (others => '0');
	signal ReadAck	: std_logic := '0';
	signal WriteEn	: std_logic := '0';
	
	--Outputs
	signal DataOut	: std_logic_vector(7 downto 0);
	signal Empty	: std_logic;
	signal Full		: std_logic;
	signal Contents		: natural range 0 to 16;
	
	-- Clock period definitions
	constant CLK_period : time := 10 ns;
	shared variable read_process_finished : boolean := false;
	shared variable write_process_finished : boolean := false;
BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: entity work.STD_FIFO
		GENERIC MAP ( DATA_WIDTH => 8,
			FIFO_DEPTH => 16
		)
		PORT MAP (
			CLK		=> CLK,
			RST		=> RST,
			DataIn	=> DataIn,
			WriteEn	=> WriteEn,
			ReadAck	=> ReadAck,
			DataOut	=> DataOut,
			Full	=> Full,
			Empty	=> Empty,
			Contents => Contents
		);
	
	-- Clock process definitions
	CLK_process :process
	begin
		if(read_process_finished and write_process_finished) then
			wait;
		end if;

		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
	end process;
	
	-- Reset process
	rst_proc : process
	begin
	wait for CLK_period * 5;
		
		RST <= '1';
		
		wait for CLK_period * 5;
		
		RST <= '0';
		
		wait;
	end process;
	
	-- Write process
	wr_proc : process
		variable counter : unsigned (7 downto 0) := (others => '0');
	begin		
		wait for CLK_period * 20;

		for i in 1 to 32 loop
			counter := counter + 1;
			
			DataIn <= std_logic_vector(counter);
			
			wait for CLK_period * 1;
			
			WriteEn <= '1';
			
			wait for CLK_period * 1;
		
			WriteEn <= '0';
		end loop;
		
		wait for clk_period * 20;
		
		for i in 1 to 32 loop
			counter := counter + 1;
			
			DataIn <= std_logic_vector(counter);
			
			wait for CLK_period * 1;
			
			WriteEn <= '1';
			
			wait for CLK_period * 1;
			
			WriteEn <= '0';
		end loop;
		
		assert false report "end of write process" severity note;
		write_process_finished := true;
		wait;
	end process;
	
	-- Read process
	rd_proc : process
	begin
		wait for CLK_period * 20;
		
		wait for CLK_period * 40;
			
		ReadAck <= '1';
		
		wait for CLK_period * 60;
		
		ReadAck <= '0';
		
		wait for CLK_period * 256 * 2;
		
		ReadAck <= '1';
		
		assert false report "end of read process" severity note;
		read_process_finished := true;
		wait;
	end process;

END;
