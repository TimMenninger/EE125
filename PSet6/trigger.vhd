------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
------------------------------------
entity trigger is
   generic (
      freq: natural := 50_000_000; -- frequency of clk in Hz
      T: natural := 1); -- milliseconds y is high after trigger
   port(
      clk, rst, x: in std_logic;
      y: out std_logic);
end entity;
------------------------------------
architecture trigger_fsm of trigger is

   type state1 is (idle1, idle_high, rising); -- FSM1 states
   signal nx_FSM1, pr_FSM1: state1;
   
   type state2 is (idle2, counting); -- FSM2 states
   signal nx_FSM2, pr_FSM2: state2;
   
   constant T_ticks: natural := T * freq / 1000; -- ticks y is high
   signal T_counter: integer range 0 to T_ticks; -- counts ticks since y rising edge
   signal i: std_logic; -- Output from FSM1
   
begin

   process (clk, rst) -- Controls FSM1, setting i high if rising edge
   begin
      if (rst='1') then
         i <= '0'; -- Output nothing
         nx_FSM1 <= idle1; -- Reset machine
      elsif (rising_edge(clk)) then
         case pr_FSM1 is
            when idle1 => -- Check for rising edge on x (only in idle1 if x low)
               if (x='1') then
                  nx_FSM1 <= rising;
                  i <= '1';
               else
                  i <= '0';
               end if;
            when idle_high => -- Stay here until x goes low
               if (x='0') then
                  nx_FSM1 <= idle1;
               end if;
               i <= '0';
            when rising => -- Triggered. go back to idle.
               if (x='0') then
                  nx_FSM1 <= idle1;
               else
                  nx_FSM1 <= idle_high;
               end if;
               i <= '0';
         end case;
      end if;
   end process;
   
   
   process (clk, rst) -- Controls FSM2
   begin
      if (rst='1') then -- Reset state machine
         nx_FSM2 <= idle2;
      elsif (rising_edge(clk)) then
         if (T_counter >= T_ticks) then -- Done counting, go idle
            nx_FSM2 <= idle2;
         elsif (i = '1') then -- Trigger, start counting.
            nx_FSM2 <= counting;
         end if;
      end if;
   end process;
   
   
   process (clk, rst) -- Timer for FSM2
   begin
      if (rst='1') then -- Reset counter
         T_counter <= 0;
      elsif (rising_edge(clk)) then
         if (i = '1') then -- Trigger, restart counter
            T_counter <= 0;
         end if;
         if (nx_FSM2 /= pr_FSM2) then -- Timer strategy #1
            T_counter <= 0;
         elsif (pr_FSM2 = counting) then
            T_counter <= T_Counter + 1;
         end if;
      end if;
   end process;
   
   
   process (clk, rst) -- Set output according to FSM2
   begin
      if (rst='1') then -- Output is inactive on reset.
         y <= '0';
      elsif (rising_edge(clk)) then
         case nx_FSM2 is
            when idle2 => -- Inactive when not counting
               y <= '0';
            when counting => -- Active when we are still counting
               y <= '1';
         end case;
      end if;
   end process;
   
   
   process (clk, rst) -- Set states equal to each other.
   begin
      if (rising_edge(clk)) then
         pr_FSM1 <= nx_FSM1;
         pr_FSM2 <= nx_FSM2;
      end if;
   end process;
   
end architecture;
            
   
   