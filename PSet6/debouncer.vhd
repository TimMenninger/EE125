------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
------------------------------------
entity debouncer is
   generic (
      freq: natural := 50_000_000; -- frequency of clk in Hz
      db_time: natural := 20); -- milliseconds required for debounce
   port(
      clk, rst: in std_logic;
      btns: in std_logic_vector(3 downto 0);
      ssd_deb, ssd_raw: out std_logic_vector(6 downto 0));
end entity;
------------------------------------
architecture debouncer_fsm of debouncer is
   
   constant db_ticks: natural := db_time / freq * 1000; -- ticks until db_time reached
   
   type state is (idle, debouncing, debounced, invalid);
   signal pr_db, nx_db: state;
   signal counter, counter_raw: integer range 0 to 15;
   signal db_counter: integer range 0 to db_ticks;
   signal button: integer range -1 to 4;
   signal last_button: std_logic_vector(3 downto 0);
   
begin
   
   
   process (clk, rst, btns) -- Interpret buttonpress and move states accordingly
   begin
      if (rst='1') then -- Go to idle state and reset counters
         nx_db <= idle;
         button <= -1;
      elsif (nx_db = invalid) then -- In reject state, must release all buttons to leave
         button <= -1;
         nx_db <= invalid;
         if (btns="1111") then
            nx_db <= idle;
         end if;
      elsif (rising_edge(clk)) then -- Move states according to buttonpress
         if (db_counter >= db_ticks) then
            nx_db <= debounced; -- Button debounced
         end if;
         case btns is
            when "1111" =>
               nx_db <= idle;
               button <= 0;
            when "1110" =>
               if (button /= 1) then
                  nx_db <= debouncing;
               end if;
               button <= 1;
            when "1101" =>
               if (button /= 2) then
                  nx_db <= debouncing;
               end if;
               button <= 2;
            when "1011" =>
               if (button /= 3) then
                  nx_db <= debouncing;
               end if;
               button <= 3;
            when "0111" =>
               if (button /= 4) then
                  nx_db <= debouncing;
               end if;
               button <= 4;
            when others => -- Invalid button
               nx_db <= invalid;
               button <= -1;
         end case;
      end if;
   end process;
   
   
   process (clk, rst, btns) -- check for new button press
   begin
      if (rst='1') then
         counter_raw <= 0;
      elsif (rising_edge(clk)) then
         if (last_button > btns) then -- New button press
            counter_raw <= (counter_raw + 1) mod 16;
         end if;
         last_button <= btns; -- Update last known button press.
      end if;
   end process;
   
   
   process (clk, rst) -- Update debouncer counter
   begin
      if (rst='1') then
         db_counter <= 0;
      elsif (rising_edge(clk)) then
         if (nx_db = debouncing and db_counter < db_ticks) then -- Continue debouncing
            db_counter <= db_counter + 1;
         elsif (nx_db = debounced) then -- Already debounced
            db_counter <= db_ticks;
         else -- Button now pressed
            db_counter <= 0;
         end if;
      end if;
   end process;
   
   
   process (clk, rst) -- Update buttonpress counters (raw and debounced)
   begin
      if (rst='1') then
         counter <= 0;
      elsif (nx_db = invalid) then -- In reject state, must reset to leave
         counter <= counter;
      elsif (rising_edge(clk) and nx_db /= pr_db) then -- Switched states, may need increment
         if (nx_db = debounced and button /= 0) then -- Debounced buttonpress
            counter <= (counter + 1) mod 16;
         end if;
      end if;
   end process;
   
   
   process (clk, rst) -- Update state
   begin
      if (rising_edge(clk)) then
         pr_db <= nx_db;
      end if;
   end process;
   
   process (clk) -- Write to ssd's
   begin
      case counter is -- Display debounced counter
         when 0 =>
            ssd_deb <= "0000001"; -- "0" on ssd
         when 1 =>
            ssd_deb <= "1001111"; -- "1" on ssd
         when 2 =>
            ssd_deb <= "0010010"; -- "2" on ssd
         when 3 =>
            ssd_deb <= "0000110"; -- "3" on ssd
         when 4 =>
            ssd_deb <= "1001100"; -- "4" on ssd
         when 5 =>
            ssd_deb <= "0100100"; -- "5" on ssd
         when 6 =>
            ssd_deb <= "0100000"; -- "6" on ssd
         when 7 =>
            ssd_deb <= "0001111"; -- "7" on ssd
         when 8 =>
            ssd_deb <= "0000000"; -- "8" on ssd
         when 9 =>
            ssd_deb <= "0000100"; -- "9" on ssd
         when 10 =>
            ssd_deb <= "0001000"; -- "A" on ssd
         when 11 =>
            ssd_deb <= "1100000"; -- "b" on ssd
         when 12 =>
            ssd_deb <= "0110001"; -- "C" on ssd
         when 13 =>
            ssd_deb <= "1000010"; -- "d" on ssd
         when 14 =>
            ssd_deb <= "0110000"; -- "E" on ssd
         when 15 =>
            ssd_deb <= "0111000"; -- "f" on ssd
      end case;
      
      case counter_raw is -- Display raw counter
         when 0 =>
            ssd_raw <= "0000001"; -- "0" on ssd
         when 1 =>
            ssd_raw <= "1001111"; -- "1" on ssd
         when 2 =>
            ssd_raw <= "0010010"; -- "2" on ssd
         when 3 =>
            ssd_raw <= "0000110"; -- "3" on ssd
         when 4 =>
            ssd_raw <= "1001100"; -- "4" on ssd
         when 5 =>
            ssd_raw <= "0100100"; -- "5" on ssd
         when 6 =>
            ssd_raw <= "0100000"; -- "6" on ssd
         when 7 =>
            ssd_raw <= "0001111"; -- "7" on ssd
         when 8 =>
            ssd_raw <= "0000000"; -- "8" on ssd
         when 9 =>
            ssd_raw <= "0000100"; -- "9" on ssd
         when 10 =>
            ssd_raw <= "0001000"; -- "A" on ssd
         when 11 =>
            ssd_raw <= "1100000"; -- "b" on ssd
         when 12 =>
            ssd_raw <= "0110001"; -- "C" on ssd
         when 13 =>
            ssd_raw <= "1000010"; -- "d" on ssd
         when 14 =>
            ssd_raw <= "0110000"; -- "E" on ssd
         when 15 =>
            ssd_raw <= "0111000"; -- "f" on ssd
      end case;
   end process;
   
end architecture;
         
