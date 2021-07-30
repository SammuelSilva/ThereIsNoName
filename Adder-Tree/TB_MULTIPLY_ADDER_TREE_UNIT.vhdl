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

--! @file TB_MULTIPLY_ADDER_TREE_UNIT.vhdl
--! @author Sammuel Silva

use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity TB_MULTIPLY_ADDER_TREE_UNIT is
end entity TB_MULTIPLY_ADDER_TREE_UNIT;

architecture BEH of TB_MULTIPLY_ADDER_TREE_UNIT is
    component DUT is
        generic(
            MATRIX_WIDTH        : natural := 3
        );
        port(
            CLK, RESET          : in  std_logic;
            ENABLE              : in  std_logic;
            
            KERNEL              : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH*MATRIX_WIDTH -1); 
            FMAP_WINDOW         : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH*MATRIX_WIDTH -1); 
            
            LOAD_NEXT_KERNEL    : in  std_logic; 
            LOAD_KERNEL         : in  std_logic; 
            
            RESULT_DATA         : out WORD_TYPE 
        );
    end component DUT;
    for all : DUT use entity WORK.MULTIPLY_ADDER_TREE_UNIT(BEH);
    
    constant MATRIX_WIDTH           : natural := 3;

    signal CLK, RESET               : std_logic;
    signal ENABLE                   : std_logic;
    
    -- Arch signals
    signal KERNEL              :  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH*MATRIX_WIDTH -1); 
    signal FMAP_WINDOW         :  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH*MATRIX_WIDTH -1); 

    signal LOAD_NEXT_KERNEL    :  std_logic := '0'; 
    signal LOAD_KERNEL         :  std_logic := '0'; 

    signal RESULT_DATA         :  WORD_TYPE;
    
    -- for clock gen
    constant clock_period   : time := 10 ns;
    signal stop_the_clock   : boolean := false;
    
    signal START            : boolean;
    signal NEXT_FMAP        : boolean := false;
    signal EVALUATE         : boolean;
    signal QUIT_CLOCK0      : boolean;

    -- for data input simulation
    signal CURRENT_INPUT_0  : INTEGER_ARRAY_2D_TYPE(0 to MATRIX_WIDTH-1, 0 to MATRIX_WIDTH-1);
    signal CURRENT_INPUT_1  : INTEGER_ARRAY_2D_TYPE(0 to MATRIX_WIDTH-1, 0 to MATRIX_WIDTH-1);
    signal CURRENT_RESULT   : INTEGER_ARRAY_2D_TYPE(0 to MATRIX_WIDTH-1, 0 to MATRIX_WIDTH-1);
    
    
    constant IN_FMAP_1      : INTEGER_ARRAY_2D_TYPE :=
        (
            ( 74,  91,  64),
            (  5,  28,   2),
            (  2,   5,   7)
        );
    
    constant IN_KERNEL_1    : INTEGER_ARRAY_2D_TYPE :=
        (
            (  1,  0,  0),
            (  0,  1,  0),
            (  0,  0,  1)
        );

    constant IN_FMAP_2      : INTEGER_ARRAY_2D_TYPE :=
        (
            ( 74,   200,   64),
            (  150,  28, 114),
            (  2,     5,     7)
        );
    
    constant IN_KERNEL_2    : INTEGER_ARRAY_2D_TYPE :=
        (
            (  150,  200,  99),
            (  243,  33,    1),
            (  0,     0,   24)
        );
    
    constant IN_FMAP_3      : INTEGER_ARRAY_2D_TYPE :=
        (
            ( 74,   200,   64,    100),
            (150,    28,  114,    132),
            (  2,     5,    7,      9),
            (  0,     1,    3,      4)
        );
    
    constant IN_KERNEL_3    : INTEGER_ARRAY_2D_TYPE :=
        (
            ( 23,   145,   12,    100),
            (221,    22,  100,    200),
            (  0,     1,    1,      2),
            (  0,     2,    3,      0)
        );
begin

    DUT_i : DUT
    generic map(
        MATRIX_WIDTH => MATRIX_WIDTH
    )
    port map(
        CLK                 => CLK,
        RESET               => RESET,
        ENABLE              => ENABLE,
        KERNEL              => KERNEL,
        FMAP_WINDOW         => FMAP_WINDOW,
        LOAD_NEXT_KERNEL    => LOAD_NEXT_KERNEL,
        LOAD_KERNEL         => LOAD_KERNEL,
        RESULT_DATA         => RESULT_DATA
    );

    STIMULUS:
    process is
        procedure INITIALIZE
        is
        begin
            START               <= false;
            RESET               <= '0';
            ENABLE              <= '0';
            KERNEL              <= (others => (others => '0'));
            wait until '1'=CLK and CLK'event;

            -- RESET
            RESET               <= '1';
            wait until '1'=CLK and CLk'event;
            RESET               <= '0';
            ENABLE              <= '1';
        end procedure INITIALIZE;

        procedure LOAD_KERNEL_PROC(
            MATRIX : in INTEGER_ARRAY_2D_TYPE
        ) is
        begin
            for row in 0 to MATRIX_WIDTH - 1 loop
                for col in 0 to MATRIX_WIDTH - 1 loop
                    KERNEL(row * MATRIX_WIDTH + col) <= std_logic_vector(to_unsigned(MATRIX(row, col), BYTE_WIDTH));
                end loop;
            end loop;
        end procedure LOAD_KERNEL_PROC;

        procedure START_TEST 
        is
        begin
            START               <= true;
            LOAD_NEXT_KERNEL    <= '1';
            wait until '1'=CLK and CLK'event;
            LOAD_KERNEL_PROC(IN_KERNEL_2);
            START               <= false;
            wait until '1'=CLK and CLK'event;
            LOAD_NEXT_KERNEL    <= '0';
            for i in 0 to 6*MATRIX_WIDTH-1 loop
                wait until '1'=CLK and CLK'event;
            end loop;
        end procedure START_TEST;
    begin
        QUIT_CLOCK0      <= false;
        CURRENT_INPUT_0  <= IN_FMAP_1;
        CURRENT_INPUT_1  <= IN_FMAP_2;
        --CURRENT_RESULT  <= RESULT_MATRIX_S;
        INITIALIZE;
        LOAD_KERNEL_PROC(IN_KERNEL_1);
        START_TEST;
        QUIT_CLOCK0 <= true;
        wait;
    end process STIMULUS;

    PROCESS_INPUT_FMAP_0:
    process is
    begin
        wait until START = true;
        for row in 0 to MATRIX_WIDTH - 1 loop
            for col in 0 to MATRIX_WIDTH - 1 loop
                FMAP_WINDOW(row * MATRIX_WIDTH + col) <= std_logic_vector(to_unsigned(CURRENT_INPUT_0(row, col), BYTE_WIDTH));
            end loop;
        end loop;
        wait until '1'=CLK and CLK'event;
        LOAD_KERNEL <= '1';
        wait until '1'=CLK and CLK'event;
        LOAD_KERNEL <= '0';

        for row in 0 to MATRIX_WIDTH - 1 loop
            for col in 0 to MATRIX_WIDTH - 1 loop
                FMAP_WINDOW(row * MATRIX_WIDTH + col) <= std_logic_vector(to_unsigned(CURRENT_INPUT_1(row, col), BYTE_WIDTH));
            end loop;
        end loop;
        wait until '1'=CLK and CLK'event;
        LOAD_KERNEL <= '1';
        wait until '1'=CLK and CLK'event;
        LOAD_KERNEL <= '0';
    end process;

    stop_the_clock <= QUIT_CLOCK0;
    
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