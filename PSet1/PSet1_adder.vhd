library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
---------------------------------------------------------------------------
entity PSet1_adder is
	generic (
    	n: natural := 8);
	port (
    	a, b: in std_logic_vector(n-1 downto 0);
    	cin: in std_logic_vector(0 downto 0);
    	sum: out std_logic_vector(n-1 downto 0);
    	cout: out std_logic);
end entity;
---------------------------------------------------------------------------
architecture computation of PSet1_adder is
    	signal s_a, s_b: signed(n downto 0);
		signal s_cin: signed(n downto 0);
    	signal pre_sum: signed(n downto 0);
begin
	process (a, b, cin)
	begin
    	s_a <= signed(a(n-1) & a); -- Sign extend a
    	s_b <= signed(b(n-1) & b); -- Sign extend b
		s_cin(n downto 1) <= (OTHERS => '0'); -- Initialize to 0
		s_cin <= s_cin(n downto 1) & signed(cin);
    	pre_sum <= s_a + s_b + s_cin;
    	sum <= std_logic_vector(pre_sum(n-1 downto 0));
    	cout <= pre_sum(n);
	end process;
end architecture;