use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.math_real.log2;
    use IEEE.math_real.floor;
    use IEEE.math_real.ceil;

entity MULTIPLY_ADDER_TREE_UNIT is
    generic(
        MATRIX_WIDTH        : natural := 3
    );
    port(
        CLK, RESET          : in  std_logic;
        ENABLE              : in  std_logic;
        
        KERNEL              : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH*MATRIX_WIDTH-1); --!< Input dos pesos, conectados com a entrada de pesos no MACC.
        FMAP_WINDOW         : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH*MATRIX_WIDTH-1); --!< Os dados de entrada na diagonal.
        
        LOAD_NEXT_KERNEL    : in  std_logic; --!< Ativa os pesos carregados de forma sequenciais.
        LOAD_KERNEL         : in  std_logic; --!< Realiza o pre-carregamento de uma coluna com o WEIGHT_DATA.
        
        RESULT_DATA         : out WORD_TYPE --!< Resultado da multiplicação das matrizes
    );
end entity MULTIPLY_ADDER_TREE_UNIT;

architecture BEH of MULTIPLY_ADDER_TREE_UNIT is
    
    component MULTIPLY is
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
        end component MULTIPLY;
    for all : MULTIPLY use entity WORK.MULTIPLY(BEH);

    component ACCUMULATOR is
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
    end component ACCUMULATOR;
    for all : ACCUMULATOR use entity WORK.ACCUMULATOR(BEH);
    
    constant MATRIX_SIZE            : natural := MATRIX_WIDTH*MATRIX_WIDTH;
    constant BMATRIX_WIDTH          : std_logic_vector(BYTE_WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(MATRIX_SIZE, BYTE_WIDTH));
    constant ZERO_OR_ONE            : std_logic_vector(BYTE_WIDTH - 1 downto 0) := (BYTE_WIDTH-1 downto 1 => '0') & BMATRIX_WIDTH(0);
    constant BIT_ODD_CHECK          : natural := to_integer(unsigned(ZERO_OR_ONE));
    constant TREE_DEPTH             : natural := natural(ceil(log2(real(MATRIX_SIZE - 1))));

    --! General Signals
    signal REG_FMAP_ns              : BYTE_ARRAY_TYPE(0 to MATRIX_SIZE - 1);
    signal REG_FMAP_cs              : BYTE_ARRAY_TYPE(0 to MATRIX_SIZE - 1) := (others => (others => '0'));
    signal EXTENDED_KERNEL_DATA     : EXTENDED_BYTE_ARRAY(0 to MATRIX_SIZE - 1);
    signal EXTENDED_FMAP_DATA       : EXTENDED_BYTE_ARRAY(0 to MATRIX_SIZE - 1) := (others => (others => '0'));
    signal ZERO_SKIPPING_KERNEL     : std_logic_vector(0 to MATRIX_SIZE - 1) := (others => '0');
    signal ZERO_SKIPPING_FMAP       : std_logic_vector(0 to MATRIX_SIZE - 1) := (others => '0');
    
    signal MULT_RESULT              : REG_ARRAY(0 to MATRIX_SIZE - 1) := (others => (others => '0'));
    signal INTERIM_RESULT           : REG_WORD_ARRAY(0 to MATRIX_SIZE - 1 - 1) := (others => (others => '0'));
    signal ODD_MSIZE_PIPE_cs        : REG_WORD_ARRAY(0 to (TREE_DEPTH - 1 + 1)) := (others => (others => '0'));
    signal ODD_MSIZE_PIPE_ns        : REG_WORD_ARRAY(0 to (TREE_DEPTH - 1 + 1));

begin

    REG_FMAP_ns <= FMAP_WINDOW;

    SIGN_EXTEND_KERNEL:
    process(KERNEL) is
    begin
        for i in 0 to MATRIX_SIZE - 1 loop
            EXTENDED_KERNEL_DATA(i) <= '0' & KERNEL(i);

            if signed(KERNEL(i)) = 0 then
                ZERO_SKIPPING_KERNEL(i) <= '1';
            else
                ZERO_SKIPPING_KERNEL(i) <= '0';
            end if;
        end loop;
    end process SIGN_EXTEND_KERNEL;

    SIGN_EXTEND_FMAP:
    process(REG_FMAP_cs) is
    begin
        for i in 0 to MATRIX_SIZE - 1 loop
            EXTENDED_FMAP_DATA(i) <= '0' & REG_FMAP_cs(i);

            if signed(REG_FMAP_cs(i)) = 0 then
                ZERO_SKIPPING_FMAP(i) <= '1';
            else
                ZERO_SKIPPING_FMAP(i) <= '0';
            end if;
        end loop;
    end process SIGN_EXTEND_FMAP;
    
    ROOT_MULT_GEN:
    for i in 0 to MATRIX_SIZE-1 generate
        MULTIPLY0 : MULTIPLY
        generic map(
            PARTIAL_MULT        => 2*EXTENDED_BYTE_WIDTH
        )
        port map(
            CLK                 => CLK,
            RESET               => RESET,
            ENABLE              => ENABLE,
            FMAP                => EXTENDED_FMAP_DATA(i), 
            KERNEL              => EXTENDED_KERNEL_DATA(i),
            LOAD_KERNEL         => LOAD_KERNEL, 
            LOAD_NEXT_KERNEL    => LOAD_NEXT_KERNEL, 
            RESULT              => MULT_RESULT(i)
        );
    end generate ROOT_MULT_GEN;

    LEAFS_ACC_GEN:
    for i in 0 to TREE_DEPTH - 1 generate
        ROW_OF_LEAFS: 
        for j in 0 to natural(floor(real(MATRIX_SIZE/(2**(i+1))))) - 1  generate
            FIRST_ROW: 
            if i = 0 generate
                ACC0 : ACCUMULATOR
                generic map(
                    PARTIAL_ACC     => 2*EXTENDED_BYTE_WIDTH + 1
                )
                port map(
                    CLK             => CLK,
                    RESET           => RESET,
                    ENABLE          => ENABLE,
            
                    MULV1           => MULT_RESULT(2*j),
                    MULV2           => MULT_RESULT((2*j) + 1),
            
                    RESULT          => INTERIM_RESULT(j)(2*EXTENDED_BYTE_WIDTH + 1 - 1 downto 0)
                );
            end generate FIRST_ROW;
            
            SECOND_ROW:
            if i = 1 generate
                ACC0 : ACCUMULATOR
                generic map(
                    PARTIAL_ACC     => 2*EXTENDED_BYTE_WIDTH + i
                )
                port map(
                    CLK             => CLK,
                    RESET           => RESET,
                    ENABLE          => ENABLE,
            
                    MULV1           => INTERIM_RESULT(MATRIX_SIZE - natural(floor((real(MATRIX_SIZE/(2**(i-1)))))) + (2*j))(2*EXTENDED_BYTE_WIDTH + i - 1 - 1 downto 0),
                    MULV2           => INTERIM_RESULT(MATRIX_SIZE - natural(floor((real(MATRIX_SIZE/(2**(i-1)))))) + (2*j) + 1)(2*EXTENDED_BYTE_WIDTH + i - 1 - 1 downto 0),
            
                    RESULT          => INTERIM_RESULT(natural(floor(real(MATRIX_SIZE/(2**(i))))) + MATRIX_SIZE - natural(floor(real(MATRIX_SIZE/(2**(i-1))))) + j)(2*EXTENDED_BYTE_WIDTH + i - 1 downto 0)
                );
            end generate SECOND_ROW;

            DEEP_ROW:
            if i > 1 generate
                ACC0 : ACCUMULATOR
                generic map(
                    PARTIAL_ACC     => 2*EXTENDED_BYTE_WIDTH + i
                )
                port map(
                    CLK             => CLK,
                    RESET           => RESET,
                    ENABLE          => ENABLE,
            
                    MULV1           => INTERIM_RESULT(MATRIX_SIZE - natural(floor((real(MATRIX_SIZE/(2**(i-1)))))) + (2*j) - BIT_ODD_CHECK)(2*EXTENDED_BYTE_WIDTH + i - 1 - 1 downto 0),
                    MULV2           => INTERIM_RESULT(MATRIX_SIZE - natural(floor((real(MATRIX_SIZE/(2**(i-1)))))) + (2*j) + 1 - BIT_ODD_CHECK)(2*EXTENDED_BYTE_WIDTH + i - 1 - 1 downto 0),
            
                    RESULT          => INTERIM_RESULT(natural(floor(real(MATRIX_SIZE/(2**(i))))) + MATRIX_SIZE - natural(floor(real(MATRIX_SIZE/(2**(i-1))))) + j - BIT_ODD_CHECK)(2*EXTENDED_BYTE_WIDTH + i - 1 downto 0)
                );
            end generate DEEP_ROW;

        end generate ROW_OF_LEAFS;
    end generate LEAFS_ACC_GEN;
    
    ODD_CONECTION:
    if BIT_ODD_CHECK = 1 generate
        ODD_MSIZE_PIPE_ns(1 to (TREE_DEPTH - 1 + 1)) <= ODD_MSIZE_PIPE_cs(0 to (TREE_DEPTH - 1 + 1) - 1);
        ODD_MSIZE_PIPE_ns(0) <= (WORD_SIZE-1 downto 2*EXTENDED_BYTE_WIDTH => MULT_RESULT(MATRIX_SIZE - 1)(EXTENDED_BYTE_WIDTH-1)) & MULT_RESULT(MATRIX_SIZE - 1);
    end generate ODD_CONECTION;

    ODD_ROOT:
    if BIT_ODD_CHECK = 1 generate
        ACC0 : ACCUMULATOR
        generic map(
            PARTIAL_ACC     => 2*EXTENDED_BYTE_WIDTH + (TREE_DEPTH-1)
        )
        port map(
            CLK             => CLK,
            RESET           => RESET,
            ENABLE          => ENABLE,
            
            MULV1           => ODD_MSIZE_PIPE_ns(TREE_DEPTH - 1 + 1)(2*EXTENDED_BYTE_WIDTH + (TREE_DEPTH-1) - 1 - 1 downto 0),
            MULV2           => INTERIM_RESULT(MATRIX_SIZE - natural(floor((real(MATRIX_SIZE/(2**((TREE_DEPTH-1)-1)))))) + 1)(2*EXTENDED_BYTE_WIDTH + (TREE_DEPTH-1) - 1 - 1 downto 0),
            
            RESULT          => INTERIM_RESULT(MATRIX_SIZE - 1 - 1)(2*EXTENDED_BYTE_WIDTH + (TREE_DEPTH-1) - 1 downto 0)
        );
    end generate ODD_ROOT;

    RESULT_ASSIGNMENT:
    process(INTERIM_RESULT) is
        variable RESULT_DATA_v  : std_logic_vector(2*EXTENDED_BYTE_WIDTH + (TREE_DEPTH-1) - 1 downto 0);
        variable EXTEND_v       : std_logic_vector(WORD_SIZE-1 downto 2*EXTENDED_BYTE_WIDTH + (TREE_DEPTH-1)); -- 32bits Downto 32bits (tem 1 posicao)
    begin
        RESULT_DATA_v := INTERIM_RESULT(MATRIX_SIZE - 1 - 1)(2*EXTENDED_BYTE_WIDTH + (TREE_DEPTH-1) - 1 downto 0); -- RESULT_DATA_v armazena todos os valores da ultima linha da coluna i, exceto o ultimo bit armazenado
        EXTEND_v := (others => INTERIM_RESULT(MATRIX_SIZE - 1 - 1)(2*EXTENDED_BYTE_WIDTH + (TREE_DEPTH-1)-1)); -- Guarda o valor do ultimo dado (SINAL)
        
        RESULT_DATA <= EXTEND_v & RESULT_DATA_v; -- Concatena o resultado com o sinal
    end process RESULT_ASSIGNMENT;

    SEQ_LOG:
    process(CLK) is
    begin
        if CLK'event and CLK = '1' then
            if RESET = '1' then
                REG_FMAP_cs          <= (others => (others => '0'));
            else
                REG_FMAP_cs         <= REG_FMAP_ns;
            end if;
            ODD_MSIZE_PIPE_cs       <= ODD_MSIZE_PIPE_ns;
        end if;
    end process SEQ_LOG;
end architecture BEH;
    