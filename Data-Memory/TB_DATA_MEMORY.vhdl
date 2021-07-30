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

--! @file TB_DATA_MEMORY.vhdl
--! @author Sammuel Silva

use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity TB_DATA_MEMORY is
end entity TB_DATA_MEMORY;

architecture BEH of TB_DATA_MEMORY is
    component DUT is
        generic(
            MEM_WIDTH           : natural := 3;
            MEM_DEPTH_IN        : natural := 2**11;
            MEM_DEPTH_OUT       : natural := (2**11)/2
        );
        port(
            CLK, RESET          : in  std_logic;
            ENABLE              : in  std_logic;
                
            -- Define the memory block to be used to read/write the data
            SWITCH_ET           : in  std_logic_vector(0 to MEM_WIDTH - 2) := (others => '0');
            SWITCH_IT           : in  std_logic_vector(0 to MEM_WIDTH - 2) := (others => '0');

            -- Conections Port to External Data
                -- Write Operation
            W_DATA_ET           : in  BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);
            W_ADDR_ET           : in  DATA_ADDRESS_TYPE;
            W_DATA_EN_ET        : in  std_logic_vector(0 to MEM_WIDTH - 1); 
                -- Read Operation
            R_ADDR_ET           : in  DATA_ADDRESS_TYPE; 
            R_DATA_EN_ET        : in  std_logic_vector(0 to MEM_WIDTH - 1); 
            R_DATA_ET           : out BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1); 
        
            -- Conections Port to Internal Data
                -- Write Operation
            W_DATA_IT           : in  BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);
            W_ADDR_IT           : in  DATA_ADDRESS_TYPE;
            W_DATA_EN_IT        : in  std_logic_vector(0 to MEM_WIDTH - 1); 
                -- Read Operation
            R_ADDR_IT           : in  DATA_ADDRESS_TYPE; 
            R_DATA_EN_IT        : in  std_logic_vector(0 to MEM_WIDTH - 1); 
            R_DATA_IT           : out BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1)
        );
    end component DUT;
    for all : DUT use entity WORK.DATA_MEMORY(BEH);    
    
    constant MEM_WIDTH      : natural := 3;
    constant MEM_DEPTH_IN   : natural := 2**2;
    constant MEM_DEPTH_OUT  : natural := (2**2);

    signal CLK, RESET       : std_logic;
    signal ENABLE           : std_logic;

    signal STOP_CLK         : boolean := false;
    signal END_EVALUATION   : boolean := false;
    constant INITIAL_POS    : natural := 0;
    constant FINAL_POS      : natural := INITIAL_POS + MEM_DEPTH_IN;

    type DATA_RAM_IN is array (0 to FINAL_POS - 1) of BYTE_ARRAY_TYPE(0 to MEM_WIDTH-1);
    type DATA_RAM_OUT is array (0 to FINAL_POS - 1) of BYTE_ARRAY_TYPE(0 to MEM_WIDTH-1);
    
    signal DATA_IN_P0         : DATA_RAM_IN;
    signal DATA_OUT_P0        : DATA_RAM_OUT;
    signal DATA_IN_P1         : DATA_RAM_IN;
    signal DATA_OUT_P1        : DATA_RAM_OUT;

    signal SWITCH_ET          : std_logic_vector(0 to MEM_WIDTH - 2);
    signal SWITCH_IT          : std_logic_vector(0 to MEM_WIDTH - 2);

    -- Read data ports
    signal R_ADDR_ET          : DATA_ADDRESS_TYPE;
    signal R_DATA_EN_ET       : std_logic_vector(0 to MEM_WIDTH - 1);
    signal R_DATA_ET          : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);
    signal R_ADDR_IT          : DATA_ADDRESS_TYPE;
    signal R_DATA_EN_IT       : std_logic_vector(0 to MEM_WIDTH - 1);
    signal R_DATA_IT          : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);


    -- Write data ports
    signal W_DATA_ET          : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);
    signal W_ADDR_ET          : DATA_ADDRESS_TYPE;
    signal W_DATA_EN_ET       : std_logic_vector(0 to MEM_WIDTH - 1);
    signal W_DATA_IT          : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);
    signal W_ADDR_IT          : DATA_ADDRESS_TYPE;
    signal W_DATA_EN_IT       : std_logic_vector(0 to MEM_WIDTH - 1);

-- For clock gen
    constant clock_period     : time := 10 ns;
    signal stop_the_clock     : boolean := false;
    signal W_ACTIVATE_ET      : boolean := false;
    signal R_ACTIVATE_ET      : boolean := false;
    signal W_ACTIVATE_IT      : boolean := false;
    signal R_ACTIVATE_IT      : boolean := false;

begin
    DUTi0 : DUT
    generic map (
        MEM_WIDTH           => MEM_WIDTH,
        MEM_DEPTH_IN        => MEM_DEPTH_IN,
        MEM_DEPTH_OUT       => MEM_DEPTH_OUT
    )
    port map (
        CLK               => CLK,
        RESET             => RESET,
        ENABLE            => ENABLE,
        SWITCH_ET         => SWITCH_ET,
        SWITCH_IT         => SWITCH_IT,
        W_DATA_ET         => W_DATA_ET,
        W_ADDR_ET         => W_ADDR_ET,
        W_DATA_EN_ET      => W_DATA_EN_ET,
        W_DATA_IT         => W_DATA_IT,
        W_ADDR_IT         => W_ADDR_IT,
        W_DATA_EN_IT      => W_DATA_EN_IT,
        R_ADDR_ET         => R_ADDR_ET,
        R_DATA_EN_ET      => R_DATA_EN_ET,
        R_DATA_ET         => R_DATA_ET,
        R_ADDR_IT         => R_ADDR_IT,
        R_DATA_EN_IT      => R_DATA_EN_IT,
        R_DATA_IT         => R_DATA_IT
    );
    
    STIMULUS:
    process is
    begin

        for position in INITIAL_POS to FINAL_POS-1 loop
            DATA_IN_P0(position) <= BITS_TO_BYTE_ARRAY(std_logic_vector(to_unsigned((position + 1), BYTE_WIDTH*MEM_WIDTH)));
        end loop;
        

        ENABLE          <= '0';
        RESET           <= '0';
        R_DATA_EN_ET    <= (others => '0');
        W_DATA_EN_ET    <= (others => '0');
        SWITCH_ET       <= (others => '0');
        R_DATA_EN_IT    <= (others => '0');
        W_DATA_EN_IT    <= (others => '0');
        SWITCH_IT       <= (others => '0');

        wait until '1'= CLK and CLK'event;
        RESET           <= '1';
        wait until '1'= CLK and CLK'event;
        RESET           <= '0';
        ENABLE          <= '1';

        W_ACTIVATE_ET   <= true; 
        SWITCH_ET       <= "00";
        W_DATA_EN_ET    <= "111";
        wait until '1'= CLK and CLK'event;
        W_ACTIVATE_ET   <= false; 
        for i in 0 to FINAL_POS-1 loop
            wait until '1'= CLK and CLK'event;
        end loop;
        
        for position in INITIAL_POS to FINAL_POS-1 loop
            DATA_IN_P1(position) <= DATA_IN_P0(position);
            DATA_IN_P0(position) <= BITS_TO_BYTE_ARRAY(std_logic_vector(to_unsigned(3*(position + 1), BYTE_WIDTH*MEM_WIDTH)));
        end loop;
        wait until '1'= CLK and CLK'event;

        W_ACTIVATE_ET  <= true;
        R_ACTIVATE_ET  <= true;
        W_ACTIVATE_IT  <= true;
        SWITCH_ET      <= "10"; 
        SWITCH_IT      <= "00"; 
        R_DATA_EN_ET   <= "100";
        W_DATA_EN_IT   <= "111";
        wait until '1'= CLK and CLK'event;
        W_ACTIVATE_ET  <= false;
        R_ACTIVATE_ET  <= false;
        W_ACTIVATE_IT  <= false;
        for i in 0 to FINAL_POS-1 loop
            wait until '1'= CLK and CLK'event;
        end loop;

        W_ACTIVATE_ET  <= true;
        R_ACTIVATE_ET  <= true;
        W_ACTIVATE_IT  <= true;
        R_ACTIVATE_IT  <= true;
        SWITCH_ET      <= "10"; 
        SWITCH_IT      <= "10"; 
        R_DATA_EN_ET   <= "100";
        R_DATA_EN_IT   <= "100";
        W_DATA_EN_IT   <= "111";
        W_DATA_EN_ET   <= "000";
        wait until '1'= CLK and CLK'event;
        W_ACTIVATE_ET  <= false;
        R_ACTIVATE_ET  <= false;
        W_ACTIVATE_IT  <= false;
        R_ACTIVATE_IT  <= false;
        for i in 0 to FINAL_POS-1 loop
            wait until '1'= CLK and CLK'event;
        end loop;
        
        for position in INITIAL_POS to FINAL_POS-1 loop
            DATA_IN_P0(position) <= BITS_TO_BYTE_ARRAY(std_logic_vector(to_unsigned(7*(position + 1), BYTE_WIDTH*MEM_WIDTH)));
        end loop;
        wait until '1'= CLK and CLK'event;

        W_ACTIVATE_ET  <= true;
        R_ACTIVATE_ET  <= true;
        W_ACTIVATE_IT  <= true;
        R_ACTIVATE_IT  <= true;
        SWITCH_ET      <= "01"; 
        SWITCH_IT      <= "10"; 
        R_DATA_EN_ET   <= "100";
        R_DATA_EN_IT   <= "000";
        W_DATA_EN_IT   <= "111";
        W_DATA_EN_ET   <= "111";
        wait until '1'= CLK and CLK'event;
        W_ACTIVATE_ET  <= false;
        R_ACTIVATE_ET  <= false;
        W_ACTIVATE_IT  <= false;
        R_ACTIVATE_IT  <= false;
        for i in 0 to FINAL_POS-1 loop
            wait until '1'= CLK and CLK'event;
        end loop;
        
        for position in INITIAL_POS to FINAL_POS-1 loop
            DATA_IN_P1(position) <= DATA_IN_P0(position);
        end loop;
        wait until '1'= CLK and CLK'event;

        W_ACTIVATE_ET  <= true;
        R_ACTIVATE_ET  <= true;
        W_ACTIVATE_IT  <= true;
        R_ACTIVATE_IT  <= true;
        SWITCH_ET      <= "01"; 
        SWITCH_IT      <= "01"; 
        R_DATA_EN_ET   <= "100";
        R_DATA_EN_IT   <= "100";
        W_DATA_EN_IT   <= "111";
        W_DATA_EN_ET   <= "000";
        wait until '1'= CLK and CLK'event;
        W_ACTIVATE_ET  <= false;
        R_ACTIVATE_ET  <= false;
        W_ACTIVATE_IT  <= false;
        R_ACTIVATE_IT  <= false;
        for i in 0 to 2*FINAL_POS-1 loop
            wait until '1'= CLK and CLK'event;
        end loop;

        STOP_CLK <= true;
    end process;
    
    SWITCH_READ_IT:
    process is
    begin
        wait until R_ACTIVATE_IT = true;

        for position in INITIAL_POS to FINAL_POS-1 loop
            R_ADDR_IT <= std_logic_vector(to_unsigned(position, DATA_ADDRESS_WIDTH));
            wait until '1'= CLK and CLK'event;
        end loop;

    end process;

    SWITCH_WRITE_IT:
    process is
    begin
        wait until W_ACTIVATE_IT = true;
        for position in INITIAL_POS to FINAL_POS-1 loop
            W_ADDR_IT <= std_logic_vector(to_unsigned(position, DATA_ADDRESS_WIDTH));
            W_DATA_IT <= DATA_IN_P1(position);
            wait until '1'= CLK and CLK'event;
        end loop;
    end process;

    SWITCH_READ_ET:
    process is
    begin
        wait until R_ACTIVATE_ET = true;

        for position in INITIAL_POS to FINAL_POS-1 loop
            R_ADDR_ET <= std_logic_vector(to_unsigned(position, DATA_ADDRESS_WIDTH));
            wait until '1'= CLK and CLK'event;
        end loop;

    end process;

    SWITCH_WRITE_ET:
    process is
    begin
        wait until W_ACTIVATE_ET = true;
        for position in INITIAL_POS to FINAL_POS-1 loop
            W_ADDR_ET <= std_logic_vector(to_unsigned(position, DATA_ADDRESS_WIDTH));
            W_DATA_ET <= DATA_IN_P0(position);
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
