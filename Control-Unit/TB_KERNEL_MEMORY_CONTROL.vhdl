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

--! @file TB_KERNEL_MEMORY_CONTROL.vhdl
--! @author Sammuel Silva

use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.math_real.log2;
    use IEEE.math_real.ceil;

entity TB_KERNEL_MEMORY_CONTROL is
end entity TB_KERNEL_MEMORY_CONTROL;

architecture BEH of TB_KERNEL_MEMORY_CONTROL is
    component DUT is
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
    end component DUT;
    for all : DUT use entity WORK.KERNEL_MEMORY_CONTROL(BEH);
    constant MEM_WIDTH          : natural := 3;

    signal CLK                  : std_logic;
    signal RESET                : std_logic;
    signal ENABLE               : std_logic;  

    signal INSTRUCTION          : KERNEL_INSTRUCTION_TYPE;
    signal INSTRUCTION_EN       : std_logic;
    signal END_KERNEL_USAGE     : std_logic;
    signal END_EXTERNAL_LOAD    : std_logic;
    signal KERNEL_READ_EN       : std_logic_vector(0 to MEM_WIDTH - 1);
    signal KERNEL_READ_ADDRESS  : KERNEL_ADDRESS_TYPE;
    signal SWITCH               : std_logic_vector(0 to MEM_WIDTH - 2);
    signal LOAD_NEXT            : std_logic;
    signal LOAD                 : std_logic;

    signal BUSY                 : std_logic;
    signal RESOURCE_BUSY        : std_logic;


    -- for clock gen
    constant clock_period           : time := 10 ns;
    signal stop_the_clock           : boolean := false;
    signal QUIT_CLOCK1              : boolean := false; 
begin
    DUT_i0 : DUT
    generic map(
        MEM_WIDTH => MEM_WIDTH
    )
    port map(
        CLK                 => CLK,
        RESET               => RESET,
        ENABLE              => ENABLE,

        INSTRUCTION         => INSTRUCTION,
        INSTRUCTION_EN      => INSTRUCTION_EN,
        END_KERNEL_USAGE    => END_KERNEL_USAGE,
        END_EXTERNAL_LOAD   => END_EXTERNAL_LOAD,
        KERNEL_READ_EN      => KERNEL_READ_EN,
        KERNEL_READ_ADDRESS => KERNEL_READ_ADDRESS,
        SWITCH              => SWITCH,
        LOAD_NEXT           => LOAD_NEXT,
        LOAD                => LOAD,

        BUSY                => BUSY,
        RESOURCE_BUSY       => RESOURCE_BUSY
    );

    STIMULUS_DUT :
    process is
    begin
        ENABLE              <= '0';
        RESET               <= '0';
        LOAD_NEXT           <= '0';
        LOAD                <= '0';
        BUSY                <= '0';
        RESOURCE_BUSY       <= '0';
        INSTRUCTION_EN      <= '0';
        END_KERNEL_USAGE    <= '0';
        END_EXTERNAL_LOAD   <= '0';

        wait until CLK = '1' and CLK'event;
        RESET                   <= '1';
        wait until CLK = '1' and CLK'event;
        RESET                   <= '0';
        ENABLE                  <= '1';
        
        wait until CLK = '1' and CLK'event;
        wait until CLK = '1' and CLK'event;
        wait until CLK = '1' and CLK'event;

        END_EXTERNAL_LOAD <= '1';
        wait until CLK = '1' and CLK'event;
        END_EXTERNAL_LOAD <= '0';

        INSTRUCTION.OP_CODE <= "00001001"; -- load weight
        INSTRUCTION.KERNEL_LENGTH <= std_logic_vector(to_unsigned(9, LENGTH_WIDTH));
        INSTRUCTION.KERNEL_ADDRESS <= x"0000000010";
        INSTRUCTION_EN <= '1';
        wait until CLK = '1' and CLK'event;
        INSTRUCTION_EN <= '0';

        for i in 0 to 7 loop
            wait until CLK = '1' and CLK'event;
        end loop;

        END_KERNEL_USAGE    <= '1';
        wait until CLK = '1' and CLK'event;
        END_KERNEL_USAGE    <= '0';

        INSTRUCTION.OP_CODE <= "00001001"; -- load weight
        INSTRUCTION.KERNEL_LENGTH <= std_logic_vector(to_unsigned(16, LENGTH_WIDTH));
        INSTRUCTION.KERNEL_ADDRESS <= x"0000000011";
        INSTRUCTION_EN <= '1';
        wait until CLK = '1' and CLK'event;
        INSTRUCTION_EN <= '0';

        for i in 0 to 15 loop
            if i = 3 then
                END_EXTERNAL_LOAD <= '1';
            end if;
            wait until CLK = '1' and CLK'event;
        end loop;

        stop_the_clock <= not QUIT_CLOCK1;

    end process STIMULUS_DUT;

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