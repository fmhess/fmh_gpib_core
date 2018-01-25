
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity dma_translator_cb7210p2_to_pl330 is
	port (
		clock : in std_logic; 
		reset : in  std_logic;
		pl330_dma_ack : in  std_logic;
		-- dma_single and dma_req only seem to work reliably when asserted together
		pl330_dma_single : out std_logic; -- single request used to transfer dregs after bursts complete
		pl330_dma_req : out std_logic; -- burst request (driver sets the max burst size to 1 so it's really requesting single)
		
		cb7210p2_dma_in_request : in std_logic;
		cb7210p2_dma_out_request : in std_logic;
		-- When false, cancels any pending dma request going out to the pl330.  This is
		-- needed to prevent a dma in request which was never satisfied from turning into
		-- a dma out request when the cb7210 changes dma direction from input to output.
		cb7210p2_dma_request_enable : in std_logic
	);
end dma_translator_cb7210p2_to_pl330;

architecture arch of dma_translator_cb7210p2_to_pl330 is

	type dma_transfer_state_enum is (transfer_idle,
		transfer_awaiting_completion);
	signal dma_transfer_state : dma_transfer_state_enum;
	signal safe_reset : std_logic;
	signal pl330_ack_or_cb7210p2_not_enable : std_logic; 
begin
	process (reset, clock)
	begin
		if to_X01(reset) = '1' then
			safe_reset <= '1';
		elsif rising_edge(clock) then
			safe_reset <= '0';
		end if;
	end process;
	
	pl330_ack_or_cb7210p2_not_enable <= pl330_dma_ack or not cb7210p2_dma_request_enable;

	process (safe_reset, clock)
	begin
		if to_X01(safe_reset) = '1' then
			dma_transfer_state <= transfer_idle;
			pl330_dma_req <= '0';
			pl330_dma_single <= '0';
		elsif rising_edge(clock) then
			case dma_transfer_state is
				when transfer_idle =>
					if (cb7210p2_dma_in_request or cb7210p2_dma_out_request) = '1' and 
						pl330_ack_or_cb7210p2_not_enable = '0' 
					then
						pl330_dma_single <= '1';
						pl330_dma_req <= '1';
						dma_transfer_state <= transfer_awaiting_completion;
					end if;
				when transfer_awaiting_completion =>
					if pl330_ack_or_cb7210p2_not_enable = '1' then
						pl330_dma_req <= '0';
						pl330_dma_single <= '0';
						dma_transfer_state <= transfer_idle;
					end if;
			end case;
		end if;
	end process;

end architecture arch;
