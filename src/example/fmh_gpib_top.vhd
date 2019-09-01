-- See src/frontends/integrated_cb7210p2.vhd
-- This is just a wrapper which combines the separate 
-- in/out GPIB bus ports of integrated_cb7210p2 into unified inout ports.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright 2019 Frank Mori Hess
--

library ieee;
use ieee.std_logic_1164.all;
use work.integrated_cb7210p2;

entity fmh_gpib_top is
	generic (
		clock_frequency_KHz : natural := 0; 
		fifo_depth : positive := 32;
		max_filter_length : positive := 63
	);
	port (
		clock : in std_logic;
		reset : in  std_logic;

		-- gpib chip registers, avalon mm io port
		avalon_chip_select_inverted : in std_logic;
		avalon_read_inverted : in std_logic;
		avalon_write_inverted : in  std_logic;
		avalon_address : in  std_logic_vector(6 downto 0);
		avalon_data_in : in  std_logic_vector(7 downto 0);
		avalon_data_out : out std_logic_vector(7 downto 0);

		irq : out std_logic;

		-- dma, avalon mm io port
		dma_fifos_chip_select : in std_logic;
		dma_fifos_address : in std_logic_vector(1 downto 0);
		dma_fifos_read : in std_logic;
		dma_fifos_write : in std_logic;
		dma_fifos_data_in : in  std_logic_vector(15 downto 0);
		dma_fifos_data_out : out std_logic_vector(15 downto 0);

		-- dma peripherial request
		dma_single : out std_logic;
		dma_req : out std_logic;
		dma_ack : in  std_logic;

		-- gpib bus
		gpib_DIO_inverted : inout std_logic_vector (7 downto 0);
		gpib_ATN_inverted : inout std_logic;
		gpib_DAV_inverted : inout std_logic;
		gpib_EOI_inverted : inout std_logic;
		gpib_IFC_inverted : inout std_logic;
		gpib_NRFD_inverted : inout std_logic;
		gpib_NDAC_inverted : inout std_logic;
		gpib_SRQ_inverted : inout std_logic;
		gpib_REN_inverted : inout std_logic;

		-- gpib transceiver control
		pullup_enable_inverted : out std_logic;
		controller_in_charge : out std_logic;
		talk_enable : out std_logic;

		-- gpib bus disconnect
		gpib_disable : in std_logic
	);
end fmh_gpib_top;

architecture structural of fmh_gpib_top is
	signal not_controller_in_charge : std_logic;
	
begin
	my_integrated_cb7210p2 : entity work.integrated_cb7210p2
		generic map (
			clock_frequency_KHz => clock_frequency_KHz, 
			fifo_depth => fifo_depth,
			max_filter_length => max_filter_length
		)
		port map(
			clock => clock,
			reset => reset,
			avalon_chip_select_inverted => avalon_chip_select_inverted,
			avalon_read_inverted => avalon_read_inverted,
			avalon_write_inverted => avalon_write_inverted,
			avalon_address => avalon_address,
			avalon_data_in => avalon_data_in,
			avalon_data_out => avalon_data_out,
			interrupt => irq,
			dma_fifos_chip_select => dma_fifos_chip_select,
			dma_fifos_address => dma_fifos_address,
			dma_fifos_read => dma_fifos_read,
			dma_fifos_write => dma_fifos_write,
			dma_fifos_data_in => dma_fifos_data_in,
			dma_fifos_data_out => dma_fifos_data_out,
			dma_single => dma_single,
			dma_req => dma_req,
			dma_ack => dma_ack,
			gpib_DIO_inverted_in => gpib_DIO_inverted,
			gpib_ATN_inverted_in => gpib_ATN_inverted,
			gpib_DAV_inverted_in => gpib_DAV_inverted,
			gpib_EOI_inverted_in => gpib_EOI_inverted,
			gpib_IFC_inverted_in => gpib_IFC_inverted,
			gpib_NRFD_inverted_in => gpib_NRFD_inverted,
			gpib_NDAC_inverted_in => gpib_NDAC_inverted,
			gpib_SRQ_inverted_in => gpib_SRQ_inverted,
			gpib_REN_inverted_in => gpib_REN_inverted,
			gpib_DIO_inverted_out => gpib_DIO_inverted,
			gpib_ATN_inverted_out => gpib_ATN_inverted,
			gpib_DAV_inverted_out => gpib_DAV_inverted,
			gpib_EOI_inverted_out => gpib_EOI_inverted,
			gpib_IFC_inverted_out => gpib_IFC_inverted,
			gpib_NRFD_inverted_out => gpib_NRFD_inverted,
			gpib_NDAC_inverted_out => gpib_NDAC_inverted,
			gpib_SRQ_inverted_out => gpib_SRQ_inverted,
			gpib_REN_inverted_out => gpib_REN_inverted,
			pullup_enable_inverted => pullup_enable_inverted,
			not_controller_in_charge => not_controller_in_charge,
			talk_enable => talk_enable,
			gpib_disable => gpib_disable
		);

		controller_in_charge <= not not_controller_in_charge;
end architecture structural;
