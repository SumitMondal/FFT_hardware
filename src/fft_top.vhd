
--Engineer     : 
--Date         : 
--Name of file : fft_top.vhd
--Description  : implements 8-point FFT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fft_pkg.all;

entity fft_top is
  port (
        -- input side
        clk, rst      : in std_logic;
        data_in       : in data_in_t;
        in_valid      : in std_logic;
        next_in       : out std_logic;
        -- output side
        out_valid     : out std_logic;
        data_real_out : out data_out_t;
        data_imag_out : out data_out_t
       );
end fft_top;
-- DO NOT MODIFY PORT NAMES ABOVE

architecture arch of fft_top is
type twid		is array (0 to 3) of signed (8 downto 0);
type zbfly_1_complex	is array (0 to 1) of signed (8 downto 0); --first bit real second bit imag
type zbfly_2_complex    is array (0 to 1) of signed (18 downto 0); -- because these are being multiplied by twiddle they need to be bigger
type zbfly_3_fin	is array (0 to 1) of signed (10 downto 0);
type fbfly_1		is array (0 to 1) of signed (11 downto 0);
type fbfly_3		is array (0 to 1) of signed (21 downto 0);
type fbfly_fin		is array (0 to 1) of signed (13 downto 0);
type sbfly_1		is array (0 to 1) of signed (14 downto 0);
type sbfly_fin		is array (0 to 1) of signed (15 downto 0);


signal twid_real : twid;
signal twid_imag : twid;

signal stall_1 : std_logic;
signal stall_2 : std_logic;
signal stall_3 : std_logic;
signal stall_4 : std_logic;

signal valid_reg_1 : std_logic;
signal valid_reg_2 : std_logic;
signal valid_reg_3 : std_logic;
signal valid_reg_4 : std_logic;
signal valid_reg_5 : std_logic;
signal valid_reg_6 : std_logic;
signal valid_reg_7 : std_logic;
signal valid_reg_8 : std_logic;
signal valid_reg_9 : std_logic;
signal valid_reg_10 : std_logic;
signal valid_reg_11 : std_logic;

signal in0_reg : signed(7 downto 0);
signal in1_reg : signed(7 downto 0);
signal in2_reg : signed(7 downto 0);
signal in3_reg : signed(7 downto 0);
signal in4_reg : signed(7 downto 0);
signal in5_reg : signed(7 downto 0);
signal in6_reg : signed(7 downto 0);
signal in7_reg : signed(7 downto 0);

signal zbfly_1_04_x : zbfly_1_complex; --first bit real second bit imag
signal zbfly_1_26_x : zbfly_1_complex;  -- these are the first butterfly (aka 0bfly)
signal zbfly_1_15_x : zbfly_1_complex;  -- the first _1 is saying this is stage 1 of the butterfly
signal zbfly_1_37_x : zbfly_1_complex;  -- the _xx is which data ins are being done
signal zbfly_1_04_y : zbfly_1_complex; -- the final _x or _y is saying which of the two outputs..
signal zbfly_1_26_y : zbfly_1_complex; -- x being the one not being multiplied by the twiddle ..
signal zbfly_1_15_y : zbfly_1_complex;
signal zbfly_1_37_y : zbfly_1_complex;

signal zbfly_2_04_x : zbfly_1_complex;  -- reg these inputs because no complex mult ont hem we'll shift later
signal zbfly_2_26_x : zbfly_1_complex;  --
signal zbfly_2_15_x : zbfly_1_complex;  -- 
signal zbfly_2_37_x : zbfly_1_complex;  -- 
signal zbfly_2_04_y : zbfly_2_complex;  -- get these by multiplying stage 1 bfly by the twiddles complex
signal zbfly_2_26_y : zbfly_2_complex;  --
signal zbfly_2_15_y : zbfly_2_complex;  -- 
signal zbfly_2_37_y : zbfly_2_complex;  -- 

signal zbfly_3_04_x : zbfly_3_fin; 	-- we gon shift our shit
signal zbfly_3_26_x : zbfly_3_fin; 
signal zbfly_3_15_x : zbfly_3_fin; 
signal zbfly_3_37_x : zbfly_3_fin; 
signal zbfly_3_04_y : zbfly_3_fin; 
signal zbfly_3_26_y : zbfly_3_fin; 
signal zbfly_3_15_y : zbfly_3_fin; 
signal zbfly_3_37_y : zbfly_3_fin; 

signal fbfly_1_0426_xx : fbfly_1;	-- this is the start of stage 1 butterfly declarations
signal fbfly_1_1537_xx : fbfly_1;	-- fbfly means stage 1 'first' butterfly
signal fbfly_1_0426_yx : fbfly_1; 	-- the numbers means the summation of which previous summations
signal fbfly_1_1537_yx : fbfly_1;	-- the prior letter means where the inputs came from, the latter letter means where they go
signal fbfly_1_0426_xy : fbfly_1;	-- x meaning that the sum was just a sum
signal fbfly_1_1537_xy : fbfly_1;	-- y means it was a subtract * twiddle ..
signal fbfly_1_0426_yy : fbfly_1;
signal fbfly_1_1537_yy : fbfly_1;

signal fbfly_2_0426_xx : fbfly_1;	-- stage 2 and 3 is multipling the twiddle for the y's and regging the x's..
signal fbfly_2_1537_xx : fbfly_1;	
signal fbfly_2_0426_yx : fbfly_1; 	
signal fbfly_2_1537_yx : fbfly_1;	

signal fbfly_2_0426_xy_r1 : signed(20 downto 0);
signal fbfly_2_0426_xy_r2 : signed(20 downto 0);
signal fbfly_2_0426_xy_i1 : signed(20 downto 0);
signal fbfly_2_0426_xy_i2 : signed(20 downto 0);

signal fbfly_2_1537_xy_r1 : signed(20 downto 0);
signal fbfly_2_1537_xy_r2 : signed(20 downto 0);
signal fbfly_2_1537_xy_i1 : signed(20 downto 0);
signal fbfly_2_1537_xy_i2 : signed(20 downto 0);

signal fbfly_2_0426_yy_r1 : signed(20 downto 0);
signal fbfly_2_0426_yy_r2 : signed(20 downto 0);
signal fbfly_2_0426_yy_i1 : signed(20 downto 0);
signal fbfly_2_0426_yy_i2 : signed(20 downto 0);

signal fbfly_2_1537_yy_r1 : signed(20 downto 0);
signal fbfly_2_1537_yy_r2 : signed(20 downto 0);
signal fbfly_2_1537_yy_i1 : signed(20 downto 0);
signal fbfly_2_1537_yy_i2 : signed(20 downto 0);

signal fbfly_3_0426_xx : fbfly_1;	-- stage 2 and 3 is multipling the twiddle for the y's and regging the x's..
signal fbfly_3_1537_xx : fbfly_1;	
signal fbfly_3_0426_yx : fbfly_1; 	
signal fbfly_3_1537_yx : fbfly_1;

signal fbfly_3_0426_xy : fbfly_3;	-- add/sub products to make final complex prod..
signal fbfly_3_1537_xy : fbfly_3;	
signal fbfly_3_0426_yy : fbfly_3; 	
signal fbfly_3_1537_yy : fbfly_3;		


signal fbfly_4_0426_xx0 : fbfly_fin;	-- final thing is to shift the y's and sign extend the x's
signal fbfly_4_1537_xx4 : fbfly_fin;	-- fbfly means stage 1 'first' butterfly (of 3 aka 0 1 and 2)
signal fbfly_4_0426_yx1 : fbfly_fin; 	-- 
signal fbfly_4_1537_yx5 : fbfly_fin;	-- 
signal fbfly_4_0426_xy2 : fbfly_fin;	-- 
signal fbfly_4_1537_xy6 : fbfly_fin;	--
signal fbfly_4_0426_yy3 : fbfly_fin;
signal fbfly_4_1537_yy7 : fbfly_fin;

signal sbfly_1_04_x : sbfly_1;
signal sbfly_1_04_y : sbfly_1;
signal sbfly_1_26_x : sbfly_1;
signal sbfly_1_26_y : sbfly_1;
signal sbfly_1_15_x : sbfly_1;
signal sbfly_1_15_y : sbfly_1;
signal sbfly_1_37_x : sbfly_1;
signal sbfly_1_37_y : sbfly_1;

signal sbfly_04x_reg : sbfly_1;
signal sbfly_26x_reg : sbfly_1;
signal sbfly_15x_reg : sbfly_1;
signal sbfly_37x_reg : sbfly_1;

signal sbfly_2_04y_r1 : signed(23 downto 0);

signal sbfly_2_04y_i2 : signed(23 downto 0);

signal sbfly_2_15y_r1 : signed(23 downto 0);

signal sbfly_2_15y_i2 : signed(23 downto 0);

signal sbfly_2_26y_r1 : signed(23 downto 0);

signal sbfly_2_26y_i2 : signed(23 downto 0);

signal sbfly_2_37y_r1 : signed(23 downto 0);

signal sbfly_2_37y_i2 : signed(23 downto 0);

signal sbflyf_04x : sbfly_fin;
signal sbflyf_04y : sbfly_fin;
signal sbflyf_26x : sbfly_fin;
signal sbflyf_26y : sbfly_fin;
signal sbflyf_15x : sbfly_fin;
signal sbflyf_15y : sbfly_fin;
signal sbflyf_37x : sbfly_fin;
signal sbflyf_37y : sbfly_fin;


begin

twid_real(0) <= "011111111";
twid_imag(0) <= "000000000";
twid_real(1) <= "010110100";
twid_imag(1) <= "101001100";
twid_real(2) <= "000000000";
twid_imag(2) <= "100000001";
twid_real(3) <= "101001100";
twid_imag(3) <= "101001100";


next_in <= '1'; -- not (stall_1 and in_valid);

reg: process(clk)
begin
if rising_edge(clk) then
 if rst = '1' then
 valid_reg_1 <= '0';
 else --if stall_1 = '0' then
 valid_reg_1 <= in_valid;
 if in_valid = '1' then
 in0_reg <= data_in(0);
 in1_reg <= data_in(1);
 in2_reg <= data_in(2);
 in3_reg <= data_in(3);
 in4_reg <= data_in(4);
 in5_reg <= data_in(5);
 in6_reg <= data_in(6);
 in7_reg <= data_in(7);
 end if;
 end if;
end if;
end process;

stall_1 <= stall_2 and valid_reg_1;

zerothbutterfly_stage1 : process(clk)
begin
if rising_edge(clk) then
 if rst = '1' then
 valid_reg_2 <= '0';
 else --if stall_2 = '0' then
 valid_reg_2 <= valid_reg_1;
 if valid_reg_1 = '1' then
 zbfly_1_04_x(0) <= (in0_reg(7) & in0_reg) + (in4_reg(7) & in4_reg);  -- adding before multiply(but not really) in the butterfuly stage 1
 zbfly_1_04_x(1) <= (others => '0');
 zbfly_1_26_x(0) <= (in2_reg(7) & in2_reg) + (in6_reg(7) & in6_reg); 
 zbfly_1_26_x(1) <= (others => '0');
 zbfly_1_15_x(0) <= (in1_reg(7) & in1_reg) + (in5_reg(7) & in5_reg);  
 zbfly_1_15_x(1) <= (others => '0');
 zbfly_1_37_x(0) <= (in3_reg(7) & in3_reg) + (in7_reg(7) & in7_reg); 
 zbfly_1_37_x(1) <= (others => '0');
 
 zbfly_1_04_y(0) <= (in0_reg(7) & in0_reg) - (in4_reg(7) & in4_reg);     -- subtracting before mutliply with twiddle in the butterfly stage 1
 zbfly_1_04_y(1) <= (others => '0');
 zbfly_1_26_y(0) <= (in2_reg(7) & in2_reg) - (in6_reg(7) & in6_reg);  
 zbfly_1_26_y(1) <= (others => '0');
 zbfly_1_15_y(0) <= (in1_reg(7) & in1_reg) - (in5_reg(7) & in5_reg);  
 zbfly_1_15_y(1) <= (others => '0');
 zbfly_1_37_y(0) <= (in3_reg(7) & in3_reg) - (in7_reg(7) & in7_reg);  
 zbfly_1_37_y(1) <= (others => '0');
 end if;
end if;
end if;
end process;

stall_2 <= stall_3 and valid_reg_2;

zblfy_2 : process(clk)     -- so this stage is registering the x inputs and doing multiplication on the y inputs
begin
if rising_edge(clk) then
 if rst = '1' then 
 valid_reg_3 <= '0';
 else --if stall_3 = '0' then
 valid_reg_3 <= valid_reg_2;
 if valid_reg_2 = '1' then
 zbfly_2_04_x <= zbfly_1_04_x; -- just regging some shite
 zbfly_2_26_x <= zbfly_1_26_x;
 zbfly_2_15_x <= zbfly_1_15_x;
 zbfly_2_37_x <= zbfly_1_37_x;

 zbfly_2_04_y(0) <= (zbfly_1_04_y(0)(8) & zbfly_1_04_y(0)) * twid_real(0);
 zbfly_2_04_y(1) <= (zbfly_1_04_y(0)(8) & zbfly_1_04_y(0)) * twid_imag(0);
 zbfly_2_26_y(0) <= (zbfly_1_26_y(0)(8) & zbfly_1_26_y(0)) * twid_real(2);
 zbfly_2_26_y(1) <= (zbfly_1_26_y(0)(8) & zbfly_1_26_y(0)) * twid_imag(2);
 zbfly_2_15_y(0) <= (zbfly_1_15_y(0)(8) & zbfly_1_15_y(0)) * twid_real(1);
 zbfly_2_15_y(1) <= (zbfly_1_15_y(0)(8) & zbfly_1_15_y(0)) * twid_imag(1);
 zbfly_2_37_y(0) <= (zbfly_1_37_y(0)(8) & zbfly_1_37_y(0)) * twid_real(3);
 zbfly_2_37_y(1) <= (zbfly_1_37_y(0)(8) & zbfly_1_37_y(0)) * twid_imag(3);
 end if;
end if;
end if;
end process;

stall_3 <= stall_4 and valid_reg_3;

zbfly_3 : process(clk)
begin
if rising_edge(clk) then
 if rst = '1' then
 valid_reg_4 <= '0';
 else --if stall_4 = '0' then
 valid_reg_4 <= valid_reg_3;
 if valid_reg_3 = '1' then
  zbfly_3_04_x(0) <= zbfly_2_04_x(0)(8) & zbfly_2_04_x(0)(8) & zbfly_2_04_x(0);   -- sign extend all the x's
  zbfly_3_04_x(1) <= zbfly_2_04_x(1)(8) & zbfly_2_04_x(1)(8) & zbfly_2_04_x(1);  
  zbfly_3_26_x(0) <= zbfly_2_26_x(0)(8) & zbfly_2_26_x(0)(8) & zbfly_2_26_x(0);  
  zbfly_3_26_x(1) <= zbfly_2_26_x(1)(8) & zbfly_2_26_x(1)(8) & zbfly_2_26_x(1);  
  zbfly_3_15_x(0) <= zbfly_2_15_x(0)(8) & zbfly_2_15_x(0)(8) & zbfly_2_15_x(0);  
  zbfly_3_15_x(1) <= zbfly_2_15_x(1)(8) & zbfly_2_15_x(1)(8) & zbfly_2_15_x(1);  
  zbfly_3_37_x(0) <= zbfly_2_37_x(0)(8) & zbfly_2_37_x(0)(8) & zbfly_2_37_x(0);  
  zbfly_3_37_x(1) <= zbfly_2_37_x(1)(8) & zbfly_2_37_x(1)(8) & zbfly_2_37_x(1);  

  zbfly_3_04_y(0) <= zbfly_2_04_y(0)(18 downto 8);  -- right shift all the y's
  zbfly_3_04_y(1) <= zbfly_2_04_y(1)(18 downto 8);
  zbfly_3_26_y(0) <= zbfly_2_26_y(0)(18 downto 8);
  zbfly_3_26_y(1) <= zbfly_2_26_y(1)(18 downto 8);
  zbfly_3_15_y(0) <= zbfly_2_15_y(0)(18 downto 8);
  zbfly_3_15_y(1) <= zbfly_2_15_y(1)(18 downto 8);
  zbfly_3_37_y(0) <= zbfly_2_37_y(0)(18 downto 8);
  zbfly_3_37_y(1) <= zbfly_2_37_y(1)(18 downto 8);
 end if;
end if;
end if;
end process;

fblfy_1_addsub : process(clk)
begin
if rising_edge(clk) then
 if rst = '1' then
 valid_reg_5 <= '0';
 else
 valid_reg_5 <= valid_reg_4;
 if valid_reg_4 = '1' then
 fbfly_1_0426_xx(0) <= (zbfly_3_04_x(0)(10) & zbfly_3_04_x(0)) + (zbfly_3_26_x(0)(10) & zbfly_3_26_x(0));
 fbfly_1_0426_xx(1) <= (zbfly_3_04_x(1)(10) & zbfly_3_04_x(1)) + (zbfly_3_26_x(1)(10) & zbfly_3_26_x(1));
 fbfly_1_1537_xx(0) <= (zbfly_3_15_x(0)(10) & zbfly_3_15_x(0)) + (zbfly_3_37_x(0)(10) & zbfly_3_37_x(0));
 fbfly_1_1537_xx(1) <= (zbfly_3_15_x(1)(10) & zbfly_3_15_x(1)) + (zbfly_3_37_x(1)(10) & zbfly_3_37_x(1)); 
 fbfly_1_0426_yx(0) <= (zbfly_3_04_y(0)(10) & zbfly_3_04_y(0)) + (zbfly_3_26_y(0)(10) & zbfly_3_26_y(0));
 fbfly_1_0426_yx(1) <= (zbfly_3_04_y(1)(10) & zbfly_3_04_y(1)) + (zbfly_3_26_y(1)(10) & zbfly_3_26_y(1));
 fbfly_1_1537_yx(0) <= (zbfly_3_15_y(0)(10) & zbfly_3_15_y(0)) + (zbfly_3_37_y(0)(10) & zbfly_3_37_y(0));
 fbfly_1_1537_yx(1) <= (zbfly_3_15_y(1)(10) & zbfly_3_15_y(1)) + (zbfly_3_37_y(1)(10) & zbfly_3_37_y(1));
 
 fbfly_1_0426_xy(0) <= (zbfly_3_04_x(0)(10) & zbfly_3_04_x(0)) - (zbfly_3_26_x(0)(10) & zbfly_3_26_x(0));
 fbfly_1_0426_xy(1) <= (zbfly_3_04_x(1)(10) & zbfly_3_04_x(1)) - (zbfly_3_26_x(1)(10) & zbfly_3_26_x(1));
 fbfly_1_1537_xy(0) <= (zbfly_3_15_x(0)(10) & zbfly_3_15_x(0)) - (zbfly_3_37_x(0)(10) & zbfly_3_37_x(0));
 fbfly_1_1537_xy(1) <= (zbfly_3_15_x(1)(10) & zbfly_3_15_x(1)) - (zbfly_3_37_x(1)(10) & zbfly_3_37_x(1)); 
 fbfly_1_0426_yy(0) <= (zbfly_3_04_y(0)(10) & zbfly_3_04_y(0)) - (zbfly_3_26_y(0)(10) & zbfly_3_26_y(0));
 fbfly_1_0426_yy(1) <= (zbfly_3_04_y(1)(10) & zbfly_3_04_y(1)) - (zbfly_3_26_y(1)(10) & zbfly_3_26_y(1));
 fbfly_1_1537_yy(0) <= (zbfly_3_15_y(0)(10) & zbfly_3_15_y(0)) - (zbfly_3_37_y(0)(10) & zbfly_3_37_y(0));
 fbfly_1_1537_yy(1) <= (zbfly_3_15_y(1)(10) & zbfly_3_15_y(1)) - (zbfly_3_37_y(1)(10) & zbfly_3_37_y(1));
 end if;
end if;
end if;
end process;
 
 
fbfly_2 : process(clk)
begin
if rising_edge(clk) then
 if rst = '1' then
 valid_reg_6 <= '0';
 else
 valid_reg_6 <= valid_reg_5;
 if valid_reg_5 = '1' then
 fbfly_2_0426_xx <= fbfly_1_0426_xx;			-- regging some stuff
 fbfly_2_1537_xx <= fbfly_1_1537_xx;
 fbfly_2_0426_yx <= fbfly_1_0426_yx;
 fbfly_2_1537_yx <= fbfly_1_1537_yx;

 fbfly_2_0426_xy_r1 <= fbfly_1_0426_xy(0) * twid_real(0);  -- getting complex products to add for final complex product ..
 fbfly_2_0426_xy_r2 <= fbfly_1_0426_xy(1) * twid_imag(0);
 fbfly_2_0426_xy_i1 <= fbfly_1_0426_xy(0) * twid_imag(0);
 fbfly_2_0426_xy_i2 <= fbfly_1_0426_xy(1) * twid_real(0);

 fbfly_2_1537_xy_r1 <= fbfly_1_1537_xy(0) * twid_real(2); 
 fbfly_2_1537_xy_r2 <= fbfly_1_1537_xy(1) * twid_imag(2);
 fbfly_2_1537_xy_i1 <= fbfly_1_1537_xy(0) * twid_imag(2);
 fbfly_2_1537_xy_i2 <= fbfly_1_1537_xy(1) * twid_real(2);

 fbfly_2_0426_yy_r1 <= fbfly_1_0426_yy(0) * twid_real(0);  
 fbfly_2_0426_yy_r2 <= fbfly_1_0426_yy(1) * twid_imag(0);
 fbfly_2_0426_yy_i1 <= fbfly_1_0426_yy(0) * twid_imag(0);
 fbfly_2_0426_yy_i2 <= fbfly_1_0426_yy(1) * twid_real(0);
 
 fbfly_2_1537_yy_r1 <= fbfly_1_1537_yy(0) * twid_real(2);  
 fbfly_2_1537_yy_r2 <= fbfly_1_1537_yy(1) * twid_imag(2);
 fbfly_2_1537_yy_i1 <= fbfly_1_1537_yy(0) * twid_imag(2);
 fbfly_2_1537_yy_i2 <= fbfly_1_1537_yy(1) * twid_real(2);
 end if;
 end if;
end if;
end process;

fbfly_3_finalcomplexmult : process(clk)
begin
if rising_edge(clk) then
 if rst = '1' then
 valid_reg_7 <= '0';
 else
 valid_reg_7 <= valid_reg_6;
 if valid_reg_6 = '1' then
 fbfly_3_0426_xx <= fbfly_2_0426_xx;			-- regging some stuff
 fbfly_3_1537_xx <= fbfly_2_1537_xx;
 fbfly_3_0426_yx <= fbfly_2_0426_yx;
 fbfly_3_1537_yx <= fbfly_2_1537_yx;

 fbfly_3_0426_xy(0) <= (fbfly_2_0426_xy_r1(20) & fbfly_2_0426_xy_r1) - (fbfly_2_0426_xy_r2(20) & fbfly_2_0426_xy_r2); 
 fbfly_3_0426_xy(1) <= (fbfly_2_0426_xy_i1(20) & fbfly_2_0426_xy_i1) + (fbfly_2_0426_xy_i2(20) & fbfly_2_0426_xy_i2);  

 fbfly_3_1537_xy(0) <= (fbfly_2_1537_xy_r1(20) & fbfly_2_1537_xy_r1) - (fbfly_2_1537_xy_r2(20) & fbfly_2_1537_xy_r2); 
 fbfly_3_1537_xy(1) <= (fbfly_2_1537_xy_i1(20) & fbfly_2_1537_xy_i1) + (fbfly_2_1537_xy_i2(20) & fbfly_2_1537_xy_i2);

 fbfly_3_0426_yy(0) <= (fbfly_2_0426_yy_r1(20) & fbfly_2_0426_yy_r1) - (fbfly_2_0426_yy_r2(20) & fbfly_2_0426_yy_r2);  
 fbfly_3_0426_yy(1) <= (fbfly_2_0426_yy_i1(20) & fbfly_2_0426_yy_i1) + (fbfly_2_0426_yy_i2(20) & fbfly_2_0426_yy_i2); 
 
 fbfly_3_1537_yy(0) <= (fbfly_2_1537_yy_r1(20) & fbfly_2_1537_yy_r1) - (fbfly_2_1537_yy_r2(20) & fbfly_2_1537_yy_r2);  
 fbfly_3_1537_yy(1) <= (fbfly_2_1537_yy_i1(20) & fbfly_2_1537_yy_i1) + (fbfly_2_1537_yy_i2(20) & fbfly_2_1537_yy_i2);
 end if;
end if;
end if;
end process;

fbfly_4_final : process(clk)
begin
if rising_edge(clk) then
 if rst = '1' then
 valid_reg_8 <= '0';
 else
 valid_reg_8 <= valid_reg_7;
 if valid_reg_7 = '1' then
 fbfly_4_0426_xx0(0) <= resize(fbfly_3_0426_xx(0),14);
 fbfly_4_0426_xx0(1) <= resize(fbfly_3_0426_xx(1),14);
 fbfly_4_1537_xx4(0) <= resize(fbfly_3_1537_xx(0),14);
 fbfly_4_1537_xx4(1) <= resize(fbfly_3_1537_xx(1),14);
 fbfly_4_0426_yx1(0) <= resize(fbfly_3_0426_yx(0),14);
 fbfly_4_0426_yx1(1) <= resize(fbfly_3_0426_yx(1),14);
 fbfly_4_1537_yx5(0) <= resize(fbfly_3_1537_yx(0),14);
 fbfly_4_1537_yx5(1) <= resize(fbfly_3_1537_yx(1),14);


 fbfly_4_0426_xy2(0) <= fbfly_3_0426_xy(0)(21 downto 8);
 fbfly_4_0426_xy2(1) <= fbfly_3_0426_xy(1)(21 downto 8);
 fbfly_4_1537_xy6(0) <= fbfly_3_1537_xy(0)(21 downto 8);
 fbfly_4_1537_xy6(1) <= fbfly_3_1537_xy(1)(21 downto 8);
 fbfly_4_0426_yy3(0) <= fbfly_3_0426_yy(0)(21 downto 8);
 fbfly_4_0426_yy3(1) <= fbfly_3_0426_yy(1)(21 downto 8);
 fbfly_4_1537_yy7(0) <= fbfly_3_1537_yy(0)(21 downto 8);
 fbfly_4_1537_yy7(1) <= fbfly_3_1537_yy(1)(21 downto 8);
end if;
end if;
end if;
end process;

sbfly_1_addsub : process(clk)
begin
if rising_edge(clk) then
 if rst = '1' then
 valid_reg_9 <= '0';
 else
 valid_reg_9 <= valid_reg_8;
 if valid_reg_8 = '1' then
 sbfly_1_04_x(0) <= (fbfly_4_0426_xx0(0)(13) & fbfly_4_0426_xx0(0)) + (fbfly_4_1537_xx4(0)(13) & fbfly_4_1537_xx4(0));
 sbfly_1_04_x(1) <= (fbfly_4_0426_xx0(1)(13) & fbfly_4_0426_xx0(1)) + (fbfly_4_1537_xx4(1)(13) & fbfly_4_1537_xx4(1));
 
 sbfly_1_04_y(0) <= (fbfly_4_0426_xx0(0)(13) & fbfly_4_0426_xx0(0)) - (fbfly_4_1537_xx4(0)(13) & fbfly_4_1537_xx4(0));
 sbfly_1_04_y(1) <= (fbfly_4_0426_xx0(1)(13) & fbfly_4_0426_xx0(1)) - (fbfly_4_1537_xx4(1)(13) & fbfly_4_1537_xx4(1));

 sbfly_1_26_x(0) <= (fbfly_4_0426_xy2(0)(13) & fbfly_4_0426_xy2(0)) + (fbfly_4_1537_xy6(0)(13) & fbfly_4_1537_xy6(0));
 sbfly_1_26_x(1) <= (fbfly_4_0426_xy2(1)(13) & fbfly_4_0426_xy2(1)) + (fbfly_4_1537_xy6(1)(13) & fbfly_4_1537_xy6(1));

 sbfly_1_26_y(0) <= (fbfly_4_0426_xy2(0)(13) & fbfly_4_0426_xy2(0)) - (fbfly_4_1537_xy6(0)(13) & fbfly_4_1537_xy6(0));
 sbfly_1_26_y(1) <= (fbfly_4_0426_xy2(1)(13) & fbfly_4_0426_xy2(1)) - (fbfly_4_1537_xy6(1)(13) & fbfly_4_1537_xy6(1));

 
 sbfly_1_15_x(0) <= (fbfly_4_0426_yx1(0)(13) & fbfly_4_0426_yx1(0)) + (fbfly_4_1537_yx5(0)(13) & fbfly_4_1537_yx5(0));
 sbfly_1_15_x(1) <= (fbfly_4_0426_yx1(1)(13) & fbfly_4_0426_yx1(1)) + (fbfly_4_1537_yx5(1)(13) & fbfly_4_1537_yx5(1));

 sbfly_1_15_y(0) <= (fbfly_4_0426_yx1(0)(13) & fbfly_4_0426_yx1(0)) - (fbfly_4_1537_yx5(0)(13) & fbfly_4_1537_yx5(0));
 sbfly_1_15_y(1) <= (fbfly_4_0426_yx1(1)(13) & fbfly_4_0426_yx1(1)) - (fbfly_4_1537_yx5(1)(13) & fbfly_4_1537_yx5(1));
 

 sbfly_1_37_x(0) <= (fbfly_4_0426_yy3(0)(13) & fbfly_4_0426_yy3(0)) + (fbfly_4_1537_yy7(0)(13) & fbfly_4_1537_yy7(0));
 sbfly_1_37_x(1) <= (fbfly_4_0426_yy3(1)(13) & fbfly_4_0426_yy3(1)) + (fbfly_4_1537_yy7(1)(13) & fbfly_4_1537_yy7(1));

 sbfly_1_37_y(0) <= (fbfly_4_0426_yy3(0)(13) & fbfly_4_0426_yy3(0)) - (fbfly_4_1537_yy7(0)(13) & fbfly_4_1537_yy7(0));
 sbfly_1_37_y(1) <= (fbfly_4_0426_yy3(1)(13) & fbfly_4_0426_yy3(1)) - (fbfly_4_1537_yy7(1)(13) & fbfly_4_1537_yy7(1));
 end if;
end if;
end if;
end process;

sbfly2_complexmult1 : process(clk)
begin
if rising_edge(clk) then
 if rst = '1' then
 valid_reg_10 <= '0';
 else
 valid_reg_10 <= valid_reg_9;
 if valid_reg_9 = '1' then
sbfly_04x_reg <= sbfly_1_04_x;
sbfly_26x_reg <= sbfly_1_26_x;
sbfly_15x_reg <= sbfly_1_15_x;
sbfly_37x_reg <= sbfly_1_37_x;

sbfly_2_04y_r1 <= sbfly_1_04_y(0) * twid_real(0);

sbfly_2_04y_i2 <= sbfly_1_04_y(1) * twid_real(0);

sbfly_2_15y_r1 <= sbfly_1_15_y(0) * twid_real(0);

sbfly_2_15y_i2 <= sbfly_1_15_y(1) * twid_real(0);

sbfly_2_26y_r1 <= sbfly_1_26_y(0) * twid_real(0);

sbfly_2_26y_i2 <= sbfly_1_26_y(1) * twid_real(0);

sbfly_2_37y_r1 <= sbfly_1_37_y(0) * twid_real(0);

sbfly_2_37y_i2 <= sbfly_1_37_y(1) * twid_real(0);

end if;
end if;
end if;
end process;

final : process(clk)
begin
if rising_edge(clk) then
 if rst = '1' then
 valid_reg_11 <= '0';
 else
 valid_reg_11 <= valid_reg_10;
 if valid_reg_10 = '1' then
 sbflyf_04x(0) <= resize(sbfly_04x_reg(0),16);
 sbflyf_04x(1) <= resize(sbfly_04x_reg(1),16);
 sbflyf_26x(0) <= resize(sbfly_26x_reg(0),16);
 sbflyf_26x(1) <= resize(sbfly_26x_reg(1),16);
 sbflyf_15x(0) <= resize(sbfly_15x_reg(0),16);
 sbflyf_15x(1) <= resize(sbfly_15x_reg(1),16);
 sbflyf_37x(0) <= resize(sbfly_37x_reg(0),16);
 sbflyf_37x(1) <= resize(sbfly_37x_reg(1),16);

 sbflyf_04y(0) <= sbfly_2_04y_r1(23 downto 8);
 sbflyf_04y(1) <= sbfly_2_04y_i2(23 downto 8);

 sbflyf_15y(0) <= sbfly_2_15y_r1(23 downto 8);
 sbflyf_15y(1) <= sbfly_2_15y_i2(23 downto 8);

 sbflyf_26y(0) <= sbfly_2_26y_r1(23 downto 8);
 sbflyf_26y(1) <= sbfly_2_26y_i2(23 downto 8);

 sbflyf_37y(0) <= sbfly_2_37y_r1(23 downto 8);
 sbflyf_37y(1) <= sbfly_2_37y_i2(23 downto 8);
 end if;
 end if;
 end if;
end process;


out_valid <= valid_reg_11;

data_real_out(0) <= sbflyf_04x(0);
data_real_out(1) <= sbflyf_15x(0);
data_real_out(2) <= sbflyf_26x(0);
data_real_out(3) <= sbflyf_37x(0);
data_real_out(4) <= sbflyf_04y(0);
data_real_out(5) <= sbflyf_15y(0);
data_real_out(6) <= sbflyf_26y(0);
data_real_out(7) <= sbflyf_37y(0); 

data_imag_out(0) <= sbflyf_04x(1);
data_imag_out(1) <= sbflyf_15x(1);
data_imag_out(2) <= sbflyf_26x(1);
data_imag_out(3) <= sbflyf_37x(1);
data_imag_out(4) <= sbflyf_04y(1);
data_imag_out(5) <= sbflyf_15y(1);
data_imag_out(6) <= sbflyf_26y(1);
data_imag_out(7) <= sbflyf_37y(1); 

next_in <= '1';


end arch;
