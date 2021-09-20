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

--! @file TB_COUNTER_ADDRESS.vhdl
--! @author Sammuel Silva

use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity TB_COUNTER_ADDRESS is
end entity TB_COUNTER_ADDRESS;

architecture BEH of TB_COUNTER_ADDRESS is
    component DUT is
        generic(
            COUNT_WIDTH     : natural := 32;
            ADDRESS_WIDTH   : natural := 40;
            MEM_WIDTH       : natural := 3
        );
        port(
            CLK             : in std_logic;
            RESET_ALL       : in std_logic;
            RESET_CONTROL   : in std_logic;
            ENABLE          : in std_logic;

            START_VAL       : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
            LOAD_ADDRESS    : in std_logic;

            KERNEL_LENGHT   : in std_logic_vector(COUNT_WIDTH-1 downto 0);
            LOAD_CONTROL    : in std_logic;

            KERNEL_READ_EN  : out std_logic_vector(0 to MEM_WIDTH - 1);
            COUNT_ADDRESS   : out std_logic_vector(ADDRESS_WIDTH-1 downto 0)
        );
    end component DUT;
    for all : DUT use entity WORK.COUNTER_ADDRESS(BEH);

    constant COUNT_WIDTH            : natural := 32;
    constant ADDRESS_WIDTH          : natural := 40;
    constant MEM_WIDTH              : natural := 3;

    -- Device Under Test 1
    signal CLK                      : std_logic;
    signal RESET_ALL                : std_logic;
    signal RESET_CONTROL            : std_logic;
    signal ENABLE                   : std_logic;
    signal START_VAL                : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal LOAD_ADDRESS             : std_logic;
    signal KERNEL_LENGHT            : std_logic_vector(COUNT_WIDTH-1 downto 0);
    signal LOAD_CONTROL             : std_logic;
    signal KERNEL_READ_EN           : std_logic_vector(0 to MEM_WIDTH - 1);
    signal COUNT_ADDRESS            : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    
    -- for clock gen
    constant clock_period           : time := 10 ns;
    signal stop_the_clock           : boolean;
    signal QUIT_CLOCK1              : boolean := false;
    
begin

    DUT_i1 : DUT
    generic map(
        COUNT_WIDTH     => COUNT_WIDTH,
        ADDRESS_WIDTH   => ADDRESS_WIDTH,
        MEM_WIDTH       => MEM_WIDTH

    )
    port map(
        CLK             => CLK,
        RESET_ALL       => RESET_ALL, 
        RESET_CONTROL   => RESET_CONTROL,     
        ENABLE          => ENABLE,

        START_VAL       => START_VAL,

        LOAD_ADDRESS    => LOAD_ADDRESS,
        KERNEL_LENGHT   => KERNEL_LENGHT,
        LOAD_CONTROL    => LOAD_CONTROL,
        
        KERNEL_READ_EN  => KERNEL_READ_EN,
        COUNT_ADDRESS   => COUNT_ADDRESS
    );
                
    STIMULUS_DUT_i1:
    process is
    begin
        ENABLE                  <= '0';
        LOAD_ADDRESS            <= '0';
        RESET_ALL               <= '0'; 
        RESET_CONTROL           <= '0';

        wait until CLK = '1' and CLK'event;
        RESET_ALL               <= '1';
        wait until CLK = '1' and CLK'event;
        RESET_ALL               <= '0';
        ENABLE                  <= '1';
        wait until CLK = '1' and CLK'event;
        LOAD_CONTROL            <= '1';
        LOAD_ADDRESS            <= '1';
        START_VAL               <= std_logic_vector(to_unsigned(10, ADDRESS_WIDTH));
        KERNEL_LENGHT           <= std_logic_vector(to_unsigned(9, COUNT_WIDTH));
        wait until '1'=CLK and CLK'event;
        LOAD_ADDRESS            <= '0';
        LOAD_CONTROL            <= '0';

        for i in 0 to 6 loop
            wait until '1'=CLK and CLK'event;
        end loop ;
        
        RESET_CONTROL           <= '1';
        wait until '1'=CLK and CLK'event;
        RESET_CONTROL           <= '0';
        LOAD_CONTROL            <= '1';
        LOAD_ADDRESS            <= '1';
        START_VAL               <= std_logic_vector(to_unsigned(2, ADDRESS_WIDTH));
        KERNEL_LENGHT           <= std_logic_vector(to_unsigned(25, COUNT_WIDTH));
        wait until '1'=CLK and CLK'event;
        LOAD_ADDRESS            <= '0';
        LOAD_CONTROL            <= '0';

        for i in 0 to 9 loop
            wait until '1'=CLK and CLK'event;
        end loop ;

        RESET_CONTROL           <= '1';
        wait until '1'=CLK and CLK'event;
        RESET_CONTROL           <= '0';
        LOAD_CONTROL            <= '1';
        LOAD_ADDRESS            <= '1';
        START_VAL               <= std_logic_vector(to_unsigned(22, ADDRESS_WIDTH));
        KERNEL_LENGHT           <= std_logic_vector(to_unsigned(64, COUNT_WIDTH));
        wait until '1'=CLK and CLK'event;
        LOAD_ADDRESS            <= '0';
        LOAD_CONTROL            <= '0';

        
        for i in 0 to 22 loop
            wait until '1'=CLK and CLK'event;
        end loop ;

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