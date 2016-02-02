library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------
entity moving_display is
	generic (
		fclk: integer := 50_000_000); -- Frequency in Hz of clock
	port (
		ena: in std_logic; -- Enable must be high for timer to run
		clk: in std_logic; -- Uses clock at fclk to time
		rst: in std_logic; -- When low (active), zeroes system
		thm: in std_logic_vector(3 downto 0); -- thermometer code
		ssd4: out std_logic_vector(6 downto 0); -- Rightmost digit
		ssd3: out std_logic_vector(6 downto 0); -- 2nd from right digit
		ssd2: out std_logic_vector(6 downto 0); -- 3rd from right digit
		ssd1: out std_logic_vector(6 downto 0)); -- 4th from right digit
end entity;
-------------------------------------------------------------------------------
architecture timer of moving_display is
		signal ticks: integer range 0 to 2 * fclk; -- Counts ticks
		signal freq: integer range 0 to 2 * fclk; -- Num ticks before reset
		signal state: integer range 0 to 7; -- State of the system
begin
	process (ena, clk, rst)
	begin
		-- Only run if enable is high.
		if (rst = '1') then
			--  If reset, want to zero the system.
			ticks <= 0;
			state <= 0;
		elsif (ena = '0') then
			-- Do nothing if we are disabled.
		-- Otherwise, increment ticks and change count if necessary
		elsif (rising_edge(clk)) then
			-- Figure out how frequently we should be changing
			case thm is
				when "0000" => freq <= 2 * fclk; -- 0.5x per sec
				when "0001" => freq <= fclk; -- 1x per sec
				when "0011" => freq <= fclk / 2; -- 2x per sec
				when "0111" => freq <= fclk / 4; -- 4x per sec
				when "1111" => freq <= fclk / 8; -- 8x per sec
				when others => -- Undefined, do nothing
					state <= 0;
					freq <= fclk;
			end case;
				
			-- Add one to the ticks for seeing the clock
			ticks <= ticks + 1;
			
			-- See if we have overflown our million-tick counter
			if (ticks >= freq) then
				ticks <= 0;
				state <= (state + 1) mod 8;
			end if;
			
		-- Otherwise, nothing to update
		end if;
		
		-- Write to the displays depending on the state.
		case state is
			when 0 =>
				-- "----"
				ssd1 <= "1111111"; -- Clear digit 1
				ssd2 <= "1111111"; -- Clear digit 2
				ssd3 <= "1111111"; -- Clear digit 3
				ssd4 <= "1111111"; -- Clear digit 4
			when 1 =>
				-- "---0"
				ssd1 <= "1111111"; -- Clear digit 1
				ssd2 <= "1111111"; -- Clear digit 2
				ssd3 <= "1111111"; -- Clear digit 3
				ssd4 <= "0000001"; -- "0" on digit 4
			when 2 =>
				-- "--01"
				ssd1 <= "1111111"; -- Clear digit 1
				ssd2 <= "1111111"; -- Clear digit 2
				ssd3 <= "0000001"; -- "0" on digit 3
				ssd4 <= "1001111"; -- "1" on digit 4
			when 3 =>
				-- "-012"
				ssd1 <= "1111111"; -- Clear digit 1
				ssd2 <= "0000001"; -- "0" on digit 2
				ssd3 <= "1001111"; -- "1" on digit 3
				ssd4 <= "0010010"; -- "2" on digit 4
			when 4 =>
				-- "0123"
				ssd1 <= "0000001"; -- "0" on digit 1
				ssd2 <= "1001111"; -- "1" on digit 2
				ssd3 <= "0010010"; -- "2" on digit 3
				ssd4 <= "0000110"; -- "3" on digit 4
			when 5 =>
				-- "123-"
				ssd1 <= "1001111"; -- "1" on digit 1
				ssd2 <= "0010010"; -- "2" on digit 2
				ssd3 <= "0000110"; -- "3" on digit 3
				ssd4 <= "1111111"; -- Clear digit 4
			when 6 =>
				-- "23--"
				ssd1 <= "0010010"; -- "2" on digit 1
				ssd2 <= "0000110"; -- "3" on digit 2
				ssd3 <= "1111111"; -- Clear digit 3
				ssd4 <= "1111111"; -- Clear digit 4
			when 7 =>
				-- "3---"
				ssd1 <= "0000110"; -- "3" on digit 1
				ssd2 <= "1111111"; -- Clear digit 2
				ssd3 <= "1111111"; -- Clear digit 3
				ssd4 <= "1111111"; -- Clear digit 4
		end case;
	end process;
end architecture;