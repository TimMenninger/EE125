-- Returns in y the hamming weight of x (number of ones) using exclusively
-- concurrent code.
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;
---------------------------------------------------------------------------
entity hamming_weight is
    generic (
    N: integer := 7);

    port (
        x: in std_logic_vector(N-1 downto 0);
        y: out std_logic_vector(integer(floor(log2(real(N)))) downto 0));

end entity;
---------------------------------------------------------------------------
-- Want log function to calculate number of bits in output.
architecture computation of hamming_weight is
	
    type oneDoneD is array (0 to N) of integer range 0 to N;
    signal temp: oneDoneD;
begin
    temp(0) <= 0; -- If zero bits analyzed, return value is 0. Otherwise,
                  -- used for reference in first bit
    concurrent: for i in 1 to n generate
        temp(i) <= temp(i-1) + conv_integer(x(i-1));
    end generate;
    y <= conv_std_logic_vector(temp(N), integer(floor(log2(real(N))))+1);
end architecture;
