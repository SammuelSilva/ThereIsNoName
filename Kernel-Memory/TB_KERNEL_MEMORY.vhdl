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

--! @file TB_KERNEL_MEMORY.vhdl
--! @author Sammuel Silva

use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity TB_KERNEL_MEMORY is
end entity TB_KERNEL_MEMORY;

architecture BEH of TB_KERNEL_MEMORY is
    component DUT is
        generic(
            MEM_WIDTH       : natural := 3;
            MEM_DEPTH       : natural := 2**14 
        );
        port(
            CLK, RESET      : in  std_logic;
            ENABLE          : in  std_logic;
                
            -- Define the memory block to be used to read/write the data
            SWITCH          : in  std_logic_vector(0 to MEM_WIDTH - 2);

            -- Read data ports
            R_ADDRESS       : in  KERNEL_ADDRESS_TYPE; 
            R_KERNEL_EN     : in  std_logic_vector(0 to MEM_WIDTH - 1); 
            R_KERNEL        : out BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);
        
            -- Write data ports
            W_ADDRESS       : in  KERNEL_ADDRESS_TYPE;
            W_KERNEL_EN     : in  std_logic_vector(0 to MEM_WIDTH - 1); 
            W_KERNEL        : in  BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1) 
        );
    end component DUT;
    for all : DUT use entity WORK.KERNEL_MEMORY(BEH);

    constant MEM_WIDTH      : natural := 3;
    constant MEM_DEPTH      : natural := 2**4; 
    constant SIZE_AUX       : natural := 3;

    signal CLK, RESET       : std_logic;
    signal ENABLE           : std_logic;

    signal STOP_CLK         : boolean := false;
    signal END_EVALUATION   : boolean := false;
    constant INITIAL_POS    : natural := 0;
    constant FINAL_POS      : natural := INITIAL_POS + MEM_DEPTH;

    type DATA_RAM_IN is array (0 to FINAL_POS - 1) of BYTE_ARRAY_TYPE(0 to MEM_WIDTH-1);
    type DATA_RAM_OUT is array (0 to FINAL_POS - 1) of BYTE_ARRAY_TYPE(0 to MEM_WIDTH-1);
    signal DATA_IN_P0         : DATA_RAM_IN;
    signal DATA_IN_P1         : DATA_RAM_IN;
    signal DATA_OUT_P0        : DATA_RAM_OUT;
    signal DATA_OUT_P1        : DATA_RAM_OUT;
    
    signal SWITCH             : std_logic_vector(0 to MEM_WIDTH - 2);
    
    -- Read data ports
    signal R_ADDRESS          : KERNEL_ADDRESS_TYPE; 
    signal R_KERNEL_EN        : std_logic_vector(0 to MEM_WIDTH - 1); 
    signal R_KERNEL           : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1); 

    -- Write data ports
    signal W_ADDRESS          : KERNEL_ADDRESS_TYPE; 
    signal W_KERNEL_EN        : std_logic_vector(0 to MEM_WIDTH - 1); 
    signal W_KERNEL           : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);

-- For clock gen
    constant clock_period     : time := 10 ns;
    signal stop_the_clock     : boolean := false;
    signal R_ACTIVATE         : boolean := false;
    signal W_ACTIVATE         : boolean := false;
begin

    DUT_i0 : DUT
    generic map(
        MEM_WIDTH => MEM_WIDTH,
        MEM_DEPTH => MEM_DEPTH
    )
    port map(
        CLK          => CLK, 
        RESET        => RESET,      
        ENABLE       => ENABLE,
        SWITCH       => SWITCH,
        R_ADDRESS    => R_ADDRESS,
        R_KERNEL_EN  => R_KERNEL_EN,
        R_KERNEL     => R_KERNEL,
        W_ADDRESS    => W_ADDRESS,
        W_KERNEL_EN  => W_KERNEL_EN,
        W_KERNEL     => W_KERNEL        
    );

    STIMULUS:
    process is
    begin

        for position in INITIAL_POS to FINAL_POS-1 loop
            DATA_IN_P0(position) <= BITS_TO_BYTE_ARRAY(std_logic_vector(to_unsigned(5*position, BYTE_WIDTH*MEM_WIDTH)));
        end loop;
        
        for position in INITIAL_POS to FINAL_POS-1 loop
            DATA_IN_P1(position) <= BITS_TO_BYTE_ARRAY(std_logic_vector(to_unsigned(10*(position+5), BYTE_WIDTH*MEM_WIDTH)));
        end loop;

        ENABLE      <= '0';
        RESET       <= '0';
        R_KERNEL_EN <= (others => '0');
        W_KERNEL_EN <= (others => '0');
        SWITCH      <= (others => '0');

        wait until '1'= CLK and CLK'event;
        RESET       <= '1';
        wait until '1'= CLK and CLK'event;
        RESET       <= '0';
        ENABLE      <= '1';

        W_ACTIVATE  <= true; 
        SWITCH      <= "00";
        W_KERNEL_EN <= "111";
        wait until '1'= CLK and CLK'event;
        W_ACTIVATE  <= false; 
        for i in 0 to FINAL_POS-1 loop
            wait until '1'= CLK and CLK'event;
        end loop;
        
        for position in INITIAL_POS to FINAL_POS-1 loop
            DATA_IN_P0(position) <= BITS_TO_BYTE_ARRAY(std_logic_vector(to_unsigned(10*position, BYTE_WIDTH*MEM_WIDTH)));
        end loop;
        wait until '1'= CLK and CLK'event;

        W_ACTIVATE  <= true; 
        R_ACTIVATE  <= true;
        SWITCH      <= "10";
        R_KERNEL_EN <= "100";
        wait until '1'= CLK and CLK'event;
        R_ACTIVATE  <= false;
        W_ACTIVATE  <= false;
        for i in 0 to FINAL_POS-1 loop
            wait until '1'= CLK and CLK'event;
        end loop;
        
        for position in INITIAL_POS to FINAL_POS-1 loop
            DATA_IN_P0(position) <= BITS_TO_BYTE_ARRAY(std_logic_vector(to_unsigned(3*position, BYTE_WIDTH*MEM_WIDTH)));
        end loop;
        wait until '1'= CLK and CLK'event;
        wait until '1'= CLK and CLK'event;
        
        W_ACTIVATE  <= true; 
        R_ACTIVATE  <= true;
        SWITCH      <= "01";
        R_KERNEL_EN <= "100";
        wait until '1'= CLK and CLK'event;
        R_ACTIVATE  <= false;
        W_ACTIVATE  <= false;
        for i in 0 to FINAL_POS-1 loop
            wait until '1'= CLK and CLK'event;
        end loop;
        wait until '1'= CLK and CLK'event;
        wait until '1'= CLK and CLK'event;

        STOP_CLK <= true;
    end process;
    
    SWITCH_READ:
    process is
    begin
        wait until R_ACTIVATE = true;

        for position in INITIAL_POS to FINAL_POS-1 loop
            R_ADDRESS <= std_logic_vector(to_unsigned(position, KERNEL_ADDRESS_WIDTH));
            wait until '1'= CLK and CLK'event;
        end loop;

    end process;

    SWITCH_WRITE:
    process is
    begin
        wait until W_ACTIVATE = true;
        for position in INITIAL_POS to FINAL_POS-1 loop
            W_ADDRESS <= std_logic_vector(to_unsigned(position, KERNEL_ADDRESS_WIDTH));
            W_KERNEL  <= DATA_IN_P0(position);
            wait until '1'= CLK and CLK'event;
        end loop;
    end process;

    
    stop_the_clock <= STOP_CLK;

    CLOCK_GEN: 
    process
    begin
        while not stop_the_clock loop
          CLK <= '0', '1' after clock_period / 2;
          wait for clock_period;
        end loop;
        wait;
    end process;
end architecture BEH;
