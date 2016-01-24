library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
---------------------------------------------------------------------------
entity multiple_detector is
	generic (
    	bits_a: integer := 5;
		bits_b: integer := 5);
	port (
    	a: in std_logic_vector(bits_a downto 0);
		b: in std_logic_vector(bits_b downto 0);
    	multiple: out std_logic;
    	invalid_input: out std_logic);
end entity;
---------------------------------------------------------------------------
architecture computation of multiple_detector is
    	signal us_a: integer range 0 to 2**bits_a;
		signal us_b: integer range 0 to 2**bits_b;
begin
	process (a, b)
	begin
		us_a <= conv_integer(a);
		us_b <= conv_integer(b);
    	if us_b=0 then -- Only possible invalid input
			multiple <= '0';
			invalid_input <= '1';
		elsif us_a mod us_b = 0 then -- Conveniently have mod available
			multiple <= '1';
			invalid_input <= '0';
		else -- Valid inputs, but a was not a multiple of b
			multiple <= '0';
			invalid_input <= '0';
		end if;
	end process;
end architecture;