-- Copyright 2021 Sammuel Silva. All rights reserved.
--
-- This project is dual licensed under GNU General Public License version 3
-- and a commercial license available on request.
---------------------------------------------------------------------------
-- For non commercial use only:
-- This file is part of TINN TPU.
-- 
-- TINN TPU is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- TINN TPU is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with TINN TPU. If not, see <http://www.gnu.org/licenses/>.

--! @file MODULES_PACK.vhdl
--! @author Sammuel Silva

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

    -- Control types
    constant DATA_ADDRESS_WIDTH                     : natural := 24;
    constant ACCUMULATOR_ADDRESS_WIDTH              : natural := 16;
    constant KERNEL_ADDRESS_WIDTH                   : natural := DATA_ADDRESS_WIDTH + ACCUMULATOR_ADDRESS_WIDTH;
    
    subtype DATA_ADDRESS_TYPE is std_logic_vector(DATA_ADDRESS_WIDTH-1 downto 0);
    subtype ACCUMULATOR_ADDRESS_TYPE is std_logic_vector(ACCUMULATOR_ADDRESS_WIDTH-1 downto 0);
    subtype KERNEL_ADDRESS_TYPE is std_logic_vector(KERNEL_ADDRESS_WIDTH-1 downto 0);
    
    
    -- Function List
    function BITS_TO_BYTE_ARRAY(BITVECTOR : std_logic_vector) return BYTE_ARRAY_TYPE;
    function BYTE_ARRAY_TO_BITS(BYTE_ARRAY : BYTE_ARRAY_TYPE) return std_logic_vector;
end package ;

package body MODULES_PACK is

    -- @brief Convert a bit vector to a byte array
    function BITS_TO_BYTE_ARRAY(BITVECTOR : std_logic_vector) return BYTE_ARRAY_TYPE is
        variable BYTE_ARRAY : BYTE_ARRAY_TYPE(0 to ((BITVECTOR'LENGTH / BYTE_WIDTH)-1));
    begin
        for i in BYTE_ARRAY'RANGE loop
                BYTE_ARRAY(i) := BITVECTOR(i*BYTE_WIDTH + BYTE_WIDTH-1 downto i*BYTE_WIDTH);
        end loop;
        
        return BYTE_ARRAY;
    end function BITS_TO_BYTE_ARRAY;
    
    -- @brief Convert a  byte array to a bit vector
    function BYTE_ARRAY_TO_BITS(BYTE_ARRAY : BYTE_ARRAY_TYPE) return std_logic_vector is 
        variable BITVECTOR : std_logic_vector(((BYTE_ARRAY'LENGTH * BYTE_WIDTH)-1) downto 0);
    begin
        for i in BYTE_ARRAY'RANGE loop
            BITVECTOR(i*BYTE_WIDTH + BYTE_WIDTH-1 downto i*BYTE_WIDTH) := BYTE_ARRAY(i);
        end loop;
        
        return BITVECTOR;
    end function BYTE_ARRAY_TO_BITS;

end package body;