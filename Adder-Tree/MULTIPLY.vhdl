use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity MULTIPLY is
    generic(
        PARTIAL_MULT        : natural := 2*EXTENDED_BYTE_WIDTH
    );
    port (
        CLK                 : in std_logic;
        RESET               : in std_logic;
        ENABLE              : in std_logic;

        FMAP                : in EXTENDED_BYTE_TYPE;
        KERNEL              : in EXTENDED_BYTE_TYPE;

        LOAD_KERNEL         : in std_logic;
        LOAD_NEXT_KERNEL    : in std_logic;

        RESULT              : out std_logic_vector(PARTIAL_MULT - 1 downto 0)
    );
end entity MULTIPLY;

architecture BEH of MULTIPLY is

    signal FMAP_ns          : EXTENDED_BYTE_TYPE;
    signal FMAP_cs          : EXTENDED_BYTE_TYPE := (others => '0');

    signal KERNEL_ns        : EXTENDED_BYTE_TYPE;
    signal KERNEL_cs        : EXTENDED_BYTE_TYPE := (others => '0');

    signal PRE_KERNEL_ns    : EXTENDED_BYTE_TYPE;
    signal PRE_KERNEL_cs    : EXTENDED_BYTE_TYPE := (others => '0');

    signal RESULT_ns        : std_logic_vector(PARTIAL_MULT - 1 downto 0);
    signal RESULT_cs        : std_logic_vector(PARTIAL_MULT - 1 downto 0) := (others => '0');

    signal PROCESSING       : std_logic := '0';
begin

    FMAP_ns         <= FMAP;

    PRE_KERNEL_ns   <= KERNEL;
    KERNEL_ns       <= PRE_KERNEL_cs;
    
    MULT:
    process(FMAP_cs, KERNEL_cs) is
        variable FMAP_v     : EXTENDED_BYTE_TYPE;
        variable KERNEL_v   : EXTENDED_BYTE_TYPE;
        variable RESULT_v   : std_logic_vector(PARTIAL_MULT - 1 downto 0);
    begin
        FMAP_v      := FMAP_cs;
        KERNEL_v    := KERNEL_cs;
        RESULT_v    := std_logic_vector(unsigned(FMAP_v) * unsigned(KERNEL_v));

        RESULT_ns   <= RESULT_v;
    end process MULT;
    
    RESULT <= RESULT_cs;

    SEQ_LOG:
    process(CLK) is
    begin
        if CLK'event and CLK = '1' then
            if RESET = '1' then
                KERNEL_cs   <= (others => '0');
                FMAP_cs     <= (others => '0');
                RESULT_cs   <= (others => '0');
                PROCESSING  <= '0';
            else
                if LOAD_KERNEL = '1' then
                    KERNEL_cs   <= KERNEL_ns;
                    PROCESSING  <= '1';
                end if;

                if LOAD_NEXT_KERNEL = '1' then
                    PRE_KERNEL_cs   <= PRE_KERNEL_ns;
                end if;
                
                if ENABLE = '1' and (PROCESSING = '1' or LOAD_KERNEL = '1') then
                    FMAP_cs     <= FMAP_ns;
                    RESULT_cs   <= RESULT_ns;
                end if;
            end if;
        end if;
    end process SEQ_LOG;

end BEH ;
