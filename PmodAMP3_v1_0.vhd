----------------------------------------------------------------------------------
-- Company: System Chip Design Lab (Temple Univeristy Engineering)
-- Engineer: Andrew Powell
-- 
-- Create Date:    
-- Design Name: 
-- Module Name:    PmodAMP3_v1_0
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
-- 
-- This module is designed to output data to the Digilent PmodAMP3. 
--
-- The last 24 bits of "s00_axis_tdata" must be the data, whereas bit 25 of "s00_axis_tdata"
-- selects the channel.
--
-- Please know that this module assumes all data on "s00_axis_tdata" is valid; in other words,
-- it assumes s00_axis_tstrb is always "1111". Moreover, "s00_axis_tlast" is ignored. This module 
-- was only tested on the Digilent Atlys Board and the Avnet ZedBoard.
--
-- Dependencies: DownSample, ResetModule, PmodAMP3SampleData, PmodAMP3LoadData, PmodAMP3, PmodAMP3_v1_0_S00_AXIS
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PmodAMP3_v1_0 is
generic (
    C_S00_AXIS_TDATA_WIDTH	: integer	:= 32;
    AMP_DATA_WIDTH          : integer   := 24);
port (
    -- AXI4 Stream Interface
    s00_axis_aclk	: in std_logic; -- 50 MHz Clock
    s00_axis_aresetn	: in std_logic;
    s00_axis_tready	: out std_logic;
    s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
    s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
    s00_axis_tlast	: in std_logic;
    s00_axis_tvalid	: in std_logic;
    -- PmodAMP Peripheral Interface
    amp_sdata       : out std_logic;
    amp_nsd         : out std_logic;
    amp_lrclk       : out std_logic;
    amp_bclk        : out std_logic;
    amp_mclk        : out std_logic);
end PmodAMP3_v1_0;

architecture arch_imp of PmodAMP3_v1_0 is

    component PmodAMP3_v1_0_S00_AXIS is
        generic (
            C_S_AXIS_TDATA_WIDTH	: integer	:= 32);
        port (
            S_AXIS_ACLK	: in std_logic;
            S_AXIS_ARESETN	: in std_logic;
            S_AXIS_TREADY	: out std_logic;
            S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
            S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
            S_AXIS_TLAST	: in std_logic;
            S_AXIS_TVALID	: in std_logic;
            -- AMP Interface
            amp_data        : out std_logic_vector(AMP_DATA_WIDTH-1 downto 0);
            amp_ch          : out std_logic;
            amp_enable      : out std_logic;
            amp_ready       : in std_logic);
    end component PmodAMP3_v1_0_S00_AXIS;
    
    component PmodAMP3 is
        port(
            clock            : in std_logic;        -- Clock: 50 MHz
            reset            : in std_logic;        -- Reset: Synchronous
            enable           : in std_logic;        -- Handshake: Enable
            ready            : out std_logic;       -- Handshake: Ready
            ch               : in std_logic;        -- Input: '1'=Right Channel,'0'=Left Channel
            data             :                      -- Input: Data 
                in std_logic_vector((AMP_DATA_WIDTH-1) downto 0);
            amp_sdata        : out std_logic;       -- TDM: Serial Out
            amp_nsd          : out std_logic;       -- TDM: Power Save (Always '1')
            amp_lrclk        : out std_logic;       -- TDM: Channel 48.828 KHz Clock (Sample Frequency)
            amp_bclk         : out std_logic;       -- TDM: Bit 3.125 MHz Clock (64 Cycles Per LR Clock)
            amp_mclk         : out std_logic);      -- TDM: Master 12.5 MHz Clock
    end component PmodAMP3;
    
    signal amp_ready    : std_logic;
    signal amp_enable   : std_logic;
    signal amp_ch       : std_logic;
    signal amp_data     : std_logic_vector((AMP_DATA_WIDTH-1) downto 0);
    
begin

    -- AXI Controller
    PmodAMP3_v1_0_S00_AXIS_inst : PmodAMP3_v1_0_S00_AXIS
        generic map (
            C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH)
        port map (
            S_AXIS_ACLK	=> s00_axis_aclk,
            S_AXIS_ARESETN	=> s00_axis_aresetn,
            S_AXIS_TREADY	=> s00_axis_tready,
            S_AXIS_TDATA	=> s00_axis_tdata,
            S_AXIS_TSTRB	=> s00_axis_tstrb,
            S_AXIS_TLAST	=> s00_axis_tlast,
            S_AXIS_TVALID	=> s00_axis_tvalid,
            amp_data        => amp_data,
            amp_ch          => amp_ch,
            amp_enable      => amp_enable,
            amp_ready       => amp_ready);
            
    -- PmodAMP Peripheral
    PmodAMP3_0 : PmodAMP3 
        port map (
            clock       => s00_axis_aclk,
            reset       => "not"(s00_axis_aresetn),
            enable      => amp_enable,
            ready       => amp_ready,
            ch          => amp_ch,
            data        => amp_data,
            amp_sdata   => amp_sdata,
            amp_nsd     => amp_nsd,
            amp_lrclk   => amp_lrclk,
            amp_bclk    => amp_bclk,
            amp_mclk    => amp_mclk);   
end arch_imp;
