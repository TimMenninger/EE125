library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------
entity two_digit_timer is
	generic (
		fclk: natural := 5); -- In MHz
	port (
		ena: in std_logic; -- Enable must be high for timer to run
		clk: in std_logic; -- Uses clock at fclk to time
		rst: in std_logic; -- When low (active), zeroes system
		ssd2: out std_logic_vector(6 downto 0); -- Tens digit segments
		ssd1: out std_logic_vector(6 downto 0); -- Ones digit segments
		full_count: out std_logic); -- True if we have reached 60 seconds
end entity;
-------------------------------------------------------------------------------
architecture timer of two_digit_timer is
		signal count2: integer range 0 to 6; -- Tens digit value
		signal count1: integer range 0 to 9; -- Ones digit value
		signal ticks_MHz: integer; -- Increments ticks and resets at 1 mil
		signal Mticks: integer; -- Counts once every 1 000 000 ticks
begin
	process (ena, clk, rst)
	begin
		-- Only run if enable is high.
		if (rst = '0') then
			--  If reset, want to zero the system.
			full_count <= '0';
			count2 <= 0;
			count1 <= 0;
			ticks_MHz <= 0;
			Mticks <= 0;
		elsif (ena = '0') then
			-- Do nothing if we are disabled.
		-- If tens digit is 6, we are at 60 sec and do nothing
		elsif (count2 = 6) then
			-- Reset in case this is the first time.
			full_count <= '1';
			ticks_MHz <= 0;
			Mticks <= 0;
		-- Otherwise, increment ticks and change count if necessary
		elsif (rising_edge(clk)) then
			full_count <= '0';
			ticks_MHz <= ticks_MHz + 1;
			
			-- See if we have overflown our million-tick counter
			if (ticks_MHz >= 1_000_000) then
				ticks_MHz <= 0;
				Mticks <= Mticks + 1;
			end if;
			
			-- See if we have reached fclk MHz
			if (Mticks >= fclk) then
				Mticks <= 0;
				-- See if we need to carry count1 into count2
				if (count1 = 9) then
					count1 <= 0;
					count2 <= count2 + 1;
				else
					count1 <= count1 + 1;
				end if;
			end if;
		-- Otherwise, nothing to update
		end if;
		
		-- If count1 is 10, we missed the boundary case.
		assert (count1 /= 10);
		
		-- Convert the count to segment display codes.
		case count2 is
			when 0 => ssd2 <= "1000000"; -- "0" on ssd2
			when 1 => ssd2 <= "1111001"; -- "1" on ssd2
			when 2 => ssd2 <= "0100100"; -- "2" on ssd2
			when 3 => ssd2 <= "0110000"; -- "3" on ssd2
			when 4 => ssd2 <= "0011001"; -- "4" on ssd2
			when 5 => ssd2 <= "0010010"; -- "5" on ssd2
			when 6 => ssd2 <= "0000010"; -- "6" on ssd2
		end case;
			
		case count1 is
			when 0 => ssd1 <= "1000000"; -- "0" on ssd1
			when 1 => ssd1 <= "1111001"; -- "1" on ssd1
			when 2 => ssd1 <= "0100100"; -- "2" on ssd1
			when 3 => ssd1 <= "0110000"; -- "3" on ssd1
			when 4 => ssd1 <= "0011001"; -- "4" on ssd1
			when 5 => ssd1 <= "0010010"; -- "5" on ssd1
			when 6 => ssd1 <= "0000010"; -- "6" on ssd1
			when 7 => ssd1 <= "1111000"; -- "7" on ssd1
			when 8 => ssd1 <= "0000000"; -- "8" on ssd1
			when 9 => ssd1 <= "0010000"; -- "9" on ssd1
		end case;
	end process;
end architecture;