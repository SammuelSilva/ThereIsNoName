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

--! @file KERNEL_MEMORY_CONTROL.vhdl
--! @author Sammuel Silva
--! @brief Kernel Memory Control (KMC) 

use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.math_real.log2;
    use IEEE.math_real.ceil;
    
entity KERNEL_MEMORY_CONTROL is
    generic(
        MEM_WIDTH            : natural := 3
    );
    port(
        CLK, RESET              : in std_logic;
        ENABLE                  : in std_logic;
    
        INSTRUCTION             : in KERNEL_INSTRUCTION_TYPE; 
        INSTRUCTION_EN          : in std_logic; 
        
        END_KERNEL_USAGE        : in std_logic; 
        END_EXTERNAL_LOAD       : in std_logic;

        KERNEL_READ_EN          : out std_logic_vector(0 to MEM_WIDTH - 1); 
        KERNEL_READ_ADDRESS     : out KERNEL_ADDRESS_TYPE; 
        
        SWITCH                  : out  std_logic_vector(0 to MEM_WIDTH - 2);

        LOAD_NEXT               : out std_logic; 
        LOAD                    : out std_logic; 

        BUSY                    : out std_logic; 
        RESOURCE_BUSY           : out std_logic  
    );
end entity KERNEL_MEMORY_CONTROL;

architecture BEH of KERNEL_MEMORY_CONTROL is
    component COUNTER_ADDRESS is
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
    end component COUNTER_ADDRESS;
    for all : COUNTER_ADDRESS use entity WORK.COUNTER_ADDRESS(BEH);
    
    signal CURR_SWITCH_cs      : std_logic_vector(0 to MEM_WIDTH - 2) := (others => '0');
    signal CURR_SWITCH_ns      : std_logic_vector(0 to MEM_WIDTH - 2);
    
    --! Control Signals
    signal RUNNING_ns          : std_logic;
    signal RUNNING_cs          : std_logic := '0';
    
    signal RUNNING_PIPE_cs     : std_logic_vector(0 to 4) := (others => '0');
    signal RUNNING_PIPE_ns     : std_logic_vector(0 to 4);
    
    --! Multiplication Load signals
    signal LOAD_REG0_ns        : std_logic;
    signal LOAD_REG1_ns        : std_logic;
    signal LOAD_REG2_ns        : std_logic;
    signal LOAD_REG3_ns        : std_logic;
    signal LOAD_REG4_ns        : std_logic;

    signal LOAD_REG0_cs        : std_logic := '0';
    signal LOAD_REG1_cs        : std_logic := '0';
    signal LOAD_REG2_cs        : std_logic := '0';
    signal LOAD_REG3_cs        : std_logic := '0';
    signal LOAD_REG4_cs        : std_logic := '0';

    --! Address counter signals
    signal ADDRESS_COUNTER_cs  : KERNEL_ADDRESS_TYPE := (others => '0');
    signal ADDRESS_COUNTER_ns  : KERNEL_ADDRESS_TYPE;
    --signal ADDRESS_RELOAD      : std_logic := '0';
    signal ADDRESS_LOAD_ns     : std_logic;
    signal ADDRESS_LOAD_cs     : std_logic := '0';

    --! Load control signals
    signal RESET_CALCULATION   : std_logic := '0';
    signal LOAD_LENGTH_ns      : std_logic;
    signal LOAD_LENGTH_cs      : std_logic := '0';
    signal KERNEL_READ_SEQ_cs  : std_logic_vector(0 to MEM_WIDTH - 1) := (others => '0');
    signal KERNEL_READ_SEQ_ns  : std_logic_vector(0 to MEM_WIDTH - 1);
begin
    LOAD_REG1_ns <= LOAD_REG0_cs;
    LOAD_REG2_ns <= LOAD_REG1_cs;
    LOAD_REG3_ns <= LOAD_REG2_cs;
    LOAD_REG4_ns <= LOAD_REG3_cs;
    LOAD_NEXT    <= LOAD_REG3_cs;
    LOAD         <= LOAD_REG4_cs;

    BUSY                     <= RUNNING_cs;
    RUNNING_PIPE_ns(0)       <= RUNNING_cs;
    RUNNING_PIPE_ns(1 to 2)  <= RUNNING_PIPE_cs(0 to 1);
    RUNNING_PIPE_ns(3 to 4)  <= RUNNING_PIPE_cs(2 to 3);

    SWITCH              <= CURR_SWITCH_cs;
    KERNEL_READ_ADDRESS <= ADDRESS_COUNTER_cs;
    KERNEL_READ_EN      <= KERNEL_READ_SEQ_cs;

    RESOURCE:
    process(RUNNING_cs, RUNNING_PIPE_cs) is
        variable RESOURCE_BUSY_v : std_logic;
    begin
        RESOURCE_BUSY_v := RUNNING_cs;
            for i in 0 to 4 loop
                RESOURCE_BUSY_v := RESOURCE_BUSY_v or RUNNING_PIPE_cs(i);
            end loop;
        RESOURCE_BUSY <= RESOURCE_BUSY_v;
    end process RESOURCE;

    ADDRESS_COUNTER_i: COUNTER_ADDRESS
    generic map (
        COUNT_WIDTH     =>  LENGTH_WIDTH,
        ADDRESS_WIDTH   =>  KERNEL_ADDRESS_WIDTH,
        MEM_WIDTH       =>  MEM_WIDTH
    )
    port map (
        CLK             =>  CLK,
        RESET_ALL       =>  RESET,
        RESET_CONTROL   =>  RESET_CALCULATION,
        ENABLE          =>  ENABLE,

        START_VAL       =>  INSTRUCTION.KERNEL_ADDRESS,
        LOAD_ADDRESS    =>  ADDRESS_LOAD_cs,

        KERNEL_LENGHT   =>  INSTRUCTION.KERNEL_LENGTH,
        LOAD_CONTROL    =>  LOAD_LENGTH_cs,

        KERNEL_READ_EN  =>  KERNEL_READ_SEQ_ns,
        COUNT_ADDRESS   =>  ADDRESS_COUNTER_ns
    );
    
    
    CONTROL:
    process(INSTRUCTION_EN, RUNNING_cs, END_KERNEL_USAGE) is
        variable INSTRUCTION_EN_v           : std_logic;
        variable RUNNING_cs_v               : std_logic;
        variable END_KERNEL_USAGE_v         : std_logic;
        
        variable RUNNING_ns_v               : std_logic;
        variable LOAD_LENGTH_v              : std_logic;
        variable RESET_CALCULATION_v        : std_logic;
        variable ADDRESS_LOAD_v             : std_logic;
        variable LOAD_NEXT_v                : std_logic;
    begin
        INSTRUCTION_EN_v    := INSTRUCTION_EN; 
        RUNNING_cs_v        := RUNNING_cs; 
        END_KERNEL_USAGE_v  := END_KERNEL_USAGE;
        
        --synthesis translate_off
        if INSTRUCTION_EN_v = '1' and RUNNING_cs_v = '1' then
            report "New Instruction shouldn't be feeded while processing! WEIGHT_CONTROL.vhdl" severity warning;
        end if;
        --synthesis translate_on
    
        if RUNNING_cs_v = '0' then 
            if INSTRUCTION_EN_v = '1' then 
                RUNNING_ns_v        := '1';
                ADDRESS_LOAD_v      := '1';
                RESET_CALCULATION_v := '1';
                LOAD_LENGTH_v       := '1';
                LOAD_NEXT_v         := '1';
            else
                RUNNING_ns_v        := '0';
                ADDRESS_LOAD_v      := '0';            
                RESET_CALCULATION_v := '0';
                LOAD_LENGTH_v       := '0';
                LOAD_NEXT_v         := '0';
            end if;
        else 
            if END_KERNEL_USAGE_v = '1' then
                RUNNING_ns_v        := '0';
                ADDRESS_LOAD_v      := '0';
                RESET_CALCULATION_v := '0';
                LOAD_LENGTH_v       := '0';
                LOAD_NEXT_v         := '0';
            else 
                RUNNING_ns_v        := '1';
                ADDRESS_LOAD_v      := '0';            
                RESET_CALCULATION_v := '0';
                LOAD_LENGTH_v       := '0';
                LOAD_NEXT_v         := '1';
            end if;
        end if;
        
        RUNNING_ns              <= RUNNING_ns_v;
        ADDRESS_LOAD_ns         <= ADDRESS_LOAD_v; 
        RESET_CALCULATION       <= RESET_CALCULATION_v;
        LOAD_LENGTH_ns          <= LOAD_LENGTH_v;
        LOAD_REG0_ns            <= LOAD_NEXT_v;
    end process CONTROL;
    
    --! @brief memory switch operation.
        -- If CURR_SWITCH_cs = '00' then the memory A is receiving data.
        -- If CURR_SWITCH_cs = '01' then the memory A is receiving data and memory B is being read.
        -- If CURR_SWITCH_cs = '11' then the memory B is receiving data.
        -- If CURR_SWITCH_cs = '10' then the memory B is receiving data and memory A is being read.
    MEMORY_SWITCH:
    process(END_EXTERNAL_LOAD, END_KERNEL_USAGE) is
        variable END_EXTERNAL_LOAD_v        : std_logic := '0';
        variable END_KERNEL_USAGE_v         : std_logic := '0';
        variable CURR_SWITCH_v              : std_logic_vector(0 to MEM_WIDTH - 2) := (others => '0');
    begin
        CURR_SWITCH_v       := CURR_SWITCH_cs;
        END_EXTERNAL_LOAD_v := END_EXTERNAL_LOAD;
        END_KERNEL_USAGE_v   := END_KERNEL_USAGE;

        if CURR_SWITCH_v = "00" then
            if END_EXTERNAL_LOAD_v = '1' then
                CURR_SWITCH_v := "10";
            end if;
        elsif CURR_SWITCH_v = "11" then
            if END_EXTERNAL_LOAD_v = '1' then
                CURR_SWITCH_v := "01";
            end if;
        elsif CURR_SWITCH_v = "01" then
            if END_KERNEL_USAGE_v = '1' then
                if END_EXTERNAL_LOAD_v = '1' then
                    CURR_SWITCH_v := "10";
                else
                    CURR_SWITCH_v := "00";
                end if;
            end if;
        elsif CURR_SWITCH_v = "10" then
            if END_KERNEL_USAGE_v = '1' then
                if END_EXTERNAL_LOAD_v = '1' then
                    CURR_SWITCH_v := "01";
                else
                    CURR_SWITCH_v := "11";
                end if;
            end if;
        end if;
        CURR_SWITCH_ns <= CURR_SWITCH_v;
    end process MEMORY_SWITCH;

    SEQ_LOG:
    process(CLK)
    begin
        if CLK'event and CLK = '1' then
            if RESET = '1' then
                RUNNING_cs      <= '0';
                CURR_SWITCH_cs  <= "00";
                RUNNING_PIPE_cs <= (others => '0');
                LOAD_REG0_cs    <= '0';
                LOAD_REG1_cs    <= '0';
                LOAD_REG2_cs    <= '0';
                LOAD_REG3_cs    <= '0';
                LOAD_REG4_cs    <= '0';
                ADDRESS_LOAD_cs <= '0';
                LOAD_LENGTH_cs  <= '0';
            else
                if ENABLE = '1' then
                    RUNNING_cs      <= RUNNING_ns;
                    CURR_SWITCH_cs  <= CURR_SWITCH_ns;

                    ADDRESS_LOAD_cs <= ADDRESS_LOAD_ns;
                    LOAD_LENGTH_cs  <= LOAD_LENGTH_ns;
                    
                    LOAD_REG0_cs    <= LOAD_REG0_ns;
                    LOAD_REG1_cs    <= LOAD_REG1_ns;
                    LOAD_REG2_cs    <= LOAD_REG2_ns;
                    LOAD_REG3_cs    <= LOAD_REG3_ns;
                    LOAD_REG4_cs    <= LOAD_REG4_ns;

                    RUNNING_PIPE_cs <= RUNNING_PIPE_ns;
                end if;
            end if;

            if RESET_CALCULATION = '1' then
                ADDRESS_COUNTER_cs <= (others => '0');
                KERNEL_READ_SEQ_cs <= (others => '0');
            else
                if ENABLE = '1' then
                    ADDRESS_COUNTER_cs <= ADDRESS_COUNTER_ns;
                    KERNEL_READ_SEQ_cs <= KERNEL_READ_SEQ_ns;
                end if;
            end if;
            
        end if;

    end process SEQ_LOG;

end architecture BEH;