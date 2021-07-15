use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity TB_MULTIPLY is
end entity TB_MULTIPLY;

architecture BEH of TB_MULTIPLY is
    component DUT is
        generic(
            PARTIAL_MULT        : natural := 2*EXTENDED_BYTE_WIDTH
        );
        port(
            CLK                 : in std_logic;
            RESET               : in std_logic;
            ENABLE              : in std_logic;

            FMAP                : in EXTENDED_BYTE_TYPE;
            KERNEL              : in EXTENDED_BYTE_TYPE;

            LOAD_KERNEL         : in std_logic;
            LOAD_NEXT_KERNEL    : in std_logic;

            RESULT              : out std_logic_vector(PARTIAL_MULT - 1 downto 0)
        );
    end component DUT;
    for all : DUT use entity WORK.MULTIPLY(BEH);

    constant COUNTER                : natural := 5;
    constant PARTIAL_MULT           : natural := 2*EXTENDED_BYTE_WIDTH;
    -- Device Under Test 1
    signal CLK, RESET               : std_logic;
    signal ENABLE_DUT1              : std_logic;
    signal LOAD_KERNEL_DUT1         : std_logic;
    signal LOAD_NEXT_KERNEL_DUT1    : std_logic;
    signal KERNEL_DUT1              : EXTENDED_BYTE_TYPE;
    signal FMAP_DUT1                : EXTENDED_BYTE_TYPE;
    signal RESULT_DUT1              : std_logic_vector(PARTIAL_MULT-1 downto 0);
    
    signal RESULT_NOW               : std_logic;

    -- for clock gen
    constant clock_period           : time := 10 ns;
    signal stop_the_clock           : boolean;
    signal QUIT_CLOCK1              : boolean := false;
    
begin

    DUT_i1 : DUT
    generic map(
        PARTIAL_MULT 
    )
    port map(
        CLK               => CLK,
        RESET             => RESET,
        ENABLE            => ENABLE_DUT1,
        FMAP              => FMAP_DUT1,
        KERNEL            => KERNEL_DUT1,
        LOAD_KERNEL       => LOAD_KERNEL_DUT1,
        LOAD_NEXT_KERNEL  => LOAD_NEXT_KERNEL_DUT1,
        RESULT            => RESULT_DUT1
    );
                
    STIMULUS_DUT_i1:
    process is
    begin
        ENABLE_DUT1             <= '0';
        LOAD_KERNEL_DUT1        <= '0';
        LOAD_NEXT_KERNEL_DUT1   <= '0';
        RESET                   <= '0';
        RESULT_DUT1             <= (others => '0');

        wait until CLK = '1' and CLK'event;
        RESET                   <= '1';
        wait until CLK = '1' and CLK'event;
        RESET                   <= '0';
        ENABLE_DUT1             <= '1';

        LOAD_NEXT_KERNEL_DUT1   <= '1';
        KERNEL_DUT1             <= std_logic_vector(to_unsigned(10, EXTENDED_BYTE_WIDTH));
        wait until '1'=CLK and CLK'event;
        

        LOAD_KERNEL_DUT1        <= '1';
        KERNEL_DUT1             <= std_logic_vector(to_unsigned(90, EXTENDED_BYTE_WIDTH));
        FMAP_DUT1               <= std_logic_vector(to_unsigned(10, EXTENDED_BYTE_WIDTH));
        wait until '1'=CLK and CLK'event;

        LOAD_NEXT_KERNEL_DUT1   <= '0';
        LOAD_KERNEL_DUT1        <= '0';
        FMAP_DUT1               <= std_logic_vector(to_unsigned(22, EXTENDED_BYTE_WIDTH));
        wait until '1'=CLK and CLK'event;

        FMAP_DUT1               <= std_logic_vector(to_unsigned(15, EXTENDED_BYTE_WIDTH));
        wait until '1'=CLK and CLK'event;

        LOAD_NEXT_KERNEL_DUT1   <= '0';
        LOAD_KERNEL_DUT1        <= '1';
        FMAP_DUT1               <= std_logic_vector(to_unsigned(10, EXTENDED_BYTE_WIDTH));
        wait until '1'=CLK and CLK'event;

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