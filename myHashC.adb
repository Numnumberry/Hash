with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Conversion;

procedure myHashC is

	package FIO is new Float_IO(float); use FIO;
	
	subtype string16 is String(1..16);
	subtype string6 is String(1..6);
	subtype slice is String(1..2);
	type largeNumber is mod 2**64;
	
	function char2large is new Ada.Unchecked_Conversion(character, largeNumber);
	function slice2large is new Ada.Unchecked_Conversion(slice, largeNumber);
	function large2int is new Ada.Unchecked_Conversion(largeNumber, integer);
	
	type tableEntry is
		record
			key: string16;
			address: integer;
			probes: integer;
		end record;
		
	table: array(0..127) of tableEntry;
	linOrRan: string6;
	
	function hash(s: string16) return integer is
		s1: slice := "  ";
		s2: slice := "  ";
	begin
		s1(1) := s(2);
		s1(2) := s(3);
		s2(1) := s(5);
		s2(2) := s(4);
		
		return large2int((((slice2large(s1)*7 + slice2large(s2))*3) + char2large(s(1))*27) mod 128);
	end hash;

	procedure insert(s: string16; initial: integer) is
		spotFound: boolean := false;
		count: integer := initial;
		wrapCount: integer := 0;
		R: integer := 1;
		p: integer := 0;
	begin
		if linOrRan = "linear" then
			while spotFound = false loop
				if table(count).key = "                " then
					table(count).key := s;
					table(count).address := initial;
					table(count).probes := count + wrapCount - initial + 1;
					spotFound := true;
				elsif count = 127 then
					wrapCount := count + 1;
					count := 0;
				else
					count := count + 1;
				end if;
			end loop;
		elsif linOrRan = "random" then
			wrapCount := 1;
			while spotFound = false loop
				if table(count).key = "                " then
					table(count).key := s;
					table(count).address := initial;
					table(count).probes := wrapCount;
					spotFound := true;
				else
					R := R * 5;
					R := R mod 512;
					p := R / 4;
					count := initial + p;
					if count > 127 then
						count := count - 128;
					end if;
					wrapCount := wrapCount + 1;
				end if;
			end loop;
		end if;
	end insert;
	
	function find(i: integer; value: string16) return integer is
		index: integer := i;
		R: integer := 1;
		p: integer := 0;
	begin
		if linOrRan = "linear" then
			for j in 0..127 loop
				if table(index).key = value then
					return index;
				else
					index := index + 1;
					if index = 128 then
						index := 0;
					end if;
				end if;
			end loop;
		elsif linOrRan = "random" then
			for j in 0..127 loop
				if table(index).key = value then
					return index;
				else
					R := R * 5;
					R := R mod 512;
					p := R / 4;
					index := i + p;
					if index > 127 then
						index := index - 128;
					end if;
				end if;
			end loop;
		end if;
		return -1;
	end find;
	
	procedure print is
		Output: File_Type;
	begin
		Open(Output, Append_File, "output.txt");
		put_line("     Key              Address   Probes");
		put_line(Output, "     Key              Address   Probes");
		for i in 0..127 loop
			if i < 10 then
				put(i'Image); put(":  |"); put(table(i).key); put("|");
				put(Output, i'Image); put(Output, ":  |"); put(Output, table(i).key); put(Output, "|");
				if table(i).address < 10 then
					put(table(i).address'Image); put_line("       |" & table(i).probes'Image);
					put(Output, table(i).address'Image); put_line(Output, "       |" & table(i).probes'Image);
				elsif table(i).address < 100 then
					put(table(i).address'Image); put_line("      |" & table(i).probes'Image);
					put(Output, table(i).address'Image); put_line(Output, "      |" & table(i).probes'Image);
				else
					put(table(i).address'Image); put_line("     |" & table(i).probes'Image);
					put(Output, table(i).address'Image); put_line(Output, "     |" & table(i).probes'Image);
				end if;
			elsif i < 100 then
				put(i'Image); put(": |"); put(table(i).key); put("|");
				put(Output, i'Image); put(Output, ": |"); put(Output, table(i).key); put(Output, "|");
				if table(i).address < 10 then
					put(table(i).address'Image); put("       |" & table(i).probes'Image); new_line;
					put(Output, table(i).address'Image); put_line(Output, "       |" & table(i).probes'Image);
				elsif table(i).address < 100 then
					put(table(i).address'Image); put("      |" & table(i).probes'Image); new_line;
					put(Output, table(i).address'Image); put_line(Output, "      |" & table(i).probes'Image);
				else
					put(table(i).address'Image); put("     |" & table(i).probes'Image); new_line;
					put(Output, table(i).address'Image); put_line(Output, "     |" & table(i).probes'Image);
				end if;
			else
				put(i'Image); put(":|"); put(table(i).key); put("|");
				put(Output, i'Image); put(Output, ":|"); put(Output, table(i).key); put(Output, "|");
				if table(i).address < 10 then
					put(table(i).address'Image); put("       |" & table(i).probes'Image); new_line;
					put(Output, table(i).address'Image); put_line(Output, "       |" & table(i).probes'Image);
				elsif table(i).address < 100 then
					put(table(i).address'Image); put("      |" & table(i).probes'Image); new_line;
					put(Output, table(i).address'Image); put_line(Output, "      |" & table(i).probes'Image);
				else
					put(table(i).address'Image); put("     |" & table(i).probes'Image); new_line;
					put(Output, table(i).address'Image); put_line(Output, "     |" & table(i).probes'Image);
				end if;
			end if;
		end loop;
		Close(Output);
	end print;
	
	procedure putFloat(f: float) is
		s: String := f'Image;
		Output: File_Type;
	begin
		Open(Output, Append_File, "output.txt");
		put(Output, "avg: ");
		if s(12) = '1' then
			s(3) := s(4);
			s(4) := '.';
			for i in 1..8 loop
				put(s(i));
				put(Output, s(i));
			end loop;
		else
			for i in 1..8 loop
				put(s(i));
				put(Output, s(i));
			end loop;
		end if;
		Close(Output);
	end putFloat;
	
	procedure calculateStats(last: integer) is
		Input: File_Type;
		Output: File_Type;
		min: integer;
		max: integer;
		sum: integer;
		temp: integer;
		
		count: integer := 1;
	begin
		Open(Input, In_File, "words.txt");
		Open(Output, Append_File, "output.txt");
		new_line;
		put_line("First 30: ");
		put_line(Output, "");
		put_line(Output, "First 30: ");
		
		min := 128;
		max := 1;
		sum := 0;
		for i in 1..30 loop
			declare
				Line: String := Get_Line(Input);
			begin
				temp := table(find(hash(Line), Line)).probes;
				if temp < min then
					min := temp;
				end if;
				if temp > max then
					max := temp;
				end if;
				sum := sum + temp;
			end;
		end loop;
		put("min: "); put(min'Image); new_line;
		put(Output, "min: "); put_line(Output, min'Image);
		put("max: "); put(max'Image); new_line;
		put(Output, "max: "); put(Output, max'Image);
		Close(Output);
		put("avg: "); putFloat(float(sum) / float(30)); 
		Open(Output, Append_File, "output.txt");
		put_line(Output, "");
		
		Close(Input);
		Open(Input, In_File, "words.txt");
		
		new_line; new_line;
		put_line("Last 30: ");
		put_line(Output, "Last 30: ");
		
		min := 128;
		max := 1;
		sum := 0;
		for i in 1..last loop
			declare
				Line: String := Get_Line(Input);
			begin
				if i > last - 30 then
					temp := table(find(hash(Line), Line)).probes;
					if temp < min then
						min := temp;
					end if;
					if temp > max then
						max := temp;
					end if;
					sum := sum + temp;
				end if;
			end;
		end loop;
		put("min: "); put(min'Image); new_line;
		put(Output, "min: "); put_line(Output, min'Image);
		put("max: "); put(max'Image); new_line;
		put(Output, "max: "); put(Output, max'Image);
		Close(Output);
		put("avg: "); putFloat(float(sum) / float(30)); 
		Open(Output, Append_File, "output.txt");
		put_line(Output, "");
		Close(Input);
		Close(Output);
	end calculateStats;
	
	procedure process is
		Input: File_Type;
		Output: File_Type;
		fillPercent: float := 0.0;
		desiredPercent: float;
		entryNum: integer := 0;
	begin
		for i in 0..127 loop
			table(i).key := "                ";
			table(i).address := 0;
			table(i).probes := 0;
		end loop;
		Open(Input, In_File, "words.txt");
		Create(Output, Append_File, "output.txt");
		put("Desired fill percentage: "); get(desiredPercent);
		put(Output, "Desired fill percentage: "); put_line(Output, desiredPercent'Image);
		put("Linear or random probe?: "); get(linOrRan);
		put(Output, "Linear or random probe?: "); put_line(Output, linOrRan);
		put_line(Output, "");
		Close(Output);
		new_line;
		while fillPercent <= desiredPercent loop
			declare
				Line: String := Get_Line(Input);
			begin
				insert(Line, hash(Line));
				entryNum := entryNum + 1;
				fillPercent := float(entryNum + 1) / 128.0;		--makes sure not to go over 40%
			end;
		end loop;
		Close(Input);
		print;
		calculateStats(entryNum);
	end process;
begin
	process;
end myHashC;