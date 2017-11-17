-- testbench for gpib tranceiver.
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2017 Frank Mori Hess
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dma_translator_cb7210p2_to_pl330;

entity dma_translator_cb7210p2_to_pl330_testbench is
end dma_translator_cb7210p2_to_pl330_testbench;
     
architecture arch of dma_translator_cb7210p2_to_pl330_testbench is

	signal clock : std_logic;
	signal reset : std_logic;
	signal pl330_dma_cs_inverted : std_logic;
	signal pl330_dma_rd_inverted : std_logic;
	signal pl330_dma_wr_inverted :  std_logic;
	signal pl330_dma_ack : std_logic;
	signal pl330_dma_single : std_logic;
	signal pl330_dma_req : std_logic;
		
	signal cb7210p2_dma_in_request : std_logic;
	signal cb7210p2_dma_out_request : std_logic;
	signal cb7210p2_dma_read_inverted : std_logic;
	signal cb7210p2_dma_write_inverted : std_logic;
	signal cb7210p2_dma_ack_inverted : std_logic;

	constant clock_half_period : time := 50 ns;

	shared variable test_finished : boolean := false;

	-- wait wait for a condition with a hard coded timeout to avoid infinite test loops on failure
	procedure wait_for_ticks (num_clock_cycles : in integer) is
	begin
		for i in 1 to num_clock_cycles loop
			wait until rising_edge(clock);
		end loop;
	end procedure wait_for_ticks;

	begin
	my_dma_translator: entity work.dma_translator_cb7210p2_to_pl330 
		port map (
			clock => clock,
			reset => reset,
			pl330_dma_cs_inverted => pl330_dma_cs_inverted,
			pl330_dma_rd_inverted => pl330_dma_rd_inverted,
			pl330_dma_wr_inverted => pl330_dma_wr_inverted,
			pl330_dma_ack => pl330_dma_ack,
			pl330_dma_single => pl330_dma_single,
			pl330_dma_req => pl330_dma_req,
		
			cb7210p2_dma_in_request => cb7210p2_dma_in_request,
			cb7210p2_dma_out_request => cb7210p2_dma_out_request,
			cb7210p2_dma_read_inverted => cb7210p2_dma_read_inverted,
			cb7210p2_dma_write_inverted => cb7210p2_dma_write_inverted,
			cb7210p2_dma_ack_inverted => cb7210p2_dma_ack_inverted
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
	
	-- cb7210p2 process
	process
	begin
		cb7210p2_dma_in_request <= '0';
		cb7210p2_dma_out_request <= '0';
		
		reset <= '1';
		wait_for_ticks(2);
		reset <= '0';
		wait_for_ticks(1);

		-- do a dma transfer from pl330 to cb7210
		cb7210p2_dma_in_request <= '1';
		wait until cb7210p2_dma_ack_inverted = '0' and cb7210p2_dma_write_inverted = '0';
		wait_for_ticks(2);
		cb7210p2_dma_in_request <= '0';
		wait until cb7210p2_dma_ack_inverted = '1' or cb7210p2_dma_write_inverted = '1';
		wait_for_ticks(1);
		
		-- now do a dma transfer in the other direction
		
		-- do a dma transfer from cb7210 to pl330
		cb7210p2_dma_out_request <= '1';
		wait until cb7210p2_dma_ack_inverted = '0' and cb7210p2_dma_read_inverted = '0';
		wait_for_ticks(2);
		cb7210p2_dma_out_request <= '0';
		wait until cb7210p2_dma_ack_inverted <= '1' or cb7210p2_dma_read_inverted <= '1';

		wait_for_ticks(1);
		assert false report "finished cb7210p2 process" severity note;
		test_finished := true;
		wait;
	end process;

	--pl330 process
	process
	begin
		pl330_dma_cs_inverted <= '1';
		pl330_dma_rd_inverted <= '1';
		pl330_dma_wr_inverted <= '1';
		pl330_dma_ack <= '0';
		
		wait until reset = '1';
		wait_for_ticks(1);

		-- do a dma transfer from pl330 to cb7210
		wait until pl330_dma_single = '1';
		pl330_dma_cs_inverted <= '0';
		pl330_dma_wr_inverted <= '0';
		wait_for_ticks(1);
		pl330_dma_ack <= '1';
		wait until pl330_dma_req = '1';
		wait_for_ticks(1);
		pl330_dma_ack <= '0';
		wait_for_ticks(1);
		assert pl330_dma_req = '0';
		pl330_dma_cs_inverted <= '1';
		pl330_dma_wr_inverted <= '1';
		wait until pl330_dma_single = '0';
		wait_for_ticks(1);
		
		-- now do a dma transfer in the other direction
		
		-- do a dma transfer from cb7210 to pl330
		wait until pl330_dma_single = '1';

		pl330_dma_cs_inverted <= '0';
		pl330_dma_rd_inverted <= '0';
		wait until pl330_dma_req = '1';
		wait_for_ticks(1);
		pl330_dma_ack <= '1';
		wait_for_ticks(1);
		pl330_dma_ack <= '0';
		wait_for_ticks(1);
		assert pl330_dma_req = '0';
		pl330_dma_cs_inverted <= '1';
		pl330_dma_rd_inverted <= '1';

		assert false report "finished pl330 process" severity note;
		wait;
	end process;
	
end arch;
