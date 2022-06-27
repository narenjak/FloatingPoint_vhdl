-- Company: birjand uni
-- Engineer: saeed yazdani _narenjak_
-- 
-- Create Date:    13:01:10 06/26/2022 
-- Design Name: 
-- Module Name:    add_sub_FloatingPoint - Behavioral 

--i'll be use a flow chart(https://poojavaishnav.files.wordpress.com/2015/05/mano-m-m-computer-system-architecture.pdf   page 359)
--Assumption: mantissas in bias (0 to 255)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;



entity AddOrSub is
	port(
			AC     :in  unsigned (31 downto 0);
			BR     :in  unsigned (31 downto 0);
			result :out unsigned (31 downto 0);
			op     :in std_logic);  --select_addORsub 
	end AddOrSub;
architecture Behavioral of AddOrSub is

	signal as_xor_bs :std_logic;
	signal a         :unsigned (7  downto 0):=ac(7  downto 0);
	signal b         :unsigned (7  downto 0):=br(7  downto 0);
	signal a_mantiss :unsigned (22 downto 0);
	signal b_mantiss :unsigned (22 downto 0);
	signal e_result  :unsigned (23 downto 0);
	signal e         :std_logic;
	signal addDone   :std_logic; --if 1 means :addition of A,B done
	signal re30to8   :unsigned (22 downto 0);
--	
--	signal a_b       : integer ;
--	signal b_a       : integer ;
--	
	begin

	as_xor_bs <= ac(31) xor br(31);
	a         <= ac(7  downto 0);
	b         <= br(7  downto 0);
   a_mantiss <= ac(30 downto 8);
	b_mantiss <= br(30 downto 8);
--	a_b       <= to_integer(a)-to_integer(b);
--   b_a		 <= to_integer(b)-to_integer(a);
	
   process (ac,br,op,as_xor_bs,e_result)
	begin

	--check for zeros
		if BR = 0 then
			result <= ac;
		elsif ac = 0 then
			result(30 downto 0) <= br(30 downto 0);
			if op ='1' then -- do sub
				result(31) <= not ac(31);
			else --do add
				result(31) <= '0';
			end if;
		else -- ac/=0 and br/=0
		--align mantissas
			if a>b then
				--shr B and b++	
				--for i in 0 to a_b loop
					--shr B:
					b_mantiss <= '0' & b_mantiss(22 downto 1) ;
					--b++:
					b <= b+1;
				--end loop;
			elsif a<b then
				--shr A and a++
				--for i in 0 to b_a loop
					--shr A:
					a_mantiss <= '0' & a_mantiss(22 downto 1) ;
					--a++:
					a <= a+1;
				--end loop;
			else
				--do nothing
				--i think it help fpga _not sure_
			end if;
			--code above was done a=b 
			result(7 downto 0) <= a;
			
			--mantissas addition or subtraction
			if op = '0' then --do add
				--A+B
				if as_xor_bs = '0' then
					e_result <= resize((a_mantiss + b_mantiss),24);
					addDone <= '1';
				--A-B
				else
					e_result <= resize((a_mantiss + not(b_mantiss) + 1),24);
					addDone <= '0';
				end if;
			else -- op = '1' do sub
				--A+B
				if as_xor_bs = '1' then
					e_result <= resize((a_mantiss + b_mantiss),24);
					addDone <= '1';
				--A-B
				else
					e_result <= resize((a_mantiss + not(b_mantiss) + 1),24);
					addDone <= '0';
				end if;
			result(30 downto 8) <= e_result(22 downto 0);
			result(31) <= ac(31);
			e <= e_result(23);
			end if;
		end if;
	end process;
	
	--normalization
	process (e, addDone)
	begin
	--Cannot read from 'out' object result
	result(30 downto 8) <=re30to8;
	
		if (addDone = '0' and e = '0') then
			result(30 downto 8) <= not(re30to8) + 1;
			result(31) <= not(ac(31));
			
			--for i in 0 to 23 loop --23 for worth case
				if re30to8(22) = '0' then
				--shl A and a--
				result(30 downto 8) <= re30to8(21 downto 0) & '0';
				a <= a-1;
				result(7 downto 0) <= a;
				else
				--do nothing END
				end if;
			--end loop;	
		elsif addDone = '0' and e = '1' then	
			if a = 0 then
				result <= to_unsigned(0,32);
			else 
				--for i in 0 to 23 loop --23 for worth case
					if re30to8(22) = '0' then
					--shl A and a--
					result(30 downto 8) <= re30to8(21 downto 0) & '0';
					a <= a-1;
					result(7 downto 0) <= a;
					else
					--do nothing END
					end if;
				--end loop;	
			end if;
		elsif addDone = '1' and e = '1' then
			--shr A and A1 <= e and a++
			result(30 downto 8) <= '0' & re30to8(22 downto 1) ;
			result(30) <= e;
			a <= a+1;
			result(7 downto 0) <= a;
		else
			--do nothing END
		end if;
		
	end process;

end Behavioral;

