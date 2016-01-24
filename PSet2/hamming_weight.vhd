library ieee;
use ieee.std_logic_1164.all;
---------------------------------------------------------------------------
package log_function is
    function log2 (n: natural) return natural;
end package;

package body log_function is
    -- Log function because number of ones in a number is log base 2 the
    -- number of bits in the number
    function log2 (n: natural) return natural is
        variable temp: natural := n;
        variable counter: natural := 0;
    begin
        while temp > 1 loop
            temp := temp / 2;
            counter := counter + 1;
        end loop;
        -- loop rounds down so if n wasn't a power of 2, we need to add 1
        if 2**counter < n then
            counter := counter + 1;
        end if
        return counter;
    end function log2;
end package body;
---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.log_function.log2;
---------------------------------------------------------------------------
entity hamming_weight is
    generic (
    N: integer := 7);

    port (
        x: in std_logic_vector(N-1 downto 0);
        y: out std_logic_vector(log2(N) downto 0));

end entity;
---------------------------------------------------------------------------
-- Want log function to calculate number of bits in output.
architecture computation of hamming_weight is
	
    type oneDoneD is array (0 to N) of integer range 0 to N;
    signal temp: oneDoneD;
begin
    process (x)
    begin
        temp(0) <= 0; -- If zero bits analyzed, return value is 0. Otherwise,
                      -- used for reference in first bit
        for i in 1 to n loop
            temp(i) <= temp(i-1) + conv_integer(x(i-1));
        end loop;
        y <= conv_std_logic_vector(temp(N), log2(N)+1);
    end process;
end architecture;
