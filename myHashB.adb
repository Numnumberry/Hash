with Ada.Text_IO;
with Ada.Direct_IO;
with Ada.Unchecked_Conversion;

procedure myHashB is
	
	subtype string16 is String(1..16);
	subtype string6 is String(1..6);
	subtype slice is String(1..2);
	type largeNumber is mod 2**64;
	
	type tableEntry is
		record
			key: string16;
			address: integer;
			probes: integer;
		end record;
		
	package DIO is new Ada.Direct_IO(tableEntry); use DIO;
	package FIO is new Ada.Text_IO.Float_IO(float); use FIO;
	
	function int2Count is new Ada.Unchecked_Conversion(integer, DIO.Count);
	function Count2int is new Ada.Unchecked_Conversion(DIO.Count, integer);
	function char2large is new Ada.Unchecked_Conversion(character, largeNumber);
	function slice2large is new Ada.Unchecked_Conversion(slice, largeNumber);
	function large2int is new Ada.Unchecked_Conversion(largeNumber, integer);
	
	linOrRan: string6;
	
	function hash(s: string16) return integer is
		s1: slice := "  ";
		s2: slice := "  ";
	begin
		s1(1) := s(2);
		s1(2) := s(3);
		s2(1) := s(5);
		s2(2) := s(4);
		
		return large2int((((slice2large(s1)*7 + slice2large(s2))*3) + char2large(s(1))*27) mod 128) + 1;
	end hash;
	
	procedure insert(s: string16; initial: integer) is
		Relative: DIO.File_Type;
		spotFound: boolean := false;
		count: integer := initial;
		wrapCount: integer := 0;
		R: integer := 1;
		p: integer := 0;
		data: tableEntry;
	begin
		DIO.Open(Relative, DIO.Inout_File, "relativeFile.txt", "");
		if linOrRan = "linear" then
			while spotFound = false loop
				DIO.read(Relative, data, int2Count(count));
				if data.key = "                " then
					data.key := s;
					data.address := initial;
					data.probes := count + wrapCount - initial + 1;
					DIO.write(Relative, data, int2Count(count));
					spotFound := true;
				elsif count = 128 then
					wrapCount := count;
					count := 1;
				else
					count := count + 1;
				end if;
			end loop;
		elsif linOrRan = "random" then
			wrapCount := 1;
			while spotFound = false loop
				DIO.read(Relative, data, int2Count(count));
				if data.key = "                " then
					data.key := s;
					data.address := initial;
					data.probes := wrapCount;
					DIO.write(Relative, data, int2Count(count));
					spotFound := true;
				else
					R := R * 5;
					R := R mod 512;
					p := R / 4;
					count := initial + p;
					if count > 128 then
						count := count - 128;
					end if;
					wrapCount := wrapCount + 1;
				end if;
			end loop;
		end if;
		DIO.Close(Relative);
	end insert;
	
	function find(i: integer; value: string16) return DIO.Count is
		Relative: DIO.File_Type;
		index: DIO.Count := int2Count(i);
		R: integer := 1;
		p: integer := 0;
		data: tableEntry;
	begin		
		DIO.Open(Relative, DIO.Inout_File, "relativeFile.txt", "");
		if linOrRan = "linear" then
			for j in 1..128 loop
				DIO.read(Relative, data, index);
				if data.key = value then
					DIO.Close(Relative);
					return index;
				else
					index := index + 1;
					if index = 129 then
						index := 1;
					end if;
				end if;
			end loop;
		elsif linOrRan = "random" then
			for j in 1..128 loop
				DIO.read(Relative, data, index);
				if data.key = value then
					DIO.Close(Relative);
					return index;
				else
					R := R * 5;
					R := R mod 512;
					p := R / 4;
					index := int2Count(i) + int2Count(p);
					if index > 128 then
						index := index - 128;
					end if;
				end if;
			end loop;
		end if;
		return 666;
	end find;
	
	procedure print is
		Output: Ada.Text_IO.File_Type;
		Relative: DIO.File_Type;
		data: tableEntry;
	begin
		DIO.Open(Relative, DIO.Inout_File, "relativeFile.txt", "");
		Ada.Text_IO.Open(Output, Ada.Text_IO.Append_File, "output.txt");
		Ada.Text_IO.put_line("     Key              Address   Probes");
		Ada.Text_IO.put_line(Output, "     Key              Address   Probes");
		for i in 1..128 loop
			DIO.read(Relative, data, int2Count(i));
			if i < 10 then
				Ada.Text_IO.put(i'Image); Ada.Text_IO.put(":  |"); Ada.Text_IO.put(data.key); Ada.Text_IO.put("|");
				Ada.Text_IO.put(Output, i'Image); Ada.Text_IO.put(Output, ":  |"); Ada.Text_IO.put(Output, data.key); Ada.Text_IO.put(Output, "|");
				if data.address < 10 then
					Ada.Text_IO.put(data.address'Image); Ada.Text_IO.put_line("       |" & data.probes'Image);
					Ada.Text_IO.put(Output, data.address'Image); Ada.Text_IO.put_line(Output, "       |" & data.probes'Image);
				elsif data.address < 100 then
					Ada.Text_IO.put(data.address'Image); Ada.Text_IO.put_line("      |" & data.probes'Image);
					Ada.Text_IO.put(Output, data.address'Image); Ada.Text_IO.put_line(Output, "      |" & data.probes'Image);
				else
					Ada.Text_IO.put(data.address'Image); Ada.Text_IO.put_line("     |" & data.probes'Image);
					Ada.Text_IO.put(Output, data.address'Image); Ada.Text_IO.put_line(Output, "     |" & data.probes'Image);
				end if;
			elsif i < 100 then
				Ada.Text_IO.put(i'Image); Ada.Text_IO.put(": |"); Ada.Text_IO.put(data.key); Ada.Text_IO.put("|");
				Ada.Text_IO.put(Output, i'Image); Ada.Text_IO.put(Output, ": |"); Ada.Text_IO.put(Output, data.key); Ada.Text_IO.put(Output, "|");
				if data.address < 10 then
					Ada.Text_IO.put(data.address'Image); Ada.Text_IO.put("       |" & data.probes'Image); Ada.Text_IO.new_line;
					Ada.Text_IO.put(Output, data.address'Image); Ada.Text_IO.put_line(Output, "       |" & data.probes'Image);
				elsif data.address < 100 then
					Ada.Text_IO.put(data.address'Image); Ada.Text_IO.put("      |" & data.probes'Image); Ada.Text_IO.new_line;
					Ada.Text_IO.put(Output, data.address'Image); Ada.Text_IO.put_line(Output, "      |" & data.probes'Image);
				else
					Ada.Text_IO.put(data.address'Image); Ada.Text_IO.put("     |" & data.probes'Image); Ada.Text_IO.new_line;
					Ada.Text_IO.put(Output, data.address'Image); Ada.Text_IO.put_line(Output, "     |" & data.probes'Image);
				end if;
			else
				Ada.Text_IO.put(i'Image); Ada.Text_IO.put(":|"); Ada.Text_IO.put(data.key); Ada.Text_IO.put("|");
				Ada.Text_IO.put(Output, i'Image); Ada.Text_IO.put(Output, ":|"); Ada.Text_IO.put(Output, data.key); Ada.Text_IO.put(Output, "|");
				if data.address < 10 then
					Ada.Text_IO.put(data.address'Image); Ada.Text_IO.put("       |" & data.probes'Image); Ada.Text_IO.new_line;
					Ada.Text_IO.put(Output, data.address'Image); Ada.Text_IO.put_line(Output, "       |" & data.probes'Image);
				elsif data.address < 100 then
					Ada.Text_IO.put(data.address'Image); Ada.Text_IO.put("      |" & data.probes'Image); Ada.Text_IO.new_line;
					Ada.Text_IO.put(Output, data.address'Image); Ada.Text_IO.put_line(Output, "      |" & data.probes'Image);
				else
					Ada.Text_IO.put(data.address'Image); Ada.Text_IO.put("     |" & data.probes'Image); Ada.Text_IO.new_line;
					Ada.Text_IO.put(Output, data.address'Image); Ada.Text_IO.put_line(Output, "     |" & data.probes'Image);
				end if;
			end if;
		end loop;
		Ada.Text_IO.Close(Output);
		DIO.Close(Relative);
	end print;
	
	procedure putFloat(f: float) is
		s: String := f'Image;
		Output: Ada.Text_IO.File_Type;
	begin
		Ada.Text_IO.Open(Output, Ada.Text_IO.Append_File, "output.txt");
		Ada.Text_IO.put(Output, "avg: ");
		if s(12) = '1' then
			s(3) := s(4);
			s(4) := '.';
			for i in 1..8 loop
				Ada.Text_IO.put(s(i));
				Ada.Text_IO.put(Output, s(i));
			end loop;
		else
			for i in 1..8 loop
				Ada.Text_IO.put(s(i));
				Ada.Text_IO.put(Output, s(i));
			end loop;
		end if;
		Ada.Text_IO.Close(Output);
	end putFloat;
	
	procedure calculateStats(last: integer) is
		Input: Ada.Text_IO.File_Type;
		Output: Ada.Text_IO.File_Type;
		Relative: DIO.File_Type;
		data: tableEntry;
		min: integer;
		max: integer;
		sum: integer;
		temp: integer;
		findValue: DIO.Count;
		count: integer := 1;
	begin
		Ada.Text_IO.Open(Input, Ada.Text_IO.In_File, "words.txt");
		Ada.Text_IO.Open(Output, Ada.Text_IO.Append_File, "output.txt");
		Ada.Text_IO.new_line;
		Ada.Text_IO.put_line("First 30: ");
		Ada.Text_IO.put_line(Output, "");
		Ada.Text_IO.put_line(Output, "First 30: ");		
		
		min := 128;
		max := 1;
		sum := 0;
		for i in 1..30 loop
			declare
				Line: String := Ada.Text_IO.Get_Line(Input);
			begin
				findValue := find(hash(Line), Line);
				DIO.Open(Relative, DIO.Inout_File, "relativeFile.txt", "");
				DIO.read(Relative, data, findValue);
				temp := data.probes;
				if temp < min then
					min := temp;
				end if;
				if temp > max then
					max := temp;
				end if;
				sum := sum + temp;
				DIO.Close(Relative);
			end;
		end loop;
		Ada.Text_IO.put("min: "); Ada.Text_IO.put(min'Image); Ada.Text_IO.new_line;
		Ada.Text_IO.put(Output, "min: "); Ada.Text_IO.put_line(Output, min'Image);
		Ada.Text_IO.put("max: "); Ada.Text_IO.put(max'Image); Ada.Text_IO.new_line;
		Ada.Text_IO.put(Output, "max: "); Ada.Text_IO.put(Output, max'Image);
		Ada.Text_IO.Close(Output);
		Ada.Text_IO.put("avg: "); putFloat(float(sum) / float(30)); 
		Ada.Text_IO.Open(Output, Ada.Text_IO.Append_File, "output.txt");
		Ada.Text_IO.put_line(Output, "");
		
		Ada.Text_IO.Close(Input);
		Ada.Text_IO.Open(Input, Ada.Text_IO.In_File, "words.txt");
		
		Ada.Text_IO.new_line(2);
		Ada.Text_IO.put_line("Last 30: ");
		Ada.Text_IO.put_line(Output, "Last 30: ");
		
		min := 128;
		max := 1;
		sum := 0;
		for i in 1..last loop
			declare
				Line: String := Ada.Text_IO.Get_Line(Input);
			begin
				if i > last - 30 then
					findValue := find(hash(Line), Line);
					DIO.Open(Relative, DIO.Inout_File, "relativeFile.txt", "");
					DIO.read(Relative, data, findValue);
					temp := data.probes;
					if temp < min then
						min := temp;
					end if;
					if temp > max then
						max := temp;
					end if;
					sum := sum + temp;
					DIO.Close(Relative);
				end if;
			end;
		end loop;
		Ada.Text_IO.put("min: "); Ada.Text_IO.put(min'Image); Ada.Text_IO.new_line;
		Ada.Text_IO.put(Output, "min: "); Ada.Text_IO.put_line(Output, min'Image);
		Ada.Text_IO.put("max: "); Ada.Text_IO.put(max'Image); Ada.Text_IO.new_line;
		Ada.Text_IO.put(Output, "max: "); Ada.Text_IO.put(Output, max'Image);
		Ada.Text_IO.Close(Output);
		Ada.Text_IO.put("avg: "); putFloat(float(sum) / float(30)); 
		Ada.Text_IO.Open(Output, Ada.Text_IO.Append_File, "output.txt");
		Ada.Text_IO.put_line(Output, "");
		Ada.Text_IO.Close(Input);
		Ada.Text_IO.Close(Output);
	end calculateStats;
	
	procedure process is
		Input: Ada.Text_IO.File_Type;
		Output: Ada.Text_IO.File_Type;
		Relative: DIO.File_Type;
		fillPercent: float := 0.0;
		desiredPercent: float;
		entryNum: integer := 0;
		data: tableEntry;
		knt: DIO.Count := 1;
	begin
		DIO.Open(Relative, DIO.Inout_File, "relativeFile.txt", "");
		data.key := "                ";
		data.address := 0;
		data.probes := 0;
		for i in 1..128 loop
			DIO.write(Relative, data);
		end loop;
		DIO.Close(Relative);
		
		Ada.Text_IO.Open(Input, Ada.Text_IO.In_File, "words.txt");
		Ada.Text_IO.Create(Output, Ada.Text_IO.Append_File, "output.txt");
		Ada.Text_IO.put("Desired fill percentage: "); get(desiredPercent);
		Ada.Text_IO.put(Output, "Desired fill percentage: ");
		Ada.Text_IO.put_line(Output, desiredPercent'Image);
		Ada.Text_IO.put("Linear or random probe?: "); Ada.Text_IO.get(linOrRan);
		Ada.Text_IO.put(Output, "Linear or random probe?: ");
		Ada.Text_IO.put_line(Output, linOrRan);
		Ada.Text_IO.put_line(Output, "");
		Ada.Text_IO.Close(Output);
		Ada.Text_IO.new_line;
		while fillPercent <= desiredPercent loop
			declare
				Line: String := Ada.Text_IO.Get_Line(Input);
			begin
				insert(Line, hash(Line));
				entryNum := entryNum + 1;
				fillPercent := float(entryNum + 1) / 128.0;		--makes sure not to go over 40%
			end;
		end loop;
		Ada.Text_IO.Close(Input);
		print;
		calculateStats(entryNum);
	end process;
begin
	process;
end myHashB;