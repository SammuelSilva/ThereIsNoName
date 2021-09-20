-- Copyright 2021 Sammuel Silva. All rights reserved.
--
-- This project is dual licensed under GNU General Public License version 3
-- and a commercial license available on request.
---------------------------------------------------------------------------
-- For non commercial use only:
-- This file is part of TiNN.
-- 
-- TiNN is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- TiNN is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with TiNN. If not, see <http://www.gnu.org/licenses/>.

--! @file COUNTER_ADDRESS.vhdl
--! @author Sammuel Silva
--! @brief Counter Address

use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    
entity COUNTER_ADDRESS is
    generic(
        COUNT_WIDTH     : natural := 32;
        ADDRESS_WIDTH   : natural := 40;
        MEM_WIDTH       : natural := 3
    );
    port(
        CLK             : in std_logic;
        RESET_ALL   : in std_logic;
        RESET_CONTROL   : in std_logic;
        ENABLE          : in std_logic;

        START_VAL       : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        LOAD_ADDRESS    : in std_logic;

        KERNEL_LENGHT   : in std_logic_vector(COUNT_WIDTH-1 downto 0);
        LOAD_CONTROL    : in std_logic;

        KERNEL_READ_EN  : out std_logic_vector(0 to MEM_WIDTH - 1);
        COUNT_ADDRESS   : out std_logic_vector(ADDRESS_WIDTH-1 downto 0)
    );
end entity COUNTER_ADDRESS;

architecture BEH of COUNTER_ADDRESS is
    constant ONE             : std_logic_vector(ADDRESS_WIDTH-1 downto 0) := (ADDRESS_WIDTH-1 downto 1 => '0')&'1';
    constant ZEROS           : std_logic_vector(COUNT_WIDTH-1 downto 0) := (others => '0');
    
    --! Counter Address
    signal CLOAD_cs          : std_logic := '0';
    signal CLOAD_ns          : std_logic;

    signal RELOAD            : std_logic := '0';
    
    signal INPUT_ns          : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal INPUT_cs          : std_logic_vector(ADDRESS_WIDTH-1 downto 0) := (others => '0');

    signal COUNTER_INPUT_ns  : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal COUNTER_INPUT_cs  : std_logic_vector(ADDRESS_WIDTH-1 downto 0) := (others => '0');

    signal COUNTER_ns        : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal COUNTER_cs        : std_logic_vector(ADDRESS_WIDTH-1 downto 0) := (others => '0');


    --! Load Control
    signal MAX_LENGHT_ns     : std_logic_vector(COUNT_WIDTH-1 downto 0);
    signal MAX_LENGHT_cs     : std_logic_vector(COUNT_WIDTH-1 downto 0) := (others => '0');

    signal LOAD_cs           : std_logic := '0';
    signal LOAD_ns           : std_logic;

    signal READ_EN           : std_logic_vector(0 to MEM_WIDTH - 1) := (others => '0');
    signal COUNTER           : std_logic_vector(COUNT_WIDTH-1 downto 0);

    signal RESTART           : std_logic := '0';

    signal ACTIVATION_REG1    : std_logic := '0';
    signal ACTIVATION_REG2_ns : std_logic;
    signal ACTIVATION_REG2_cs : std_logic := '0';
    signal ACTIVATION         : std_logic;

    attribute use_dsp               : string;
    attribute use_dsp of COUNTER_ns : signal is "yes";
    attribute use_dsp of COUNTER    : signal is "yes";

begin
    --! Counter Address
    CLOAD_ns            <= LOAD_ADDRESS;

    INPUT_ns            <= START_VAL when LOAD_ADDRESS = '1' else ONE;
    COUNTER_INPUT_ns    <= INPUT_cs;

    COUNTER_ns          <= std_logic_vector(unsigned(COUNTER_cs) + unsigned(COUNTER_INPUT_cs)) when RELOAD = '0' else START_VAL;

    COUNT_ADDRESS       <= COUNTER_cs;

    --! Load Control
    MAX_LENGHT_ns       <= KERNEL_LENGHT;
    LOAD_ns             <= LOAD_CONTROL;

    KERNEL_READ_EN  <= READ_EN when COUNTER <= MAX_LENGHT_cs else (others => '0');

    ACTIVATION <= ACTIVATION_REG1;
    --ACTIVATION         <= ACTIVATION_REG2_cs;

    RESTART_PROCESS:
    process(RESTART) is
    begin
        if RESTART = '1' then
            RELOAD <= '1';
        else
            RELOAD <= '0';
        end if;
    end process RESTART_PROCESS;
    
    --RELOAD_cs <= RELOAD_ns;

    SEQ_LOG:
    process(CLK) is
        variable COUNT_AUX_v   : natural   := 0;
    begin
        if CLK'event and CLK = '1' then
        --! Counter Address Logic
            if RESET_ALL = '1' then
                COUNTER_INPUT_cs        <= (others => '0');
                INPUT_cs                <= (others => '0');
                CLOAD_cs                <= '0';
            else
                if ENABLE = '1' then
                    COUNTER_INPUT_cs    <= COUNTER_INPUT_ns;
                    INPUT_cs            <= INPUT_ns;
                    CLOAD_cs            <= CLOAD_ns;
                end if; 
            end if;
            
            if CLOAD_cs = '1' then
                COUNTER_cs              <= (others => '0');      
            else
                if ENABLE = '1' then
                    COUNTER_cs       <= COUNTER_ns;
                end if;
            end if;
        --! Load Control Logic
            if RESET_CONTROL = '1' or RESET_ALL = '1' then
                --LOAD_cs                 <= '0';
                COUNTER                 <= (others => '0');
                READ_EN                 <= (others => '0');
                MAX_LENGHT_cs           <= (others => '0');
                RESTART                 <= '0';
                ACTIVATION_REG1         <= '0';
                ACTIVATION_REG2_cs      <= '0';
            else
                if ENABLE = '1' then
                    LOAD_cs             <= LOAD_ns;
                    --ACTIVATION_REG2_cs  <= ACTIVATION_REG2_ns;

                    if RELOAD = '1' then
                        RESTART  <= '0';
                        COUNTER  <= std_logic_vector(unsigned(ZEROS) + MEM_WIDTH);
                        READ_EN <= (others => '1');
                    elsif ACTIVATION = '1' then
                        if (unsigned(COUNTER) + MEM_WIDTH) >= unsigned(MAX_LENGHT_cs) then
                            COUNT_AUX_v := to_integer(unsigned(MAX_LENGHT_cs) - unsigned(COUNTER));
                            READ_EN(COUNT_AUX_v to MEM_WIDTH - 1) <= (others => '0');
                            COUNTER  <= MAX_LENGHT_cs;
                            RESTART  <= '1';
                        else
                            READ_EN <= (others => '1');
                            COUNTER <= std_logic_vector(unsigned(COUNTER) + MEM_WIDTH);
                        end if;
                    end if;
                end if;
                
                if LOAD_cs = '1' then
                    MAX_LENGHT_cs    <= MAX_LENGHT_ns;
                    ACTIVATION_REG1  <= '1';
                end if;
            end if;

        end if;
    end process SEQ_LOG;
end architecture BEH;