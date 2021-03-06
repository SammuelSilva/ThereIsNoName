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

--! @file DATA_MEMORY.vhdl
--! @author Sammuel Silva
--! @brief Data memory

-- This file contains the definition of the memory used to store the input feature maps used by the TINN
-- There is four memories: Memory A, Memory B, Memory C and Memory D.
-- Memory A and B are used to store the input feature maps comming from the external memory, and
-- are read by the TINN to perform the convolutional operations.
-- Memory C and D are used to store the output feature maps generated by the convolutional operations and send the
-- result to the external memory. 

use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.math_real.sqrt;

entity DATA_MEMORY is
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

        
        -- Conections Port to External Data: Write Operation
        W_DATA_ET           : in  BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);
        W_ADDR_ET           : in  DATA_ADDRESS_TYPE;
        W_DATA_EN_ET        : in  std_logic_vector(0 to MEM_WIDTH - 1); 
        -- Conections Port to Internal Data: Read Operation
        R_ADDR_ET           : in  DATA_ADDRESS_TYPE; 
        R_DATA_EN_ET        : in  std_logic_vector(0 to MEM_WIDTH - 1); 
        R_DATA_ET           : out BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1); 
    
        -- Conections Port to Internal Data: Write Operation
        W_DATA_IT           : in  BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);
        W_ADDR_IT           : in  DATA_ADDRESS_TYPE;
        W_DATA_EN_IT        : in  std_logic_vector(0 to MEM_WIDTH - 1); 
        -- Conections Port to External Data: Read Operation
        R_ADDR_IT           : in  DATA_ADDRESS_TYPE; 
        R_DATA_EN_IT        : in  std_logic_vector(0 to MEM_WIDTH - 1); 
        R_DATA_IT           : out BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1)
    );
end entity DATA_MEMORY;

architecture BEH of DATA_MEMORY is
    type RAM_IN_TYPE is array(0 to MEM_DEPTH_IN-1) of std_logic_vector(MEM_WIDTH*BYTE_WIDTH-1 downto 0);
    type RAM_OUT_TYPE is array(0 to MEM_DEPTH_OUT-1) of std_logic_vector(MEM_WIDTH*BYTE_WIDTH-1 downto 0);

    signal W_DATA_ET_BITS          : std_logic_vector(MEM_WIDTH*BYTE_WIDTH-1 downto 0);
    signal W_DATA_IT_BITS          : std_logic_vector(MEM_WIDTH*BYTE_WIDTH-1 downto 0);
    signal R_DATA_ET_BITS          : std_logic_vector(MEM_WIDTH*BYTE_WIDTH-1 downto 0);
    signal R_DATA_IT_BITS          : std_logic_vector(MEM_WIDTH*BYTE_WIDTH-1 downto 0);

    signal R_DATA_ET_REG0_cs       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1) := (others => (others => '0'));
    signal R_DATA_ET_REG0_ns       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);
    signal R_DATA_ET_REG1_cs       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1) := (others => (others => '0'));
    signal R_DATA_ET_REG1_ns       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);

    signal R_DATA_IT_REG0_cs       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1) := (others => (others => '0'));
    signal R_DATA_IT_REG0_ns       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);
    signal R_DATA_IT_REG1_cs       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1) := (others => (others => '0'));
    signal R_DATA_IT_REG1_ns       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);

    shared variable RAM_A  : RAM_IN_TYPE
    --synthesis translate_off
        :=
        -- Test values - Identity
        (
            0  => BYTE_ARRAY_TO_BITS((x"80", x"00", x"00")),
            1  => BYTE_ARRAY_TO_BITS((x"00", x"80", x"00")),
            2  => BYTE_ARRAY_TO_BITS((x"00", x"00", x"80")),
            others => (others => '0')
        )
    --synthesis translate_on
    ;
    
    shared variable RAM_B  : RAM_IN_TYPE
    --synthesis translate_off
        :=
        -- Test values
        (
            0  => BYTE_ARRAY_TO_BITS((x"00", x"00", x"00")),
            1  => BYTE_ARRAY_TO_BITS((x"00", x"00", x"00")),
            2  => BYTE_ARRAY_TO_BITS((x"00", x"00", x"00")),
            others => (others => '0')
        )
        --synthesis translate_on
    ;

    shared variable RAM_C  : RAM_OUT_TYPE
    --synthesis translate_off
        :=
        -- Test values - Identity
        (
            0  => BYTE_ARRAY_TO_BITS((x"00", x"00", x"00")),
            1  => BYTE_ARRAY_TO_BITS((x"00", x"00", x"00")),
            2  => BYTE_ARRAY_TO_BITS((x"00", x"00", x"80")),
            others => (others => '0')
        )
    --synthesis translate_on
    ;
    
    shared variable RAM_D  : RAM_OUT_TYPE
    --synthesis translate_off
        :=
        -- Test values
        (
            0  => BYTE_ARRAY_TO_BITS((x"00", x"00", x"00")),
            1  => BYTE_ARRAY_TO_BITS((x"00", x"00", x"00")),
            2  => BYTE_ARRAY_TO_BITS((x"00", x"00", x"00")),
            others => (others => '0')
        )
        --synthesis translate_on
    ;

    attribute ram_style           : string;
    attribute ram_style of RAM_A  : variable is "block";
    attribute ram_style of RAM_B  : variable is "block";
    attribute ram_style of RAM_C  : variable is "block";
    attribute ram_style of RAM_D  : variable is "block";

begin
    -- Convert the data to be written in the internal data memory representation
    W_DATA_ET_BITS <= BYTE_ARRAY_TO_BITS(W_DATA_ET);
    W_DATA_IT_BITS <= BYTE_ARRAY_TO_BITS(W_DATA_IT);

    -- Convert the data to the convolutional operation representation
    R_DATA_ET_REG0_ns <= BITS_TO_BYTE_ARRAY(R_DATA_ET_BITS);
    R_DATA_IT_REG0_ns <= BITS_TO_BYTE_ARRAY(R_DATA_IT_BITS);
    
    R_DATA_ET_REG1_ns <= R_DATA_ET_REG0_cs;
    R_DATA_ET         <= R_DATA_ET_REG1_cs; -- Data read to internal operations

    R_DATA_IT_REG1_ns <= R_DATA_IT_REG0_cs;
    R_DATA_IT         <= R_DATA_IT_REG1_cs; -- Data read to external memory
    
    --! @brief Data memory write operation.
        -- SWITCH_ET(0) equals to '0' means that the memory A will reciver the data coming from the external memory.
        -- Else, the memory B will reciver the data coming from the external memory.
        -- The W_DATA_EN_ET signal is used to enable the write operation in a memory position.

        -- SWITCH_IT(0) equals to '0' means that the memory D will reciver the data coming from the convolutional operations.
        -- Else, the memory C will reciver the data coming from the convolutional operations.
        -- The W_DATA_EN_IT signal is used to enable the write operation in a memory position.
    WRITE:
    process(CLK) is
    begin
        if CLK'event and CLK = '1' then
            for i in 0 to MEM_WIDTH - 1 loop
                if W_DATA_EN_ET(i) = '1' then
                    if SWITCH_ET(0) = '0' then
                        RAM_A(to_integer(unsigned(W_ADDR_ET)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) := W_DATA_ET_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    else
                        RAM_B(to_integer(unsigned(W_ADDR_ET)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) := W_DATA_ET_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    end if;
                end if;

                if W_DATA_EN_IT(i) = '1' then
                    if SWITCH_IT(0) = '0' then
                        RAM_C(to_integer(unsigned(W_ADDR_IT)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) := W_DATA_IT_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    else
                        RAM_D(to_integer(unsigned(W_ADDR_IT)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) := W_DATA_IT_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    end if;
                end if;
            end loop;
        end if;
    end process WRITE;
    
    --! @brief Data memory read operation.
        -- Convolutional Operations
            -- SWITCH_ET equals to "01", means tht the data will be read from the memory B.
            -- SWITCH_ET equals to "10", means the data will be read from the memory A.
            -- The R_KERNEL_EN signal is used to enable the read operation in a memory position.
        -- Read to external memory
            -- SWITCH_IT equals to "01", means tht the data will be read from the memory D.
            -- SWITCH_IT equals to "10", means the data will be read from the memory C.
            -- The R_KERNEL_IT signal is used to enable the read operation in a memory position.
    READ:
    process(CLK) is
    begin
        if CLK'event and CLK = '1' then
            for i in 0 to MEM_WIDTH - 1 loop
                if R_DATA_EN_ET(i) = '1' then
                    if SWITCH_ET = "01" then
                        R_DATA_ET_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) <= RAM_B(to_integer(unsigned(R_ADDR_ET)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    end if;
                    if SWITCH_ET = "10" then
                        R_DATA_ET_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) <= RAM_A(to_integer(unsigned(R_ADDR_ET)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    end if;
                else
                    R_DATA_ET_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) <= (others => '0');
                end if;

                if R_DATA_EN_IT(i) = '1' then
                    if SWITCH_IT = "01" then
                        R_DATA_IT_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) <= RAM_D(to_integer(unsigned(R_ADDR_IT)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    end if;
                    if SWITCH_IT = "10" then
                        R_DATA_IT_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) <= RAM_C(to_integer(unsigned(R_ADDR_IT)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    end if;
                else
                    R_DATA_IT_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) <= (others => '0');
                end if;
            end loop;
        end if;
    end process READ;

    SEQ_LOG:
    process(CLK) is
    begin
        if CLK'event and CLK = '1' then
            if RESET = '1' then
                R_DATA_ET_REG0_cs    <= (others => (others => '0'));
                R_DATA_ET_REG1_cs    <= (others => (others => '0'));
                R_DATA_IT_REG0_cs    <= (others => (others => '0'));
                R_DATA_IT_REG1_cs    <= (others => (others => '0'));
            else
                if ENABLE = '1' then 
                    R_DATA_ET_REG0_cs <= R_DATA_ET_REG0_ns;
                    R_DATA_ET_REG1_cs <= R_DATA_ET_REG1_ns;

                    R_DATA_IT_REG0_cs <= R_DATA_IT_REG0_ns;
                    R_DATA_IT_REG1_cs <= R_DATA_IT_REG1_ns;
                end if;
            end if;
        end if;
    end process SEQ_LOG;
end architecture BEH;