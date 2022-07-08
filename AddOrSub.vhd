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
	signal a_mantiss :unsigned (22 downto 0):=ac(30 downto 8);
	signal b_mantiss :unsigned (22 downto 0):=br(30 downto 8);
	
	signal e_a_m     :unsigned (23 downto 0);
	signal e         :std_logic;
	
	signal addDone   :std_logic; --if =1 means :addition of A,B done
	
	begin
	
	result <= to_unsigned(0,32) when ac=0;
	result <= ac when (BR = 0);
	result <= br when (BR /= 0 and ac = 0);
	result(31) <= not ac(31) when (BR /= 0 and ac = 0 and op ='1');
	a         <= ac(7  downto 0);
	b         <= br(7  downto 0);
   a_mantiss <= ac(30 downto 8);
	b_mantiss <= br(30 downto 8);
	--result(7 downto 0) <= a;--or b, code72_89 above was done a=b
	as_xor_bs <= ac(31) xor br(31);
	
--	process
--	begin
--		--check for zeros
--		if BR /= 0 and ac = 0 then
--			result <= br;
--			if op ='1' then -- do sub
--				result(31) <= not ac(31);
--			end if;
--		end if;
--	end process;
	
	process (a_mantiss,a,b_mantiss,b)
	begin
		if (ac /= 0 and br /=0) then
			--align mantissas
			if a>b then
				--shr B:
				b_mantiss <= '0' & b_mantiss(22 downto 1) ;
				--b++:
				b <= b+1;
			end if;
			if a<b then
				--shr A:
				a_mantiss <= '0' & a_mantiss(22 downto 1) ;
				--a++:
				a <= a+1;
			end if;
		end if;
	end process;	
	 
	
	process(a,b)
	begin	
		--mantissas addition or subtraction
		if (a=b and ac /=0 and br /=0) then
			if op = '0' then --do add
				--A+B
				if as_xor_bs = '0' then
					e_a_m <= resize((a_mantiss + b_mantiss),24);
					addDone <= '1';
				--A-B
				else--if as_xor_bs = '1' then
					e_a_m <= resize((a_mantiss + not(b_mantiss) + 1),24);
					addDone <= '0';
				end if;
			else --if op = '1' do sub
				--A+B
				if as_xor_bs = '1' then
					e_a_m <= resize((a_mantiss + b_mantiss),24);
					addDone <= '1';
				--A-B
				else
					e_a_m <= resize((a_mantiss + not(b_mantiss) + 1),24);
					addDone <= '0';
				end if;
			end if;
			a_mantiss <= e_a_m(22 downto 0);
			e <= e_a_m(23);	
			--normalization
			if (addDone = '0' and e = '0') then
				a_mantiss <= not(a_mantiss) + 1;
				result(31) <= not(ac(31));
				for i in 0 to 23 loop --23 for worth case
					if a_mantiss(22) = '0' then
					--shl A and a--
					a_mantiss <= a_mantiss(21 downto 0) & '0';
					a <= a-1;
					end if;
				end loop;
				if a_mantiss(22) = '1' then
					result(31 downto 8) <= ac(31) & a_mantiss;
					result(7  downto 0) <= a;
				end if;
			end if;
			if (addDone = '0' and e = '1') then	
				if a_mantiss /= 0 then
					for i in 0 to 23 loop --23 for worth case
						if a_mantiss(22) = '0' then
						--shl A and a--
						a_mantiss <= a_mantiss(21 downto 0) & '0';
						a <= a-1;
						end if;
					end loop;
					if a_mantiss(22) = '1' then
						result(31 downto 8) <= ac(31) & a_mantiss;
					end if;
				elsif a_mantiss = 0 then
					result <= to_unsigned(0,32);
				end if;
			end if;
			if addDone = '1' and e = '1' then
				--shr A and A1 <= e and a++
				a_mantiss <= e & a_mantiss(22 downto 1) ;
				a <= a+1;
				result(31 downto 8) <= ac(31) & a_mantiss;
				result(7  downto 0) <= a;
			else
				result(31 downto 8) <= ac(31) & a_mantiss;
				result(7  downto 0) <= a;				
			end if;
		end if;
	end process;
end Behavioral;