------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
------------------------------------
entity light_rotator is
   generic (
		freq: natural := 50_000_000); -- frequency of clk in Hz
   port(
      stp, clk, rst, dir, spd: in std_logic;
      ssd: out std_logic_vector(6 downto 0));
end entity;
------------------------------------
architecture moore_fsm of light_rotator is

   --FSM-related declarations:
   type state is (A, AB, B, BC, C, CD, D, DE, E, EF, F, FA);
	type time_state is (T1, T2, T3, T4, T5, T6);
   signal pr_state, nx_state: state;
	signal tstate: time_state;
   
   -- Timer-related declarations:
	-- to get x milliseconds at y MHz, we calculate x * y / 1000.  Compiler
	--    kept thinking hte numbers were negative when we used it
   constant T_1: natural := 12_000_000; --240ms @ fclk=50MHz
   constant T_2: natural := 9_000_000; --180ms @ fclk=50MHz
   constant T_3: natural := 6_500_000; --130ms @ fclk=50MHz
   constant T_4: natural := 5_000_000; --100ms @ fclk=50MHz
   constant T_5: natural := 3_500_000; --70ms @ fclk=50MHz
   constant T_6: natural := 2_000_000; --40ms @ fclk=50MHz
   constant T_switch: natural := 1_000_000; --20ms @ fclk=50MHz
   signal tmax: natural range 0 to T_1; -- speed of segment
   signal t: integer range 0 to T_1;
   
   --Debouncer declaration
   constant db: natural := 2_500_000; -- debounce time in ms
   signal debounce: natural range 0 to freq * db / 1000;
	signal switching: boolean := false;
   
begin 

   --Timer (using strategy #1):
   process (clk, rst, stp)
   begin 
      if rst='1' then
         t <= T_1;
		elsif stp = '1' then
			t <= t; -- do nothing
      elsif rising_edge(clk) and stp='0' and t > 0 then
			if pr_state /= nx_state then -- state changed
				t <= 0;
			else
				t <= t + 1;
			end if;
		end if;
   end process;
   
   --FSM state register:
   process (clk, rst)
   begin 
      if rst='1' then
         pr_state <= A;
      elsif rising_edge(clk) then
         pr_state <= nx_state;
      end if;
   end process;
   
   --Debouncer:
   process (clk, rst, spd)
   begin
      if rst='1' then
         debounce <= db;
			tstate <= T1;
		elsif rising_edge(clk) and spd='1' then
			debounce <= db;
      elsif rising_edge(clk) and debounce > 0 then
			debounce <= debounce - 1;
			if debounce = 0 then
				case tstate is -- Button debounced, change timing state
					when T1 =>
						tstate <= T2;
					when T2 =>
						tstate <= T3;
					when T3 =>
						tstate <= T4;
					when T4 =>
						tstate <= T5;
					when T5 =>
						tstate <= T6;
					when T6 =>
						tstate <= T1;
				end case;
			end if;
      end if;
	end process;
	
	-- Use the state to set the time
	process (rst, clk)
	begin
		if rst = '1' then
			tmax <= T_1;
		elsif rising_edge(clk) and switching = true then
			tmax <= T_switch;
		elsif rising_edge(clk) then
			case tstate is -- Set the time for segments according to state
				when T1 =>
					tmax <= T_1;
				when T2 =>
					tmax <= T_2;
				when T3 =>
					tmax <= T_3;
				when T4 =>
					tmax <= T_4;
				when T5 =>
					tmax <= T_5;
				when T6 =>
					tmax <= T_6;
			end case;
		end if;
   end process;
		 
   
   --FSM combinational logic:
   process (clk, rst, stp, dir)
   begin
		if rst = '1' then
		   nx_state <= A;
		elsif stp = '1' then
			nx_state <= nx_state; -- do nothing
		else
		  case pr_state is
			 when A =>
				ssd <= "0111111";
				if t <= tmax then -- Time to change
					nx_state <= A;
					switching <= false;
				elsif dir = '1' then
					nx_state <= FA;
					switching <= true;
				else 
					nx_state <= AB;
					switching <= true;
				end if;
			 when AB =>
				ssd <= "0011111";
				if t <= tmax then
					nx_state <= AB; 
					switching <= true;
				elsif dir = '1' then
					nx_state <= A;
					switching <= false;
				else 
					nx_state <= B;
					switching <= false;
				end if;
			 when B =>
				ssd <= "1011111";
				if t <= tmax then
					nx_state <= B;
					switching <= false;
				elsif dir = '1' then
					nx_state <= AB;
					switching <= true;
				else 
					nx_state <= BC;
					switching <= true;
				end if;
			 when BC => 
				ssd <= "1001111";
				if t <= tmax then
					nx_state <= BC;
					switching <= true;
				elsif dir = '1' then
					nx_state <= B;
					switching <= false;
				else
					nx_state <= C;
					switching <= false;
				end if;
			 when C =>
				ssd <= "1101111";
				if t <= tmax then
					nx_state <= C;
					switching <= false;
				elsif dir = '1' then
					nx_state <= BC;
					switching <= true;
				else 
					nx_state <= CD;
					switching <= true;
				end if; 
			 when CD =>
				ssd <= "1100111";
				if t <= tmax then
					nx_state <= CD;
					switching <= true;
				elsif dir = '1' then
					nx_state <= C;
					switching <= false; 
				else 
					nx_state <= D;
					switching <= false;
				end if;
			 when D =>
				ssd <= "1110111";
				if t <= tmax then
					nx_state <= D;
					switching <= false;
				elsif dir = '1' then
					nx_state <= CD;
					switching <= true;
				else
					nx_state <= DE;
					switching <= true;
				end if; 
			 when DE =>
				ssd <= "1110011";
				if t <= tmax then
					nx_state <= DE;
					switching <= true;
				elsif dir = '1' then 
					nx_state <= D;
					switching <= false;
				else 
					nx_state <= E;
					switching <= false;
				end if;
			 when E =>
				ssd <= "1111011";
				if t <= tmax then 
					nx_state <= E;
					switching <= false;
				elsif dir = '1' then
					nx_state <= DE;
					switching <= true;
				else 
					nx_state <= EF;
					switching <= true;
				end if;
			 when EF =>
				ssd <= "1111001";
				if t <= tmax then
					nx_state <= EF;
					switching <= true;
				elsif dir = '1' then
					nx_state <= E; 
					switching <= false;
				else 
					nx_state <= F;
					switching <= false;
				end if; 
			 when F =>
				ssd <= "1111101";
				if t <= tmax then
					nx_state <= F;
					switching <= false;
				elsif dir = '1' then
					nx_state <= EF;
					switching <= true;
				else 
					nx_state <= FA;
					switching <= true;
				end if; 
			 when FA =>
				ssd <= "0111101";
				if t <= tmax then
					nx_state <= FA;
					switching <= true;
				elsif dir = '1'then
					nx_state <= F;
					switching <= false;
				else 
					nx_state <= A;
					switching <= false;
				end if; 
		  end case;
	  end if;
   end process;
      
end architecture;
----------------------------------
