library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
------------------------------------------------------------------------------
package bcd_to_ssd_pkg is
	function bcd_to_ssd_fn (n: unsigned) return std_logic_vector;
end package; 
------------------------------------------------------------------------------
package body bcd_to_ssd_pkg is
	function bcd_to_ssd_fn (n: unsigned) return std_logic_vector is
	begin
		-- Make sure input is correct size
		assert (n'length <= 4)
			report "Input must be 4 bits!"
			severity failure;
		
		-- Return the ssd code for the integer.
		case to_integer(n) is
			when 0  => return "0000001";  -- "0" on ssd
			when 1  => return "1001111";  -- "1" on ssd
			when 2  => return "0010010";  -- "2" on ssd
			when 3  => return "0000110";  -- "3" on ssd
			when 4  => return "1001100";  -- "4" on ssd
			when 5  => return "0100100";  -- "5" on ssd
			when 6  => return "0100000";  -- "6" on ssd
			when 7  => return "0001111";  -- "7" on ssd
			when 8  => return "0000000";  -- "8" on ssd
			when 9  => return "0000100";  -- "9" on ssd
			when 10 => return "0001000";  -- "A" on ssd
			when 11 => return "1100000";  -- "b" on ssd
			when 12 => return "0110001";  -- "C" on ssd
		   when 13 => return "1000010";  -- "d" on ssd
			when 14 => return "0110000";  -- "E" on ssd
			when 15 => return "0111000";  -- "f" on ssd
			when others => return "1111111"; -- nothing
		end case;
	end function;
end package body;
------------------------------------------------------------------------------

-----Main code:---------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bcd_to_ssd_pkg.all;
------------------------------------------------------------------------------
entity bcd_to_ssd is
	port (to_disp: in std_logic_vector(3 downto 0);
			ssd: out std_logic_vector(6 downto 0));
end entity;
------------------------------------------------------------------------------
architecture convert of bcd_to_ssd is
begin
	ssd <= bcd_to_ssd_fn (unsigned(to_disp));
end architecture;