library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity fibonacci_counter is
  port (N : in std_logic_vector(4 downto 0);
        DC_IN, PB1, PB2, RESET, CLK : in std_logic;
		  SEVEN_SEG_DISPLAY : out std_logic_vector(41 downto 0));
end fibonacci_counter;



  

architecture sequential of fibonacci_counter is
  subtype digit is integer range 0 to 9;
  type array_of_digits is array(5 downto 0) of digit;
  type array_of_numbers is array(5 downto 0) of integer;
  type array_of_cnts is array(2 downto 0) of integer;
  signal divided_clk : std_logic := '0';
  signal fibonacci_count : integer := 1;
  signal prev_fibonacci_count : integer := 0;
  signal count : integer := 1;
  signal tmp : array_of_cnts := (0, 1, 1);
  signal digits: array_of_digits := (0, 0, 0, 0, 0, 1);
  signal ssd : std_logic_vector(41 downto 0) := "100000010000001000000100000010000001111001";
  signal max_count : std_logic_vector(4 downto 0) := "01010";
  signal pb_1, pb_2 : std_logic;
  
  function digit_to_hex_display ( number : digit )
    return std_logic_vector is
    variable hex_display_val : std_logic_vector(6 downto 0);
  begin
    case number is
	   when 0 => hex_display_val := "1000000";
		when 1 => hex_display_val := "1111001";
		when 2 => hex_display_val := "0100100";
		when 3 => hex_display_val := "0110000";
		when 4 => hex_display_val := "0011001";
		when 5 => hex_display_val := "0010010";
		when 6 => hex_display_val := "0000010";
		when 7 => hex_display_val := "1111000";
		when 8 => hex_display_val := "0000000";
		when 9 => hex_display_val := "0010000";	
	 end case;	
    return hex_display_val;
  end digit_to_hex_display;

  function get_digits ( number : integer )
    return array_of_digits is
    variable digits_of_num : array_of_digits;
    variable num           : integer;
	 --variable num           : string(1 to 6);
	 --variable tmp           : integer;
    variable divisors      : array_of_numbers := (100000, 10000, 1000, 100, 10, 1);
  begin
    --num := integer'image(number);
    num := number;
	 --for i in num'range loop
	 for i in 5 downto 0 loop
      --digits_of_num(i) := to_integer(to_unsigned(character'pos(num(i)), 8));
		digits_of_num(i) := num / divisors(i);
      num := num mod divisors(i);
    end loop; 
    return digits_of_num;
  end get_digits;

  function binary_to_decimal ( binary : std_logic_vector(4 downto 0))
    return integer is
    variable decimal : integer := 0;
  begin
    if ( binary(4) = '1' ) then
	    decimal := decimal + 16;
	 end if;
	 if ( binary(3) = '1') then
	    decimal := decimal + 8;
	 end if;
	 if ( binary(2) = '1') then
	    decimal := decimal + 4;
	 end if;
	 if ( binary(1) = '1') then
	    decimal := decimal + 2;
	 end if;
	 if ( binary(0) = '1') then
	    decimal := decimal + 1;
	 end if;
    --decimal :=  (16 and binary(4)) + (8 and binary(3)) + (4 and binary(2)) + (2 and binary(1)) + binary(0);
    return decimal;
  end binary_to_decimal;
  
  function get_next_fibcount(str : string; cur_cnt : integer; prev_cnt : integer; count: integer; N : std_logic_vector(4 downto 0))
    return array_of_cnts is
	 variable prev_curr: array_of_cnts;
  begin
    if ( (str = "asc" and count = binary_to_decimal(N)) or (str = "dsc" and count = 1)) then
	    prev_curr := (prev_cnt, cur_cnt, count);
    elsif ( str = "asc" ) then
	    if ( prev_cnt = 0 and cur_cnt = 1 ) then
		    prev_curr := (cur_cnt, 1, 2);
		 --elsif ( count = integer(N) ) then
		 --   prev_curr = (prev_cnt, cur_cnt, count);
		 else
		    prev_curr := (cur_cnt, cur_cnt + prev_cnt, count + 1);
		 end if;
	 else 
	    if ( prev_cnt = 1 and cur_cnt = 1 ) then
		    prev_curr := (0, prev_cnt, 1);
		 --elsif ( count = 1 ) then
		 --   prev_curr = (prev_cnt, cur_cnt, count);
		 else
		    prev_curr := (cur_cnt - prev_cnt, prev_cnt, count - 1);
		 end if;
	 end if;
	 return prev_curr;
  end get_next_fibcount;
  
begin
  clock_divider: process(CLK)
    variable clk_count: integer:=0;
  begin
    if (CLK'event and CLK='1') then
	    if clk_count = 12500000 then
		 --if clk_count = 2 then
		    divided_clk <= not divided_clk;
			 clk_count := 0;
		 else
		    clk_count := clk_count + 1;
		 end if;
	 end if;
  end process;
  
  fibonacci_counter: process(DC_IN, RESET, N, pb_1, pb_2, divided_clk)
    begin
	   if (RESET = '1') then
		   tmp <= (0, 1, 1);
			max_count <= N;
			 --SEVEN_SEG_DISPLAY <= "100000010000001000000100000010000001111001";
		else
	     if	(divided_clk'event and divided_clk = '1') then
		      if (DC_IN = '1' ) then
		         tmp <= get_next_fibcount("asc", fibonacci_count, prev_fibonacci_count, count, max_count); 
		      else   
				   if (pb_2 = '0') then
		            if (pb_1 = '1') then
		               tmp <= get_next_fibcount("asc", fibonacci_count, prev_fibonacci_count, count, max_count);
			         else
		               tmp <= get_next_fibcount("dsc", fibonacci_count, prev_fibonacci_count, count, max_count);
			         end if;
				   end if;
		      end if;	
		  end if;
		end if;

	 end process;
	 
  display: process(digits, divided_clk)
    begin
		for i in 5 downto 0 loop
		  ssd((7*i + 6) downto 7*i) <= digit_to_hex_display(digits(i));
		end loop;
    end process;
  
  digits <= get_digits(fibonacci_count);
  SEVEN_SEG_DISPLAY <= ssd;
  prev_fibonacci_count <= tmp(2);
  fibonacci_count <= tmp(1);
  count <= tmp(0);
  pb_1 <= PB1;
  pb_2 <= PB2;
end architecture sequential;
