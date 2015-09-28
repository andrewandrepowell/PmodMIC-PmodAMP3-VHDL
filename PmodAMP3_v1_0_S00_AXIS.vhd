library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PmodAMP3_v1_0_S00_AXIS is
    generic (
        C_S_AXIS_TDATA_WIDTH	: integer	:= 32;
        AMP_DATA_WIDTH          : integer   := 24);
    port (
        -- AXI4 Stream Interface
        S_AXIS_ACLK	    : in std_logic;
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
end PmodAMP3_v1_0_S00_AXIS;

architecture arch_imp of PmodAMP3_v1_0_S00_AXIS is
    signal data_buff            : std_logic_vector(AMP_DATA_WIDTH-1 downto 0);
    signal ch_buff              : std_logic;
    signal S_AXIS_TREADY_BUFF   : std_logic;
    signal amp_enable_buff      : std_logic;
    type state_type is (S_AXI,S_AMP);
    signal state : state_type := S_AXI;
begin
    data_buff <= S_AXIS_TDATA(data_buff'high downto data_buff'low);
    ch_buff <= S_AXIS_TDATA(data_buff'length);
    amp_enable <= amp_enable_buff;
    S_AXIS_TREADY <= S_AXIS_TREADY_BUFF;
    process (S_AXIS_ACLK)
    begin
        if (rising_edge(S_AXIS_ACLK)) then
            if (S_AXIS_ARESETN='0') then
                state <= S_AXI;
                S_AXIS_TREADY_BUFF <= '0';
                amp_data <= (others => '0');
                amp_ch <= '0';
                amp_enable_buff <= '0';
            else
                case state is
                    when S_AXI =>
                        if (S_AXIS_TVALID='1' and S_AXIS_TREADY_BUFF='1') then
                            S_AXIS_TREADY_BUFF <= '0';
                            amp_data <= data_buff;
                            amp_ch <= ch_buff;
                            state <= S_AMP;
                        else
                            S_AXIS_TREADY_BUFF <= '1';
                        end if;
                    when S_AMP =>
                        if (amp_enable_buff='1' and amp_ready='1') then
                            amp_enable_buff <= '0';
                            state <= S_AXI;
                        else
                            amp_enable_buff <= '1';
                        end if;
                    when others =>
                        state <= S_AXI;
                end case;
            end if;
        end if;
    end process;
end arch_imp;