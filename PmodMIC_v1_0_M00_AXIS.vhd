library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PmodMIC_v1_0_M00_AXIS is
	generic (
		C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
		MIC_OUTPUT_WIDTH		: integer   := 12);
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
end PmodMIC_v1_0_M00_AXIS;

architecture implementation of PmodMIC_v1_0_M00_AXIS is  
                
    signal M_AXIS_TVALID_BUFF   : std_logic := '0';  
    signal mic_enable_buff      : std_logic := '0';
    type state_type is (S_ENABLE,S_MIC,S_READY);  
    signal state : state_type := S_ENABLE;
    
begin

    M_AXIS_TSTRB <= (others => '1');     
    M_AXIS_TLAST <= '1';  
    M_AXIS_TVALID <= M_AXIS_TVALID_BUFF;   
    mic_enable <= mic_enable_buff;       
     
    process(M_AXIS_ACLK)                                                                        
    begin                                                                                       
        if (rising_edge (M_AXIS_ACLK)) then                                                       
            if(M_AXIS_ARESETN = '0') then       
                M_AXIS_TVALID_BUFF <= '0';    
            else
                if (M_AXIS_TVALID_BUFF='1' and M_AXIS_TREADY='1') then
                    M_AXIS_TVALID_BUFF <= '0';
                else
                    M_AXIS_TVALID_BUFF <= '1';
                end if;
            end if;
       end if;
    end process;
    
    process(M_AXIS_ACLK)                                                                        
    begin                                                                                       
        if (rising_edge (M_AXIS_ACLK)) then                                                       
            if(M_AXIS_ARESETN = '0') then       
                ready <= '0';        
                mic_enable_buff <= '0';    
                state <= S_ENABLE;                            
            else       
                case state is
                    when S_ENABLE =>
                        ready <= '0';
                        if (enable='1') then
                            state <= S_MIC;
                        end if;
                    when S_MIC =>
                        if (mic_enable_buff='1' and mic_ready='1') then
                            M_AXIS_TDATA(mic_output'high downto mic_output'low) <= mic_output;
                            mic_enable_buff <= '0';
                            state <= S_READY;
                        else
                            mic_enable_buff <= '1';
                        end if;
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
end implementation;
