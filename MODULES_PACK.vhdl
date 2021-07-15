library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

package MODULES_PACK is
    constant BYTE_WIDTH : natural := 8;
    constant EXTENDED_BYTE_WIDTH : natural := BYTE_WIDTH+1;
    constant WORD_SIZE : natural := 4*BYTE_WIDTH;
    
    subtype BYTE_TYPE is std_logic_vector(BYTE_WIDTH-1 downto 0);
    subtype EXTENDED_BYTE_TYPE is std_logic_vector(EXTENDED_BYTE_WIDTH-1 downto 0);
    subtype MUL_HALFWORD_TYPE is std_logic_vector(2*EXTENDED_BYTE_WIDTH-1 downto 0);
    subtype HALFWORD_TYPE is std_logic_vector(2*BYTE_WIDTH-1 downto 0);
    subtype WORD_TYPE is std_logic_vector(WORD_SIZE-1 downto 0);

    type EXTENDED_BYTE_ARRAY is array(natural range <>) of EXTENDED_BYTE_TYPE;
    type BYTE_ARRAY_TYPE is array(natural range <>) of BYTE_TYPE;
    type INTEGER_ARRAY_TYPE is array(integer range <>) of integer;

    type INTEGER_ARRAY_2D_TYPE is array(natural range <>, natural range <>) of integer;
    type REG_ARRAY is array(integer range <>) of std_logic_vector(2*EXTENDED_BYTE_WIDTH - 1 downto 0);
    type REG_WORD_ARRAY is array(integer range <>) of WORD_TYPE;

end package ;