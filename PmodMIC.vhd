----------------------------------------------------------------------------------
-- Company: System Chip Design Lab (Temple Univeristy Engineering)
-- Engineer: Andrew Powell
-- 
-- Create Date:    23:15:12 08/27/2015 
-- Design Name: 
-- Module Name:    PmodMIC - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
-- 
-- This module is designed to acquire data from the Digilent PmodMIC. 
--
-- The synchronous "reset" must be held for 8 clock cycles for proper reset.
--
-- The "enable" and "ready" are the syncrhonizing handshaking signals. The module
-- will attempt to acquire an audio sample from the PmodMIC once the "enable" is set
-- to '1'. The data is available on the "output" once "ready" is set to '1'. "ready"
-- will only go back to '0' once "enable" is set to '0'.
--
-- This module was only tested on the Digilent Atlys Board.
--
-- Dependencies: DownSample, ResetModule
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use IEEE.STD_LOGIC_ARITH.ALL;	

entity PmodMIC is
	-- Do not change any of the generics.
	generic (
		OUTPUT_WIDTH						: integer := 12; 
		BUFFER_WIDTH						: integer := 16;
		COUNTER_WIDTH						: integer := 4;
		COUNTER_FINSH_VALUE				: integer := 15;
		MIC_SCLK_DOWNSAMPLE_WIDTH		: integer := 2);
	port (
		signal clock		: in std_logic;		-- Clock: 50 MHz
		signal reset		: in std_logic;		-- Reset: Synchronous
		signal mic_ncs		: out std_logic;		-- SPI: Chip Select
		signal mic_sdata 	: in std_logic;		-- SPI: Serial Out
		signal mic_sclk 	: out std_logic;		-- SPI: 12.5 MHz 
		signal output		: 							-- Output: Data
			out std_logic_vector((OUTPUT_WIDTH-1) downto 0) :=
			conv_std_logic_vector(0,OUTPUT_WIDTH); 
		signal enable		: in std_logic;		-- Handshake: Enable
		signal ready		: out std_logic 		-- Handshale: Ready
			:= '0');
end PmodMIC;

architecture Behavioral of PmodMIC is

	component DownSample 
		generic (	
			WIDTH				: integer);
		port (		
			clock				: in std_logic;		
			reset				: in std_logic;
			output			: out std_logic);
	end component;
	
	component ResetModule
		port(
			clock 					: in std_logic;
			reset 					: in std_logic;
			enable 					: in std_logic;          
			ready 					: out std_logic;
			reset_modules 			: out std_logic;
			reset_down_samplers 	: out std_logic);
	end component;

	signal data_buffer 	: std_logic_vector((BUFFER_WIDTH-1) downto 0) :=
		conv_std_logic_vector(0,BUFFER_WIDTH);
	signal counter			: std_logic_vector((COUNTER_WIDTH-1) downto 0) :=
		conv_std_logic_vector(0,COUNTER_WIDTH);
	signal mic_ncs_buff	: std_logic := '1';
	signal mic_sclk_buff	: std_logic;
	signal reset_down_samplers	: std_logic;
	signal reset_modules			: std_logic;
	signal reset_ready			: std_logic;

	type state_type is (S_ENABLE,S_LOAD_DATA,S_SET_OUTPUT,S_READY);
	signal state			: state_type := S_ENABLE;

begin

	mic_ncs <= mic_ncs_buff;
	mic_sclk <= mic_sclk_buff;
	
	-- Reset Module
	ResetModule_0 : ResetModule 
		port map(
			clock => clock,
			reset => '0',
			enable => reset,
			ready => reset_ready,
			reset_modules => reset_modules,
			reset_down_samplers => reset_down_samplers);

	-- Down Sampler For 12.5 MHz Clock (based on default generics)
	DownSample_0 : DownSample
		generic 	map (
			WIDTH => MIC_SCLK_DOWNSAMPLE_WIDTH)
		port map (
			clock => clock,
			reset => reset_down_samplers,
			output => mic_sclk_buff);

	-- Sample Data Behavioral Block
	process (mic_sclk_buff) 
	begin
		if (rising_edge(mic_sclk_buff)) then
			if (reset_modules='1') then
				data_buffer <=  (others => '0');
				counter <= (others => '0');
				output <= (others => '0');
				mic_ncs_buff <= '1';
				ready <= '0';
				state <= S_ENABLE;
			else
				case state is
					when S_ENABLE =>
						ready <= '0';
						if (enable='1') then 
							mic_ncs_buff <= '0';
							state <= S_LOAD_DATA;
						end if;
					when S_LOAD_DATA =>
						data_buffer(data_buffer'high downto data_buffer'low+1) <= 
							data_buffer(data_buffer'high-1 downto data_buffer'low);
						data_buffer(0) <= mic_sdata;
						counter <= counter+1;
						if (counter=COUNTER_FINSH_VALUE) then
							mic_ncs_buff <= '1';
							state <= S_SET_OUTPUT;
						end if;
					when S_SET_OUTPUT =>
						output <= data_buffer(output'high downto output'low);
						state <= S_READY;
					when S_READY =>
						ready <= '1';
						if (enable='0') then
							state <= S_ENABLE;
						end if;
					when others =>
						state <= S_ENABLE;
				end case;
			end if;
		end if;
	end process;

end Behavioral;

