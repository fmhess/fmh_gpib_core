-- IEEE 488.1 controller interface function.
--
-- Author: Frank Mori Hess fmh6jj@gmail.com
-- Copyright Frank Mori Hess 2017


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.interface_function_common.all;

entity interface_function_C is
	port(
		clock : in std_logic;
		pon : in std_logic;

		ATN : out std_logic;
		IDY : out std_logic;
		IFC : out std_logic;
		REN : out std_logic;
		NUL : out std_logic;
		TCT : out std_logic;
		
		controller_state_p1 : out C_state_p1;
		controller_state_p2 : out C_state_p2;
		controller_state_p3 : out C_state_p3;
		controller_state_p4 : out C_state_p4;
		controller_state_p5 : out C_state_p5
	);
 
end interface_function_C;
 
architecture interface_function_C_arch of interface_function_C is
 
begin

	controller_state_p1 <= CIDS;
	controller_state_p2 <= CSNS;
	controller_state_p3 <= SNAS;
	controller_state_p4 <= SRIS;
	controller_state_p5 <= SIIS;
	
	ATN <= 'L';
	IDY <= 'L';
	NUL <= 'H';
	REN <= 'L';
	IFC <= 'L';
	TCT <= 'L';
end interface_function_C_arch;
