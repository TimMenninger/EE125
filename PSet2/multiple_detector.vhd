-- Outputs 1 in multiple if a is a multiple of b and 0 otherwise.
-- If b is zero, it is an invalid input and thus invalid_input is 1
-- Uses exclusively concurrent code.
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
---------------------------------------------------------------------------
entity multiple_detector is
    generic (
        bits_a: integer := 5;
        bits_b: integer := 5);
    port (
        a: in std_logic_vector(bits_a - 1 downto 0);
        b: in std_logic_vector(bits_b - 1 downto 0);
        multiple: out std_logic;
        invalid_input: out std_logic);
end entity;
---------------------------------------------------------------------------
architecture computation of multiple_detector is
    signal us_a: integer range 0 to 2**bits_a;
    signal us_b: integer range 0 to 2**bits_b;
begin
    us_a <= conv_integer(a);
    us_b <= conv_integer(b);
    invalid_input <= '1' when us_b = 0 else '0';
    multiple <= '1' when us_a mod us_b = 0 else '0';
end architecture;
