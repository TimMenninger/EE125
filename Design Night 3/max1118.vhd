------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
------------------------------------
package percent_pkg is
	-- Float with one digit on either side of decimal
	function bits_to_percent_ssd (bits : integer range 0 to 255)
										   return std_logic_vector;
		
end package;

package body percent_pkg is
	function bits_to_percent_ssd (bits : integer range 0 to 255)
										   return std_logic_vector is
		variable ssd_code: std_logic_vector(20 downto 0);
		variable scale: integer range 0 to 512; -- For easier computation
		variable ones, tens: integer range 0 to 9;
	begin
		scale := bits * 2;
		ones := 0;
		tens := 0;
		
		-- Hard code 100% because it is easier.
		if (scale >= 500) then
			return "100111100000010000001"; -- 100 on ssd
		else
			ssd_code(20 downto 14) := "1111111";
			for i in 0 to 500 loop
				if (i < scale) then
					if (i mod 5 = 0) then
						if (ones = 9) then
							ones := 0;
							tens := tens + 1;
						else
							ones := ones + 1;
						end if;
					end if;
				end if;
			end loop;
		end if;
		
		-- Convert to ssd
		case tens is -- Set tens digit
			when 0 =>
				ssd_code(13 downto 7) := "0000001"; -- "0" on ssd
			when 1 =>
				ssd_code(13 downto 7) := "1001111"; -- "1" on ssd
			when 2 =>
				ssd_code(13 downto 7) := "0010010"; -- "2" on ssd
			when 3 =>
				ssd_code(13 downto 7) := "0000110"; -- "3" on ssd
			when 4 =>
				ssd_code(13 downto 7) := "1001100"; -- "4" on ssd
			when 5 =>
				ssd_code(13 downto 7) := "0100100"; -- "5" on ssd
			when 6 =>
				ssd_code(13 downto 7) := "0100000"; -- "6" on ssd
			when 7 =>
				ssd_code(13 downto 7) := "0001111"; -- "7" on ssd
			when 8 =>
				ssd_code(13 downto 7) := "0000000"; -- "8" on ssd
			when 9 =>
				ssd_code(13 downto 7) := "0000100"; -- "9" on ssd
		end case;
		case ones is -- Set ones digit
			when 0 =>
				ssd_code(6 downto 0) := "0000001"; -- "0" on ssd
			when 1 =>
				ssd_code(6 downto 0) := "1001111"; -- "1" on ssd
			when 2 =>
				ssd_code(6 downto 0) := "0010010"; -- "2" on ssd
			when 3 =>
				ssd_code(6 downto 0) := "0000110"; -- "3" on ssd
			when 4 =>
				ssd_code(6 downto 0) := "1001100"; -- "4" on ssd
			when 5 =>
				ssd_code(6 downto 0) := "0100100"; -- "5" on ssd
			when 6 =>
				ssd_code(6 downto 0) := "0100000"; -- "6" on ssd
			when 7 =>
				ssd_code(6 downto 0) := "0001111"; -- "7" on ssd
			when 8 =>
				ssd_code(6 downto 0) := "0000000"; -- "8" on ssd
			when 9 =>
				ssd_code(6 downto 0) := "0000100"; -- "9" on ssd
		end case;
		
		return ssd_code;
	end function;
	
end package body;
------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.percent_pkg.all;
------------------------------------
entity max1118 is
   generic (
      freq: natural := 50_000_000; -- frequency of clk in Hz
		spi_freq: natural := 100_000); -- frequency of spi clk in Hz
   port(
      clk, rst: in std_logic;
      sdata: in std_logic; -- Serial data from MAX1118
		cnvst, sclk: out std_logic; -- Inputs to MAX1118
		ssd: out std_logic_vector(20 downto 0)); -- Display the voltage to one decimal
end entity;
------------------------------------
architecture fsm of max1118 is
	-- Slower clock for serial communication
	signal spi_clk: std_logic;
	
	-- State machine for ADC
   type state is (st_idle, st_cnvst, st_active, st_read, st_finish);
	signal nx_adc, pr_adc: state;
	
	-- Keep track of how many bits have been read
	signal num_bits: integer range 0 to 7;
	
	-- Keep track of 8 bit output signal
	signal digits: std_logic_vector(7 downto 0);
	
begin

	process (clk) -- Generate slower clock for serial communication
		variable clk_counter: natural range 0 to (freq / spi_freq);
	begin
		if (rising_edge(clk)) then
			clk_counter := clk_counter + 1;
			if (clk_counter = 5) then
				spi_clk <= not spi_clk;
				clk_counter := 0;
			end if;
		end if;
	end process;
	
	
	process(spi_clk, rst) -- Advance in state machine
	begin
		if (rst = '1') then
			nx_adc <= st_idle;
			num_bits <= 0;
			digits <= "00000000";
		elsif (rising_edge(spi_clk)) then
			case pr_adc is
				when st_idle => -- Go to pulse cnvst
					nx_adc <= st_cnvst;
					num_bits <= 0;
					digits <= digits;
				when st_cnvst => -- Start conversion
					nx_adc <= st_active;
					num_bits <= 0;
					digits <= digits;
				when st_active => -- Start reading
					nx_adc <= st_read;
					num_bits <= 0;
					digits <= digits;
				when st_read => -- Pulse cnvst to finish
					if (num_bits < 7) then
						nx_adc <= st_read;
						num_bits <= num_bits + 1; -- Count next read bit
					else
						nx_adc <= st_finish;
						num_bits <= 0;
					end if;
					digits(7 - num_bits) <= sdata; -- Record current bit
				when st_finish => -- Go back to start
					nx_adc <= st_idle;
					num_bits <= 0;
					digits <= digits;
			end case;
		end if;
	end process;
	
	
	process(clk) -- Set outputs based on current state
	begin
		if (rising_edge(clk)) then
			case nx_adc is
				when st_idle =>
					cnvst <= '0';
					sclk <= '1';
				when st_cnvst =>
					cnvst <= clk;
					sclk <= '1';
				when st_active =>
					cnvst <= '0';
					sclk <= '1';
				when st_read =>
					cnvst <= '0';
					sclk <= clk;
				when st_finish =>
					cnvst <= clk;
					sclk <= '1';
			end case;
			
			-- Set display values to 0 - 100
			ssd <= bits_to_percent_ssd(to_integer(unsigned(digits)));
		end if;
	end process;
	
	
	process(clk) -- Update present state
	begin
		if (rising_edge(clk)) then
			pr_adc <= nx_adc;
		end if;
	end process;

end architecture;