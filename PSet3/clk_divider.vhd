-----------------------
library ieee;
use ieee.std_logic_1164.all;
-----------------------
entity clk_divider is
	generic (n: integer := 7);
	port (clk: in std_logic;
			clk_out: out std_logic);
end entity;
-----------------------
architecture clk_divider of clk_divider is
		shared variable count_rise: integer;
		shared variable count_fall: integer;
		shared variable count_remainder: integer range 0 to (2*n);
begin
	process (clk)
	begin
		if (clk'event and clk='1') then
			count_rise := count_rise + 1; 
		end if;
	end process;
	process (clk)
	begin
		if (clk'event and clk='0') then
			count_fall := count_fall + 1; 
		end if;
	end process;
	process (clk)
	begin
	count_remainder := ((count_rise + count_fall) mod (2 * n));
		if (count_remainder < n) then 
			clk_out <= '1';
		else 
			clk_out <= '0';
		end if; 
	end process;
end architecture;
