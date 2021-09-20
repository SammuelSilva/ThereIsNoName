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

--! @file KERNEL_MEMORY.vhdl
--! @author Sammuel Silva
--! @brief Kernel Memory

-- This file contains the definition of the memory used to store the weights used by the TINN
-- There is two memories that are mutually exclusive. 
-- If Mem A is receiving a write operation, the Mem B is doing a read operation or is in a IDLE state.

use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity KERNEL_MEMORY is
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
        R_ADDRESS       : in  KERNEL_ADDRESS_TYPE; --!< Endereço da porta 0.
        R_KERNEL_EN     : in  std_logic_vector(0 to MEM_WIDTH - 1); --!< Ativação da porta 0.
        R_KERNEL        : out BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1); --!< Leitura da porta 0.
    
        -- Write data ports
        W_ADDRESS       : in  KERNEL_ADDRESS_TYPE; --!< Endereço da porta 1.
        W_KERNEL_EN     : in  std_logic_vector(0 to MEM_WIDTH - 1); --!< Ativação da porta 1.
        W_KERNEL        : in  BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1) --!< Escrita da porta 1.
    );
end entity KERNEL_MEMORY;

architecture BEH of KERNEL_MEMORY is
    type RAM_TYPE is array(0 to MEM_DEPTH-1) of std_logic_vector(MEM_WIDTH*BYTE_WIDTH-1 downto 0);

    signal W_KERNEL_BITS          : std_logic_vector(MEM_WIDTH*BYTE_WIDTH-1 downto 0);
    signal R_KERNEL_BITS          : std_logic_vector(MEM_WIDTH*BYTE_WIDTH-1 downto 0);

    signal R_KERNEL_REG0_cs       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1) := (others => (others => '0'));
    signal R_KERNEL_REG0_ns       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);
    signal R_KERNEL_REG1_cs       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1) := (others => (others => '0'));
    signal R_KERNEL_REG1_ns       : BYTE_ARRAY_TYPE(0 to MEM_WIDTH - 1);

    
    shared variable RAM_A  : RAM_TYPE
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
    
    shared variable RAM_B  : RAM_TYPE
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

    attribute ram_style          : string;
    attribute ram_style of RAM_A : variable is "block";
    attribute ram_style of RAM_B : variable is "block";
begin
    --! @brief Converting the Kernel value to a binary string.
    W_KERNEL_BITS    <= BYTE_ARRAY_TO_BITS(W_KERNEL);

    --! @brief Converting the binary string to a kernel value.
    R_KERNEL_REG0_ns <= BITS_TO_BYTE_ARRAY(R_KERNEL_BITS);
    R_KERNEL_REG1_ns <= R_KERNEL_REG0_cs;
    R_KERNEL         <= R_KERNEL_REG1_cs;

    --! @brief Kernel memory write operation.
        -- SWITCH(0) equals to '0' means that the memory A will recive the data coming from the external memory.
        -- Else, the memory B will reciver the data coming from the external memory.
        -- The W_KERNEL_EN signal is used to enable the write operation in a memory position.
    WRITE:
    process(CLK) is
    begin
        if CLK'event and CLK = '1' then
            for i in 0 to MEM_WIDTH - 1 loop
                if W_KERNEL_EN(i) = '1' then
                    if SWITCH(0) = '0' then
                        RAM_A(to_integer(unsigned(W_ADDRESS)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) := W_KERNEL_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    else
                        RAM_B(to_integer(unsigned(W_ADDRESS)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) := W_KERNEL_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    end if;
                end if;
            end loop;
        end if;
    end process WRITE;

    --! @brief Kernel memory read operation.
        -- SWITCH equals to "01", means tht the data will be read from the memory B.
        -- SWITCH equals to "10", means the data will be read from the memory A.
        -- The R_KERNEL_EN signal is used to enable the read operation in a memory position.
    READ:
    process(CLK) is
    begin
        if CLK'event and CLK = '1' then
            for i in 0 to MEM_WIDTH - 1 loop
                if R_KERNEL_EN(i) = '1' then
                    if SWITCH = "01" then
                        R_KERNEL_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) <= RAM_B(to_integer(unsigned(R_ADDRESS)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    end if;
                    if SWITCH = "10" then
                        R_KERNEL_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) <= RAM_A(to_integer(unsigned(R_ADDRESS)))((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH);
                    end if;
                else
                    R_KERNEL_BITS((i + 1) * BYTE_WIDTH - 1 downto i * BYTE_WIDTH) <= (others => '0');
                end if;
            end loop;
        end if;
    end process READ;

    SEQ_LOG:
    process(CLK) is
    begin
        if CLK'event and CLK = '1' then
            if RESET = '1' then
                R_KERNEL_REG0_cs    <= (others => (others => '0'));
                R_KERNEL_REG1_cs    <= (others => (others => '0'));
            else
                if ENABLE = '1' then 
                    R_KERNEL_REG0_cs <= R_KERNEL_REG0_ns;
                    R_KERNEL_REG1_cs <= R_KERNEL_REG1_ns;
                end if;
            end if;
        end if;
    end process SEQ_LOG;
end architecture BEH;