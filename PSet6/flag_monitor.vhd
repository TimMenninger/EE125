--------------------------
library ieee;
use ieee.std_logic_1164.all;
--------------------------
entity flag_monitor is
	port(
		clk, rst, window, flag_in: in std_logic;
		flag_out: out std_logic);
end entity;
--------------------------
architecture moore_fsm of flag_monitor is

	--FSM-related declarations:
	type state is (start, window_low, window_high_0, window_high_1, idle);
	signal pr_state, nx_state: state;

begin
	--FSM state register:
	process (clk, rst)
	begin
		if rst='1' then     
			pr_state <= start;
		elsif rising_edge(clk) then
			pr_state <= nx_state; 
		end if;
	end process; 
	
	--FSM Combinational logic:
	process (clk, rst, window, flag_in)
	begin
		case pr_state is
			when start => 
				flag_out <= '0';
				nx_state <= window_low;
			when window_low =>
				if window = '1' and flag_in = '1' then
					nx_state <= window_high_1;
				elsif window = '1' and flag_in = '0' then
					nx_state <= window_high_0; 
				else 
					nx_state <= window_low;
				end if;
			when window_high_1 =>
				if window = '1' and flag_in = '0' then
					nx_state <= idle;
				elsif window = '0' then
					flag_out <= '1'; 
					nx_state <= window_low;
				else
					nx_state <= window_high_1;
				end if;
			when window_high_0 =>
				if window = '1' and flag_in = '1' then
					nx_state <= idle;
				elsif window = '0' then
					flag_out <= '0';
					nx_state <= window_low;
				else
					nx_state <= window_high_0;
				end if; 
			when idle =>
				if window ='0' then
					nx_state <= window_low;
				else
					nx_state <= idle;
				end if;
		end case;
	end process;
end architecture
