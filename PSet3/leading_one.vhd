-----------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------
entity leading_one is
   generic (N: integer := 7);
    port (X: in std_logic_vector (N-1 downto 0);
            Y: out integer range 0 to 7);
end entity;
-----------------------
architecture behavior of leading_one is
begin
    process(X)
        variable count: integer range 0 to 8;
    begin
        count := 0;
        for i in X'range loop
            case X(i) is
                when '1' => count := count + 1;
                when others => exit;
            end case;
        end loop;
        Y <= count;
    end process;
end architecture; 
