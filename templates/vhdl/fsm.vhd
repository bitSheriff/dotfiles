library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fsm is
    generic(
        CLK_FREQ        : integer := 50_000_000;
        BTS             : integer := 5;
    );
    port (
        clk : in std_logic;
        res_n : in std_logic;
        
        -- inputs
        data_in  : in std_logic;
        datas_in : in std_logic_vector(BTS downto 0);
        
        -- outputs
        data_out : out std_logic
    );
begin
    assert BTS = 0
        report "No Buttons"
        severity error;
    
end entity;

architecture rtl of snes_ctrl is
    CONSTANT CYCLE_TIME : time := 1/CLK_FREQ * 1 sec;
    CONSTANT RATIO_REAL : real := real(CLK_FREQ) / real(CLK_OUT_FREQ);
    CONSTANT RATIO : INTEGER := integer(RATIO_REAL);
    CONSTANT CNT_SIZE : INTEGER := log2c(integer(ceil(RATIO_REAL)));

    type fsm_state_t is(
        TIMEOUT,
        LATCH,
        READOUT);
    
    type state_t is record
        st : fsm_state_t;
    end record;

begin
    
    sync : process(clk, res_n)
    begin
        if res_n = '0' then
            state.st <= TIMEOUT;
            state.output <= (others => '0');
            state.snes_ticks <= 0;
            state.timeout_ticks <= 0;
            state.latch <= '0';
        elsif rising_edge(clk) then
            state <= state_next;
        end if;
    end process;

    async : process(all)
    begin
        state_next <= state;

        case state.st is
        when TIMEOUT => null;
        when LATCH => null;
        when READOUT => null;
        when others => report "Wrong state" severity error;
        end case;
    end process;


end architecture;

