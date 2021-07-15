use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity ACCUMULATOR is
    generic(
        PARTIAL_ACC     : natural := 2*EXTENDED_BYTE_WIDTH + 1
    );
    port (
        CLK             : in std_logic;
        RESET           : in std_logic;
        ENABLE          : in std_logic;

        MULV1           : in std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0);
        MULV2           : in std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0);

        RESULT          : out std_logic_vector(PARTIAL_ACC - 1 downto 0)
    );
end entity ACCUMULATOR;

architecture BEH of ACCUMULATOR is

    --signal MULV1_ns      : std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0);
    --signal MULV1_cs      : std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0) := (others => '0');

    --signal MULV2_ns      : std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0);
    --signal MULV2_cs      : std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0) := (others => '0');

    signal RESULT_ns     : std_logic_vector(PARTIAL_ACC - 1 downto 0);
    signal RESULT_cs     : std_logic_vector(PARTIAL_ACC - 1 downto 0) := (others => '0');

begin

    --MULV1_ns     <= MULV1;
    --MULV2_ns     <= MULV2;

    ACC:
    process(MULV1, MULV2) is
        variable MULV1_v    : std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0);
        variable MULV2_v    : std_logic_vector(PARTIAL_ACC - 1 - 1 downto 0);
        variable RESULT_v   : std_logic_vector(PARTIAL_ACC - 1 downto 0);
    begin
        MULV1_v     := MULV1;
        MULV2_v     := MULV2;
        RESULT_v    := std_logic_vector(unsigned(MULV1_v(MULV1_v'HIGH) & MULV1_v) + unsigned(MULV2_v(MULV2_v'HIGH) & MULV2_v));

        RESULT_ns   <= RESULT_v;
    end process ACC;
    
    RESULT <= RESULT_cs;

    SEQ_LOG:
    process(CLK) is
    begin
        if CLK'event and CLK = '1' then
            if RESET = '1' then
                --MULV2_cs   <= (others => '0');
                --MULV1_cs   <= (others => '0');
                RESULT_cs  <= (others => '0');
            else
                
                if ENABLE = '1' then
                    --MULV1_cs    <= MULV1_ns;
                    --MULV2_cs    <= MULV2_ns;
                    RESULT_cs   <= RESULT_ns;
                end if;
            end if;
        end if;
    end process SEQ_LOG;

end BEH ;
