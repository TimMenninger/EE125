------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
------------------------------------
entity alarm is
   generic (
      freq: natural := 50_000_000; -- frequency of clk in Hz
      nChirpsArm: natural := 2; -- number of chirps on arming of system
      nChirpsUnarm: natural := 1; -- number of chirps on unarming of system
      Tchirp: natural := 300; -- milliseconds for chirp
      Tbuzz: natural := 1; -- buzzer pulse in Hz
      Tout: natural := 10; -- num seconds to leave premises
      Tin: natural := 5); -- num seconds to enter pwd after entering
   port(
      clk, rst: in std_logic;
      senA, senB: in std_logic;
      pwd: in std_logic;
      state: out std_logic_vector(9 downto 0);
      chirper: out std_logic_vector(34 downto 0));
end entity;
------------------------------------
architecture alarm_fsm of alarm is
   
   constant Tin_ticks: natural := Tin * freq; -- ticks until Tin reached
   constant Tout_ticks: natural := Tout * freq; -- ticks until Tout reached
   constant Tbuzz_ticks: natural := freq / Tbuzz / 2; -- Ticks for buzzer
   constant Tchirp_ticks: natural := freq / 1000 * Tchirp; -- Ticks for one chirp
   
   type alm_state is (unarmed, pwd_ua, A_armed, armed, entering, unarmed_wt, panic);
   -- unarmed_wt state is for after pwd asserted in any state so we don't immediately
   --    try to arm the system.
   signal pr_alm, nx_alm: alm_state;
   
   type toggle_state is (toggle_on, toggle_off);
   signal pr_buzz, nx_buzz: toggle_state; -- Toggles buzzer on and off
   signal pr_chirp, nx_chirp: toggle_state; -- Toggles chirper on and off
   
   -- Counter for chirps and max number of chirps (depends on state)
   signal max_chirps: integer range -1 to 4; -- 4 based on max of generic nChirp*
   signal num_chirps: integer range 0 to 4; -- 4 based on max of generic nChirp*
   
   signal T: integer range 0 to Tout_ticks; -- Counter for Tin and Tout
   signal Tb: integer range 0 to Tbuzz_ticks; -- Counter for buzzer
   signal Tc: integer range 0 to Tchirp_ticks; -- Counter for chirper
   
begin
   
   
   process (rst, clk, senA, senB, pwd) -- Change states accordingly.
   begin
      if (rst='1') then -- Go to start state.
         nx_alm <= unarmed;
      elsif (rising_edge(clk)) then
         case pr_alm is
            when unarmed => -- Idle state, no alarms
               if (pwd='0') then
                  nx_alm <= pwd_ua;
               else
                  nx_alm <= unarmed;
               end if;
            when pwd_ua => -- Password entered, waiting for end of pulse
               if (pwd='1') then
                  nx_alm <= A_armed;
               else
                  nx_alm <= pwd_ua;
               end if;
            when A_armed => -- Arm A, wait to arm B
               if (pwd='0') then
                  nx_alm <= unarmed_wt;
               elsif (senA='1') then
                  nx_alm <= panic;
               elsif (T >= Tout_ticks) then
                  nx_alm <= armed;
               else
                  nx_alm <= A_armed;
               end if;
            when armed => -- System totally armed, observing B signal now
               if (pwd='0') then
                  nx_alm <= unarmed_wt;
               elsif (senA='1') then
                  nx_alm <= panic;
               elsif (senB='1') then
                  nx_alm <= entering;
               else
                  nx_alm <= armed;
               end if;
            when entering => -- Password detected, wait for correct password
               if (pwd='0') then
                  nx_alm <= unarmed_wt;
               elsif (senA='1') then
                  nx_alm <= panic;
               elsif (T >= Tin_ticks) then
                  nx_alm <= panic;
               else
                  nx_alm <= entering;
               end if;
            when unarmed_wt => -- Wait state so we don't loop accidentally
               if (pwd='1') then
                  nx_alm <= unarmed;
               else
                  nx_alm <= unarmed_wt;
               end if;
            when panic => -- Alarm set
               if (pwd='0') then
                  nx_alm <= unarmed_wt;
               else
                  nx_alm <= panic;
               end if;
         end case;
      end if;
   end process;


   process (clk, rst) -- Increment wait counters if necessary.
   begin
      if (rst='1') then -- Reset counter
         T <= 0;
      elsif (rising_edge(clk)) then -- Increment if in counting state
         if (nx_alm /= pr_alm) then
            T <= 0;
         else
            T <= T + 1;
         end if;
      end if;
   end process;
   
   
   process (clk, rst) -- Changes buzz state if necessary
   begin
      if (rst='1') then
         nx_buzz <= toggle_off;
      elsif (rising_edge(clk)) then
         if (Tb >= Tbuzz_ticks) then -- Switch buzzer on/off if counter at max.
            case pr_buzz is
               when toggle_off =>
                  nx_buzz <= toggle_on;
               when toggle_on =>
                  nx_buzz <= toggle_off;
            end case;
         end if;
      end if;
   end process;
   
   
   process (clk, rst) -- Increments buzz counter
   begin
      if (rst='1') then -- Reset counter
         Tb <= 0;
      elsif (rising_edge(clk)) then -- Increment if necessary
         if (nx_alm /= pr_alm) then
            Tb <= 0;
         elsif (nx_buzz /= pr_buzz) then
            Tb <= 0;
         else
            Tb <= Tb + 1;
         end if;
      end if;
   end process;
   
   
   process (clk, rst) -- Set maximum chirps (what is counted to) based on state
   begin
      if (rst='1') then
         max_chirps <= -1;
      elsif (rising_edge(clk)) then -- Chirps double so we can count every state switch
         case nx_alm is -- Only chirp when arming and unarming system.
            when armed =>
               max_chirps <= nChirpsArm * 2;
            when unarmed_wt => -- Treated like unarmed state
               max_chirps <= nChirpsUnarm * 2;
            when unarmed => -- don't change (maybe coming off reset)
               max_chirps <= nChirpsUnarm * 2; 
            when pwd_ua => -- don't change (maybe coming off reset)
               max_chirps <= nChirpsUnarm * 2;
            when others =>
               max_chirps <= -1;
         end case;
      end if;
   end process;
   

   process (clk, rst) -- Changes chirper state
   begin
      if (rst='1') then -- Reset all, turn chirper off.
         nx_chirp <= toggle_off;
      elsif (rising_edge(clk)) then 
         if (Tc >= Tchirp_ticks) then
            case nx_alm is
               when A_armed => -- should be off
                  nx_chirp <= toggle_off;
               when entering => -- should be off
                  nx_chirp <= toggle_off;
               when panic => -- should be off
                  nx_chirp <= toggle_off;
               when others =>
                  if (num_chirps < max_chirps) then
                     case pr_chirp is -- chirp only a set number of times
                        when toggle_on =>
                           nx_chirp <= toggle_off;
                        when toggle_off =>
                           nx_chirp <= toggle_on;
                     end case;
                  else
                     nx_chirp <= toggle_off;
                  end if;
            end case;
         else
            nx_chirp <= pr_chirp;
         end if;
      end if;
   end process;
   
   
   process (clk, rst) -- Controls/tracks our number of chirps
   begin
      if (rst='1') then
         num_chirps <= 0;
      elsif (rising_edge(clk)) then
         if (nx_alm /= pr_alm) then -- set num_chirps to initial value by state
            case nx_alm is
               when unarmed => -- initial value was at unarmed_wt
                  if (nx_chirp /= pr_chirp and num_chirps < max_chirps) then
                     num_chirps <= num_chirps + 1; -- can and want to increment chirper
                  end if;
               when pwd_ua => -- initial value was at unarmed_wt
                  if (nx_chirp /= pr_chirp and num_chirps < max_chirps) then
                     num_chirps <= num_chirps + 1; -- can and want to increment chirper
                  end if;
               when others =>
                  num_chirps <= 0;
            end case;
         elsif (nx_chirp /= pr_chirp and num_chirps < max_chirps) then
            num_chirps <= num_chirps + 1; -- can and want to increment chirper
         else
            num_chirps <= num_chirps;
         end if;
      end if;
   end process;
   
   
   process (clk, rst) -- Increments chirp counter
   begin
      if (rst='1') then -- Reset counter
         Tc <= 0;
      elsif (rising_edge(clk)) then
         if (nx_chirp /= pr_chirp) then -- chirp state changed, reset counter
            Tc <= 0;
         elsif (nx_alm /= pr_alm) then -- counter should still count in sub-unarmed states
            if (nx_alm = unarmed or nx_alm = pwd_ua) then
               Tc <= Tc + 1; -- still unarmed, continue normally
            else
               Tc <= 0; -- reset counter for entering unarmed/armed, or dont care
            end if;
         else -- count normally
            Tc <= Tc + 1;
         end if;
      end if;
   end process;
   
   
   process (rst, clk) -- Update states
   begin
      if (rising_edge(clk)) then
         pr_alm <= nx_alm;
         pr_buzz <= nx_buzz;
         pr_chirp <= nx_chirp;
      end if;
   end process;
   
   
   process (rst, clk) -- Set chirper according to state.
   begin
      if (rst='1') then
         chirper <= "11111111111111111111111111111111111"; -- blank
      elsif (rising_edge(clk)) then
         case pr_chirp is
            when toggle_on => -- Turn on
               chirper <= "10001100001011111100101011110001100"; -- "chirp"
            when toggle_off => -- Turn off
               chirper <= "11111111111111111111111111111111111"; -- blank
         end case;
      end if;
   end process;
   
   
   process (rst, clk) -- Set output state for LEDs
   begin
      if (rising_edge(clk)) then
         case pr_alm is -- Set alarm state LEDs
            when armed =>
               state <= "1111100000";
            when unarmed =>
               state <= "0000011111";
            when A_armed =>
               if (pr_buzz = toggle_on) then -- Blink right five LEDs
                  state <= "0000011111";
               else
                  state <= "0000000000";
               end if;
            when entering =>
               if (pr_buzz = toggle_on) then -- Blink left five LEDs
                  state <= "1111100000";
               else
                  state <= "0000000000";
               end if;
            when panic =>
               state <= "1111111111";
            when pwd_ua => -- Equivalent of unarmed
               state <= "0000011111";
            when unarmed_wt => -- Equivalent of unarmed
               state <= "0000011111";
         end case;
      end if;
   end process;
            
   
end architecture;
      
      
            