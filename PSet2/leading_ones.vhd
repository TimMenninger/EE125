-- Returns in ssd the number of leading ones in the inputs, data.
-----------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------
entity leading_ones is
    generic (N: integer := 7);
    port (data: in std_logic_vector (N - 1 downto 0);
          ssd: out std_logic_vector(6 downto 0));
end entity;
-----------------------
architecture behavior of leading_ones is
     type oneDoneD is array (0 to N) of integer range 0 to 15;
     signal count: oneDoneD;
     signal stop: oneDoneD;
begin
	  count(0) <= 0; -- Start with count at zero
	  concurrent: for i in 1 to N generate
			count(i) <= count(i - 1) + 1 when data(i - 1)='1' else (N - i - 1);
	  end generate;
	  with count(N) select ssd <=
			"0000001" when 0,  -- "0" on ssd
			"1001111" when 1,  -- "1" on ssd
			"0010010" when 2,  -- "2" on ssd
			"0000110" when 3,  -- "3" on ssd
			"1001100" when 4,  -- "4" on ssd
			"0100100" when 5,  -- "5" on ssd
			"0100000" when 6,  -- "6" on ssd
			"0001111" when 7,  -- "7" on ssd
			"0000000" when 8,  -- "8" on ssd
			"0000100" when 9,  -- "9" on ssd
			"0001000" when 10, -- "A" on ssd
			"1100000" when 11, -- "b" on ssd
			"0110001" when 12, -- "C" on ssd
		   "1000010" when 13, -- "d" on ssd
			"0110000" when 14, -- "E" on ssd
			"0111000" when 15; -- "f" on ssd
end architecture;
------------------------
