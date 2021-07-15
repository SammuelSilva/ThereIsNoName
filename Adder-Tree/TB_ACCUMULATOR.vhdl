use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity TB_ACCUMULATOR is
end entity TB_ACCUMULATOR;

architecture BEH of TB_ACCUMULATOR is
    component DUT is
        generic(
            PARTIAL_ACC     : natural := 2*EXTENDED_BYTE_WIDTH + 1
        );
        port(
            CLK             : in std_logic;
            RESET           : in std_logic;
            ENABLE          : in std_logic;

            MULV1           : in std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0);
            MULV2           : in std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0);

            RESULT          : out std_logic_vector(PARTIAL_ACC downto 0)
        );
    end component DUT;
    for all : DUT use entity WORK.ACCUMULATOR(BEH);

    constant COUNTER                : natural := 5;
    constant PARTIAL_ACC            : natural := 2*EXTENDED_BYTE_WIDTH + 1;
    -- Device Under Test 1
    signal CLK, RESET               : std_logic;
    signal ENABLE_DUT1              : std_logic;
    signal MULV2_DUT1               : std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0);
    signal MULV1_DUT1               : std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0);
    signal RESULT_DUT1              : std_logic_vector(PARTIAL_ACC - 1 downto 0);
    
    signal RESULT_NOW               : std_logic;

    -- for clock gen
    constant clock_period           : time := 10 ns;
    signal stop_the_clock           : boolean;
    signal QUIT_CLOCK1              : boolean := false;
    
begin

    DUT_i1 : DUT
    generic map(
        PARTIAL_ACC 
    )
    port map(
        CLK         => CLK,
        RESET       => RESET,
        ENABLE      => ENABLE_DUT1,
        MULV1       => MULV1_DUT1,
        MULV2       => MULV2_DUT1,
        RESULT      => RESULT_DUT1
    );
                
    STIMULUS_DUT_i1:
    process is
    begin
        ENABLE_DUT1         <= '0';
        RESET               <= '0';
        RESULT_DUT1         <= (others => '0');

        wait until CLK = '1' and CLK'event;
        RESET               <= '1';
        wait until CLK = '1' and CLK'event;
        RESET               <= '0';
        ENABLE_DUT1         <= '1';     

        for pos in 0 to COUNTER-1 loop
            MULV2_DUT1         <= std_logic_vector(to_unsigned((pos+1), (PARTIAL_ACC - 1)));
            MULV1_DUT1         <= std_logic_vector(to_unsigned((pos+1+1)*10, (PARTIAL_ACC - 1)));
            wait until '1'=CLK and CLK'event;
        end loop;
         
        stop_the_clock <= not QUIT_CLOCK1;
    end process STIMULUS_DUT_i1;

    CLOCK_GEN: 
    process
    begin
        while not stop_the_clock loop
          CLK <= '0', '1' after clock_period / 2;
          wait for clock_period;
        end loop;
        wait;
    end process CLOCK_GEN;
end architecture BEH;