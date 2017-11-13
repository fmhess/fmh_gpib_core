
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity dma_translator_cb7210p2_to_pl330 is
	port (
		clock : in std_logic; 
		reset : in  std_logic;
		pl330_dma_cs_inverted : in std_logic;
		pl330_dma_rd_inverted : in std_logic;
		pl330_dma_wr_inverted : in  std_logic;
		pl330_dma_ack : in  std_logic;
		pl330_dma_single : out std_logic;
		pl330_dma_req : out std_logic;
		
		cb7210p2_dma_in_request : in std_logic;
		cb7210p2_dma_out_request : in std_logic;
		cb7210p2_dma_read_inverted : out std_logic;
		cb7210p2_dma_write_inverted : out std_logic;
		cb7210p2_dma_ack_inverted : out std_logic
	);
end dma_translator_cb7210p2_to_pl330;

architecture arch of dma_translator_cb7210p2_to_pl330 is

	type dma_transfer_state_enum is (transfer_idle,
		slave_requesting,
		wait_for_cb7210p2_request_to_clear,
		transfer_awaiting_completion);
	signal dma_transfer_state : dma_transfer_state_enum;
	signal pl330_dma_req_buffer : std_logic;
begin
	process (reset, clock)
	begin
		if to_X01(reset) = '1' then
			dma_transfer_state <= transfer_idle;
			pl330_dma_req_buffer <= '0';
			pl330_dma_single <= '0';
			cb7210p2_dma_ack_inverted <= '1';
		elsif rising_edge(clock) then
			case dma_transfer_state is
				when transfer_idle =>
					if (cb7210p2_dma_in_request or cb7210p2_dma_out_request) = '1' then
						dma_transfer_state <= slave_requesting;
					end if;
					pl330_dma_req_buffer <= '0';
					pl330_dma_single <= '0';
					cb7210p2_dma_ack_inverted <= '1';
				when slave_requesting =>
					pl330_dma_single <= '1';
					-- Once we go past this state, we are committed to completing the transfer.
					-- So, make sure everything is ready to go before we leave.
					if (cb7210p2_dma_in_request or cb7210p2_dma_out_request) = '0' then
						dma_transfer_state <= transfer_idle;
					-- it is legal to wait for pl330_dma_ack in the following line because it is the VALID signal, and AXI handshaking
					-- permits READY (pl_dma_req here) to wait for VALID
					elsif (cb7210p2_dma_in_request and not pl330_dma_wr_inverted and not pl330_dma_cs_inverted and pl330_dma_ack) = '1' or
					-- we don't wait for pl330_dma_ack in the following line because it is acting as the READY signal, and AXI handshaking
					-- forbids VALID (pl330_dma_req here) to wait for READY
						(cb7210p2_dma_out_request and not pl330_dma_rd_inverted and not pl330_dma_cs_inverted) = '1' 
					then
						dma_transfer_state <= wait_for_cb7210p2_request_to_clear;
						cb7210p2_dma_ack_inverted <= '0';
					end if;
				when wait_for_cb7210p2_request_to_clear =>
					if cb7210p2_dma_in_request = '0' then
						dma_transfer_state <= transfer_awaiting_completion;
					end if;
				when transfer_awaiting_completion =>
					pl330_dma_req_buffer <= '1';
					if to_X01(pl330_dma_ack) = '1' and pl330_dma_req_buffer = '1' then
						dma_transfer_state <= transfer_idle;
						-- need to clear req immediately after seeing ack so bus doesn't think we are doing 
						-- back to back transfers
						pl330_dma_req_buffer <= '0';
					end if;
			end case;
		end if;
	end process;

	cb7210p2_dma_read_inverted <= pl330_dma_rd_inverted or pl330_dma_cs_inverted;
	cb7210p2_dma_write_inverted <= pl330_dma_wr_inverted or pl330_dma_cs_inverted;
	pl330_dma_req <= pl330_dma_req_buffer;
end architecture arch;
