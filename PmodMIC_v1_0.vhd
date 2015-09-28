----------------------------------------------------------------------------------
-- Company: System Chip Design Lab (Temple Univeristy Engineering)
-- Engineer: Andrew Powell
-- 
-- Create Date:    
-- Design Name: 
-- Module Name:    PmodMIC_v1_0
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
-- 
-- This module is designed to add a master AXI Stream interface to the PmodMIC
-- module. Setting "enable" to '1' and waiting until "ready" is equal to '1' causes
-- the PmodMIC to sample audio data, which is then acquired from the master AXI Stream
-- interface. In order to sample again, "enable" needs to be set to '0' until "ready"
-- returns to '0'.
--
-- Please note that "m00_axis_tstrb" is set to "1111" and "m00_axis_tlast" is set to
-- '1'. This module was only tested on the Digilent Atlys Board and Avent ZedBoard.
--
-- Dependencies: DownSample, ResetModule, PmodMIC, PmodMIC_v1_0_M00_AXIS
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PmodMIC_v1_0 is
	generic (
		-- Parameters of Axi Master Bus Interface M00_AXIS
		C_M00_AXIS_TDATA_WIDTH	: integer	:= 32;
		MIC_OUTPUT_WIDTH		: integer   := 12);
	port (
		-- Ports of Axi Stream Master Bus Interface 
		m00_axis_aclk	       : in std_logic;      -- 50 MHz Clock
		m00_axis_aresetn	   : in std_logic;       
		m00_axis_tvalid	       : out std_logic;
		m00_axis_tdata	       : out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		m00_axis_tstrb	       : out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast	       : out std_logic;
		m00_axis_tready	       : in std_logic;
		-- PmodMIC Interface
		mic_sclk               : out std_logic;
		mic_sdata              : in std_logic;
		mic_ss                 : out std_logic;
		-- Synchronization Interface
		enable                 : in std_logic;
		ready                  : out std_logic);
end PmodMIC_v1_0;

architecture arch_imp of PmodMIC_v1_0 is
	component PmodMIC_v1_0_M00_AXIS is
        generic (
            C_M_AXIS_TDATA_WIDTH	: integer	:= 32);
		port (
            M_AXIS_ACLK	    : in std_logic;
            M_AXIS_ARESETN	: in std_logic;
            M_AXIS_TVALID	: out std_logic;
            M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
            M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
            M_AXIS_TLAST	: out std_logic;
            M_AXIS_TREADY	: in std_logic;
            enable          : in std_logic;
            ready           : out std_logic;
            mic_enable      : out std_logic;
            mic_ready       : in std_logic;
            mic_output      : in std_logic_vector(MIC_OUTPUT_WIDTH-1 downto 0));
	end component PmodMIC_v1_0_M00_AXIS;
	component PmodMIC is
        port (
            signal clock        : in std_logic;        -- 50 MHz
            signal reset        : in std_logic;
            signal mic_ncs      : out std_logic;
            signal mic_sdata    : in std_logic;
            signal mic_sclk     : out std_logic;        -- 12.5 MHz
            signal output       : out std_logic_vector((MIC_OUTPUT_WIDTH-1) downto 0);
            signal enable       : in std_logic;
            signal ready        : out std_logic);
    end component;
	signal mic_ready : std_logic;
	signal mic_enable : std_logic;
	signal mic_output : std_logic_vector(MIC_OUTPUT_WIDTH-1 downto 0);
	signal mic_reset : std_logic;
begin

    mic_reset <= not m00_axis_aresetn;

    -- Instantiation of Axi Bus Interface M00_AXIS (Controller)
    PmodMIC_v1_0_M00_AXIS_inst : PmodMIC_v1_0_M00_AXIS
        generic map (
            C_M_AXIS_TDATA_WIDTH	=> C_M00_AXIS_TDATA_WIDTH)
        port map (
            M_AXIS_ACLK	    => m00_axis_aclk,
            M_AXIS_ARESETN	=> m00_axis_aresetn,
            M_AXIS_TVALID	=> m00_axis_tvalid,
            M_AXIS_TDATA	=> m00_axis_tdata,
            M_AXIS_TSTRB	=> m00_axis_tstrb,
            M_AXIS_TLAST	=> m00_axis_tlast,
            M_AXIS_TREADY	=> m00_axis_tready,
            enable          => enable,
            ready           => ready,
            mic_enable      => mic_enable,
            mic_ready       => mic_ready,
            mic_output      => mic_output);
	
	-- PmodMIC Driver
    PmodMIC_0 : PmodMIC
        port map (
            clock => m00_axis_aclk,
            reset => mic_reset,
            mic_ncs => mic_ss,
            mic_sdata => mic_sdata,
            mic_sclk => mic_sclk,
            output => mic_output,
            enable => mic_enable,
            ready => mic_ready);
end arch_imp;
