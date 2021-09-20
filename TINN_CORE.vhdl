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

--! @file TINN_CORE.vhdl
--! @author Sammuel Silva
--! @brief TINN Core

--
use WORK.MODULES_PACK.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    
entity TINN_CORE is
    generic(
        MEM_WIDTH               : natural := 3; --!< A Largura da MMU e dos barramentos
        MEM_DEPTH_IN            : natural := 2**11; --!< A "profundidade" do Weight Buffer
        MEM_DEPTH_OUT           : natural := (2**11)/2; --!< A "Profundidade" do Unified Buffer
        MEM_DEPTH               : natural := 2**14
    );
    port(
        CLK, RESET              : in  std_logic;
        ENABLE                  : in  std_logic;
    
        --!< Inputs
        W_ADDRESS               : in KERNEL_ADDRESS_TYPE;
        W_KERNEL_EN             : in std_logic_vector(0 to MEM_WIDTH-1);
        W_KERNEL                : in BYTE_ARRAY_TYPE(0 to MEM_WIDTH-1);
        
        W_DATA_ET               : in BYTE_ARRAY_TYPE(0 to MEM_WIDTH-1);
        W_ADDR_ET               : in DATA_ADDRESS_TYPE;
        W_DATA_EN_ET            : in std_logic_vector(0 to MEM_WIDTH-1);

        --!< Outputs
        R_DATA_IT               : out BYTE_ARRAY_TYPE(0 to MEM_WIDTH-1)

        --!< Instructions inp[    
        --INSTRUCTION_PORT        : in  INSTRUCTION_TYPE; --!< Porta de Escrita para as instruções
        --INSTRUCTION_ENABLE      : in  std_logic; --!< Ativador de Escrita para instruções
        
        --!< Controls
        --BUSY                    : out std_logic; --!< A TPU ainda está ocupada e não pode receber nenhuma instrução.
        --SYNCHRONIZE             : out std_logic; --!< Interrupção de sincronização.
        --LOAD_INTERRUPTION       : out std_logic
    );
end entity TINN_CORE;

--! @brief The architecture of the TiNN core.
architecture BEH of TINN_CORE is
    component KERNEL_MEMORY is
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
    end component KERNEL_MEMORY;
    for all: KERNEL_MEMORY use entity WORK.KERNEL_MEMORY(BEH);
    
    signal KERNEL_ADDRESS   : KERNEL_ADDRESS_TYPE;
    signal KERNEL_EN        : std_logic_vector(0 to MEM_WIDTH-1);
    signal KERNEL           : BYTE_ARRAY_TYPE(0 to MEM_WIDTH-1);

    component DATA_MEMORY is
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
    end component DATA_MEMORY;
    for all: DATA_MEMORY use entity WORK.DATA_MEMORY(BEH);
    
    signal R_DATA_ADDRESS_IT   : DATA_ADDRESS_TYPE;
    signal R_DATA_EN_IT        : std_logic_vector(0 to MEM_WIDTH-1);

    signal W_DATA_ADDRESS_IT   : DATA_ADDRESS_TYPE;
    signal W_DATA_EN_IT        : std_logic_vector(0 to MEM_WIDTH-1);
    signal W_DATA_IT           : BYTE_ARRAY_TYPE(0 to MEM_WIDTH-1);

    signal R_DATA_ADDRESS_ET   : DATA_ADDRESS_TYPE;
    signal R_DATA_EN_ET        : std_logic_vector(0 to MEM_WIDTH-1);
    signal R_DATA_ET           : BYTE_ARRAY_TYPE(0 to MEM_WIDTH-1);

    component MULTIPLY_ADDER_TREE_UNIT is
        generic(
            MATRIX_WIDTH        : natural := 3
        );
        port(
            CLK, RESET          : in  std_logic;
            ENABLE              : in  std_logic;
            
            KERNEL              : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH*MATRIX_WIDTH-1); 
            FMAP_WINDOW         : in  BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH*MATRIX_WIDTH-1); 
            
            LOAD_NEXT_KERNEL    : in  std_logic; 
            LOAD_KERNEL         : in  std_logic; 
            
            RESULT_DATA         : out WORD_TYPE 
        );
    end component MULTIPLY_ADDER_TREE_UNIT;
    for all: MULTIPLY_ADDER_TREE_UNIT use entity WORK.MULTIPLY_ADDER_TREE_UNIT(BEH);

    signal LOAD_NEXT_KERNEL    : std_logic;
    signal LOAD_KERNEL         : std_logic;
    signal RESULT_DATA         : WORD_TYPE;
begin

    KERNEL_MEMORY_i : KERNEL_MEMORY
    generic map(
        MEM_WIDTH       => MEM_WIDTH,      
        MEM_DEPTH       => MEM_DEPTH
    )
    port map(
        CLK             => CLK,
        RESET           => RESET,      
        ENABLE          => ENABLE,          
                
        SWITCH          => SWITCH,          

        R_ADDRESS       => KERNEL_ADDRESS,       
        R_KERNEL_EN     => KERNEL_EN,     
        R_KERNEL        => KERNEL,        
        
        W_ADDRESS       => W_ADDRESS,       
        W_KERNEL_EN     => W_KERNEL_EN,     
        W_KERNEL        => W_KERNEL       
    );

    DATA_MEMORY_i : DATA_MEMORY
    generic map(
        MEM_WIDTH       => MEM_WIDTH,
        MEM_DEPTH_IN    => MEM_DEPTH_IN,
        MEM_DEPTH_OUT   => MEM_DEPTH_OUT
    )
    port map(
        CLK             => CLK,
        RESET           => RESET,
        ENABLE          => ENABLE,

        SWITCH_ET       => SWITCH_ET,
        SWITCH_IT       => SWITCH_IT,

        W_DATA_ET       => W_DATA_ET,
        W_ADDR_ET       => W_ADDRESS,
        W_DATA_EN_ET    => W_DATA_EN_ET,

        R_ADDRESS       => R_DATA_ADDRESS_ET,
        R_DATA_EN_ET    => R_DATA_EN_ET,
        R_DATA_ET       => R_DATA_ET,

        W_DATA_IT       => W_DATA_IT,
        W_ADDR_IT       => W_DATA_ADDRESS_IT,
        W_DATA_EN_IT    => W_DATA_EN_IT
    );

end architecture BEH;

