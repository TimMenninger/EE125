------------------------
library ieee;
use ieee.std_logic_1164.all;
------------------------
entity comb_circuit is 
    port(
        x: in std_logic_vector(2 downto 0);
        y: out std_logic_vector(1 downto 0));
end comb_circuit;
------------------------
architecture example of comb_circuit is
begin
    y(0) <= x(1);
    y(1) <= NOT x(2);
end architecture; 
------------------------
