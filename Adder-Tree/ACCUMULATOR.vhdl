-- Copyright 2021 Sammuel Silva. All rights reserved.
--
-- This project is dual licensed under GNU General Public License version 3
-- and a commercial license available on request.
---------------------------------------------------------------------------
-- For non commercial use only:
-- This file is part of TINN.
-- 
-- TINN is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- TINN is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with TINN. If not, see <http://www.gnu.org/licenses/>.

--! @file ACCUMULATOR.vhdl
--! @author Sammuel Silva
--! @brief accumulator
-- This file contains the definition of the accumulator function.
-- Prety simple, just a add function.

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

    signal RESULT_ns     : std_logic_vector(PARTIAL_ACC - 1 downto 0);
    signal RESULT_cs     : std_logic_vector(PARTIAL_ACC - 1 downto 0) := (others => '0');

begin

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
                RESULT_cs  <= (others => '0');
            else
                
                if ENABLE = '1' then
                    RESULT_cs   <= RESULT_ns;
                end if;
            end if;
        end if;
    end process SEQ_LOG;

end BEH ;
