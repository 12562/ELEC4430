library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;
use std.env.all;
	
entity fng_tb is
end entity;

architecture tb of fng_tb is
   -- Define the component to be intantiated as uut
	component fibonacci_counter is
		Port(
			CLK		         : in std_logic;
			PB1			      : in std_logic;
			PB2               : in std_logic;
			DC_IN             : in std_logic;
			N	             	: in std_logic_vector(4 downto 0);
         RESET             : in std_logic;

			SEVEN_SEG_DISPLAY : out std_logic_vector(41 downto 0)
		);
	End component;
	
	-- Declare various type's and subtype's for processing integers/digits
   type array_of_numbers is array(5 downto 0) of integer;
	type integer_vector is array(natural range<>) of integer;
	subtype digit is integer range 0 to 9;
   type array_of_digits is array(5 downto 0) of digit;
   type bitvector is array (8 downto 0) of bit;
	type vector is array(3 downto 0) of bitvector;
	type hexdispvector is array(5 downto 0) of bit_vector(6 downto 0);
	
	-- Delare test bench signals to be applied to the uut
	signal	clk    		: std_logic := '0';
   signal divided_clk    : std_logic := '0';
	signal   sw           : std_logic;
	signal   pb          : std_logic;
	signal   dc_in       : std_logic;
	signal   rst       : std_logic;
	signal	n  	      : std_logic_vector(4 downto 0);
	signal	ssd      	: std_logic_vector(41 downto 0);
	
	-- Delare the clock period
	constant period 				: time := 20 ns;
    
   -- Function for converting a std_logic_vector to a string    
   function to_string (arg : std_logic_vector) return string is
     variable result : string (1 to arg'length);
     variable v : std_logic_vector (result'range) := arg;
   begin
     for i in result'range loop
       case v(i) is
         when 'U' => result(i) := 'U';
         when 'X' => result(i) := 'X';
         when '0' => result(i) := '0';
         when '1' => result(i) := '1';
         when 'Z' => result(i) := 'Z';
         when 'W' => result(i) := 'W';
         when 'L' => result(i) := 'L';
         when 'H' => result(i) := 'H';
         when '-' => result(i) := '-';
       end case;
     end loop;
     return result;
   end to_string;

	-- Function for getting decimal digit from LCD binary data
	function hex_display_to_digit ( hex : bit_vector )
	  return digit is
	  variable dig : digit;
          variable slv : std_logic_vector(6 downto 0);
	begin
          slv := to_stdlogicvector(hex);
	  case slv is
	    when "1000000" => dig := 0;
		 when "1111001" => dig := 1;
		 when "0100100" => dig := 2;
		 when "0110000" => dig := 3;
		 when "0011001" => dig := 4;
		 when "0010010" => dig := 5;
		 when "0000010" => dig := 6;
		 when "1111000" => dig := 7;
		 when "0000000" => dig := 8;
		 when "0010000" => dig := 9;
     when others    => dig := 0;
	  end case;
	  return dig;
	end hex_display_to_digit;
	
	-- Function to split six LCD digit vectors into array of individual digit vector.
   function get_hex_disp ( hex_vector : std_logic_vector )
	  return hexdispvector is
	  variable hex_disp : hexdispvector;
	begin
	  for i in 5 downto 0 loop
	    hex_disp(i) := to_bitvector(hex_vector((7*i + 6) downto 7*i));
	  end loop;
	  return hex_disp;
	end get_hex_disp;

   -- Function for calculating decimal value from individual number digits.	
   function get_ssdinint_value ( ssd : std_logic_vector )
	  return integer is
	  variable hex_disp : hexdispvector;
	  variable int_ssd  : integer:= 0;
	begin
	  hex_disp := get_hex_disp(ssd);
	  for i in 5 downto 0 loop
	    int_ssd := int_ssd + (10**i) * hex_display_to_digit(hex_disp(i));
	  end loop;
	  return int_ssd;
	end get_ssdinint_value;
	
	-- Function to convert std_logic to an integer
   function to_int( s : std_logic ) return natural is
     begin
       if s = '1' then
         return 1;
       else
         return 0;
       end if;
   end to_int;
	
begin
   -- instantiate the unit under test
	uut: fibonacci_counter 
		Port map(
			CLK            => clk,
			PB1            => sw,
			PB2            => pb,
			DC_IN          => dc_in,
			N              => n,
			RESET          => rst,
			SEVEN_SEG_DISPLAY 				=> ssd
		);

	-- generate a clock pulse with a 20 ns period	
	clk <= not clk after period/2;
	
   clock_divider: process(clk)
     variable clk_count: integer:=0;
   begin
     if (clk'event and clk='1') then
	    --if clk_count = 12500000 then
		 if clk_count = 2 then
		    divided_clk <= not divided_clk;
			 clk_count := 0;
		 else
		    clk_count := clk_count + 1;
		 end if;
	  end if;
   end process;
	
	-- Process to run the tests
	run_tests: process is
	   
	   -- Declare the input vectors to apply to the uut
	   -- rst, sw, pb, dc_in, n(4 downto 0)
     constant inputs: vector := (
	      "100101010", "000101010", "000001010", "010000000"
	  );  
	   
	   -- Declare an array with all expected output values
     constant EXPECTED_RESULTS: integer_vector := (                                                                              
         1, 
         1, 2, 3, 5, 8, 13, 21, 34, 55, 55,
         34, 21, 13, 8, 5, 3, 2, 1,
         2, 3, 5, 8, 13, 21, 34                               
     ); 
     
     -- Define number of clock edges required for each input vector test. 0 => 1 clock edge.                        
     constant num_clk_edges: integer_vector := (
         0, 9, 7, 6
     );			
     variable log_line: line;
     variable num: integer := 0;
     variable E_rror: boolean;
     variable ErrorCount: integer:=0;
	  begin
       -- loop through all expected values and ensure that                
       -- they match the actual output value                              
       for i in inputs'range loop
         
        -- Assign the input vectors to the test bench signals.
	      sw    <= to_stdulogic(inputs(i)(7));
	      pb    <= to_stdulogic(inputs(i)(6));
	      dc_in <= to_stdulogic(inputs(i)(5));
	      n(4)  <= to_stdulogic(inputs(i)(4));
         n(3)  <= to_stdulogic(inputs(i)(3));
         n(2)  <= to_stdulogic(inputs(i)(2));
         n(1)  <= to_stdulogic(inputs(i)(1));
         n(0)  <= to_stdulogic(inputs(i)(0));
         rst   <= to_stdulogic(inputs(i)(8));
         
         for j in 0 to num_clk_edges(3 - i) loop
                wait until rising_edge(divided_clk);
                wait for period / 20;                                   
                write(log_line,                                                 
                  "i: " & integer'image(num+j) &                                       
                  ", simulated: " & integer'image(get_ssdinint_value(ssd)) &                             
                  ", expected: " & integer'image(EXPECTED_RESULTS(num+j))              
                );                                                              
                writeline(output, log_line);  
                if ( get_ssdinint_value(ssd) = EXPECTED_RESULTS(num + j)) then
                   E_rror := false;
                else
                   E_rror := true;
                   ErrorCount := ErrorCount + 1;
                end if;                              
                assert (E_rror = false)
                 report "Test failed for input combination: rst:" & std_logic'image(rst) &
		       ", sw:" & std_logic'image(sw) & ", pb:" & std_logic'image(pb) & 
                       ", dc_in:" & std_logic'image(dc_in) & ", n:" & to_string(n) 
                        severity error;       
	      end loop; 
              num := num + num_clk_edges(3 - i) + 1;      
       end loop;                                                          

       if ( ErrorCount = 0 ) then
          report "End of simulation. All tests passed.";                    
       else
          report "End of simulation. Test completed with " & integer'image(ErrorCount) & " errors";
       end if;   
       
       stop(0);
	  end process;
	
end architecture;
