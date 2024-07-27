--[[
 .____                  ________ ___.    _____                           __                
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________ 
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|   
         \/          \/         \/    \/                \/     \/     \/                   
          \_Welcome to LuaObfuscator.com   (Alpha 0.10.6) ~  Much Love, Ferib 

]]--

local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 79) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local FlatIdent_12703 = 0;
			local a;
			while true do
				if (FlatIdent_12703 == 0) then
					a = Char(StrToNumber(byte, 16));
					if repeatNext then
						local FlatIdent_2BD95 = 0;
						local b;
						while true do
							if (FlatIdent_2BD95 == 1) then
								return b;
							end
							if (FlatIdent_2BD95 == 0) then
								b = Rep(a, repeatNext);
								repeatNext = nil;
								FlatIdent_2BD95 = 1;
							end
						end
					else
						return a;
					end
					break;
				end
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local FlatIdent_60EA1 = 0;
			local Res;
			while true do
				if (FlatIdent_60EA1 == 0) then
					Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
					return Res - (Res % 1);
				end
			end
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local FlatIdent_31A5A = 0;
		local a;
		while true do
			if (FlatIdent_31A5A == 1) then
				return a;
			end
			if (FlatIdent_31A5A == 0) then
				a = Byte(ByteString, DIP, DIP);
				DIP = DIP + 1;
				FlatIdent_31A5A = 1;
			end
		end
	end
	local function gBits16()
		local FlatIdent_31905 = 0;
		local a;
		local b;
		while true do
			if (FlatIdent_31905 == 1) then
				return (b * 256) + a;
			end
			if (0 == FlatIdent_31905) then
				a, b = Byte(ByteString, DIP, DIP + 2);
				DIP = DIP + 2;
				FlatIdent_31905 = 1;
			end
		end
	end
	local function gBits32()
		local a, b, c, d = Byte(ByteString, DIP, DIP + 3);
		DIP = DIP + 4;
		return (d * 16777216) + (c * 65536) + (b * 256) + a;
	end
	local function gFloat()
		local FlatIdent_61B23 = 0;
		local Left;
		local Right;
		local IsNormal;
		local Mantissa;
		local Exponent;
		local Sign;
		while true do
			if (2 == FlatIdent_61B23) then
				Exponent = gBit(Right, 21, 31);
				Sign = ((gBit(Right, 32) == 1) and -1) or 1;
				FlatIdent_61B23 = 3;
			end
			if (FlatIdent_61B23 == 3) then
				if (Exponent == 0) then
					if (Mantissa == 0) then
						return Sign * 0;
					else
						Exponent = 1;
						IsNormal = 0;
					end
				elseif (Exponent == 2047) then
					return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
				end
				return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
			end
			if (FlatIdent_61B23 == 0) then
				Left = gBits32();
				Right = gBits32();
				FlatIdent_61B23 = 1;
			end
			if (FlatIdent_61B23 == 1) then
				IsNormal = 1;
				Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
				FlatIdent_61B23 = 2;
			end
		end
	end
	local function gString(Len)
		local Str;
		if not Len then
			Len = gBits32();
			if (Len == 0) then
				return "";
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local Instrs = {};
		local Functions = {};
		local Lines = {};
		local Chunk = {Instrs,Functions,nil,Lines};
		local ConstCount = gBits32();
		local Consts = {};
		for Idx = 1, ConstCount do
			local Type = gBits8();
			local Cons;
			if (Type == 1) then
				Cons = gBits8() ~= 0;
			elseif (Type == 2) then
				Cons = gFloat();
			elseif (Type == 3) then
				Cons = gString();
			end
			Consts[Idx] = Cons;
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local FlatIdent_2FD19 = 0;
			local Descriptor;
			while true do
				if (FlatIdent_2FD19 == 0) then
					Descriptor = gBits8();
					if (gBit(Descriptor, 1, 1) == 0) then
						local Type = gBit(Descriptor, 2, 3);
						local Mask = gBit(Descriptor, 4, 6);
						local Inst = {gBits16(),gBits16(),nil,nil};
						if (Type == 0) then
							local FlatIdent_79536 = 0;
							while true do
								if (FlatIdent_79536 == 0) then
									Inst[3] = gBits16();
									Inst[4] = gBits16();
									break;
								end
							end
						elseif (Type == 1) then
							Inst[3] = gBits32();
						elseif (Type == 2) then
							Inst[3] = gBits32() - (2 ^ 16);
						elseif (Type == 3) then
							Inst[3] = gBits32() - (2 ^ 16);
							Inst[4] = gBits16();
						end
						if (gBit(Mask, 1, 1) == 1) then
							Inst[2] = Consts[Inst[2]];
						end
						if (gBit(Mask, 2, 2) == 1) then
							Inst[3] = Consts[Inst[3]];
						end
						if (gBit(Mask, 3, 3) == 1) then
							Inst[4] = Consts[Inst[4]];
						end
						Instrs[Idx] = Inst;
					end
					break;
				end
			end
		end
		for Idx = 1, gBits32() do
			Functions[Idx - 1] = Deserialize();
		end
		return Chunk;
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local Instr = Instr;
			local Proto = Proto;
			local Params = Params;
			local _R = _R;
			local VIP = 1;
			local Top = -1;
			local Vararg = {};
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local Lupvals = {};
			local Stk = {};
			for Idx = 0, PCount do
				if (Idx >= Params) then
					Vararg[Idx - Params] = Args[Idx + 1];
				else
					Stk[Idx] = Args[Idx + 1];
				end
			end
			local Varargsz = (PCount - Params) + 1;
			local Inst;
			local Enum;
			while true do
				local FlatIdent_7A75F = 0;
				while true do
					if (FlatIdent_7A75F == 1) then
						if (Enum <= 29) then
							if (Enum <= 14) then
								if (Enum <= 6) then
									if (Enum <= 2) then
										if (Enum <= 0) then
											Upvalues[Inst[3]] = Stk[Inst[2]];
										elseif (Enum == 1) then
											local A;
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											VIP = Inst[3];
										else
											local A = Inst[2];
											local Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											local Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
										end
									elseif (Enum <= 4) then
										if (Enum == 3) then
											local FlatIdent_E0D0 = 0;
											local A;
											while true do
												if (FlatIdent_E0D0 == 0) then
													A = Inst[2];
													Stk[A](Unpack(Stk, A + 1, Inst[3]));
													break;
												end
											end
										else
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											if (Stk[Inst[2]] ~= Stk[Inst[4]]) then
												VIP = VIP + 1;
											else
												VIP = Inst[3];
											end
										end
									elseif (Enum > 5) then
										local A;
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										if (Stk[Inst[2]] == Stk[Inst[4]]) then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									else
										local FlatIdent_8DCA9 = 0;
										local A;
										while true do
											if (FlatIdent_8DCA9 == 0) then
												A = Inst[2];
												do
													return Unpack(Stk, A, A + Inst[3]);
												end
												break;
											end
										end
									end
								elseif (Enum <= 10) then
									if (Enum <= 8) then
										if (Enum == 7) then
											local FlatIdent_39EBF = 0;
											local B;
											local A;
											while true do
												if (FlatIdent_39EBF == 2) then
													VIP = VIP + 1;
													Inst = Instr[VIP];
													A = Inst[2];
													FlatIdent_39EBF = 3;
												end
												if (FlatIdent_39EBF == 6) then
													Stk[A](Unpack(Stk, A + 1, Inst[3]));
													VIP = VIP + 1;
													Inst = Instr[VIP];
													FlatIdent_39EBF = 7;
												end
												if (FlatIdent_39EBF == 8) then
													VIP = Inst[3];
													break;
												end
												if (FlatIdent_39EBF == 3) then
													B = Stk[Inst[3]];
													Stk[A + 1] = B;
													Stk[A] = B[Inst[4]];
													FlatIdent_39EBF = 4;
												end
												if (FlatIdent_39EBF == 1) then
													VIP = VIP + 1;
													Inst = Instr[VIP];
													Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
													FlatIdent_39EBF = 2;
												end
												if (FlatIdent_39EBF == 0) then
													B = nil;
													A = nil;
													Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
													FlatIdent_39EBF = 1;
												end
												if (FlatIdent_39EBF == 5) then
													VIP = VIP + 1;
													Inst = Instr[VIP];
													A = Inst[2];
													FlatIdent_39EBF = 6;
												end
												if (FlatIdent_39EBF == 7) then
													do
														return;
													end
													VIP = VIP + 1;
													Inst = Instr[VIP];
													FlatIdent_39EBF = 8;
												end
												if (FlatIdent_39EBF == 4) then
													VIP = VIP + 1;
													Inst = Instr[VIP];
													Stk[Inst[2]] = Inst[3];
													FlatIdent_39EBF = 5;
												end
											end
										else
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											if (Stk[Inst[2]] ~= Stk[Inst[4]]) then
												VIP = VIP + 1;
											else
												VIP = Inst[3];
											end
										end
									elseif (Enum == 9) then
										if (Stk[Inst[2]] == Inst[4]) then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									else
										local A;
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return Stk[Inst[2]]();
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									end
								elseif (Enum <= 12) then
									if (Enum == 11) then
										local A;
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									else
										local B;
										local A;
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										for Idx = Inst[2], Inst[3] do
											Stk[Idx] = nil;
										end
									end
								elseif (Enum > 13) then
									if (Inst[2] == Stk[Inst[4]]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									Stk[Inst[2]] = Stk[Inst[3]] - Stk[Inst[4]];
								end
							elseif (Enum <= 21) then
								if (Enum <= 17) then
									if (Enum <= 15) then
										Stk[Inst[2]]();
									elseif (Enum == 16) then
										local FlatIdent_20FB0 = 0;
										local Edx;
										local Results;
										local Limit;
										local B;
										local A;
										while true do
											if (FlatIdent_20FB0 == 6) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
												FlatIdent_20FB0 = 7;
											end
											if (FlatIdent_20FB0 == 7) then
												Top = (Limit + A) - 1;
												Edx = 0;
												for Idx = A, Top do
													Edx = Edx + 1;
													Stk[Idx] = Results[Edx];
												end
												VIP = VIP + 1;
												FlatIdent_20FB0 = 8;
											end
											if (2 == FlatIdent_20FB0) then
												Stk[A](Stk[A + 1]);
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Env[Inst[3]];
												FlatIdent_20FB0 = 3;
											end
											if (1 == FlatIdent_20FB0) then
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												FlatIdent_20FB0 = 2;
											end
											if (FlatIdent_20FB0 == 10) then
												VIP = Inst[3];
												break;
											end
											if (0 == FlatIdent_20FB0) then
												Edx = nil;
												Results, Limit = nil;
												B = nil;
												A = nil;
												FlatIdent_20FB0 = 1;
											end
											if (FlatIdent_20FB0 == 8) then
												Inst = Instr[VIP];
												A = Inst[2];
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
												VIP = VIP + 1;
												FlatIdent_20FB0 = 9;
											end
											if (FlatIdent_20FB0 == 3) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Env[Inst[3]];
												VIP = VIP + 1;
												FlatIdent_20FB0 = 4;
											end
											if (FlatIdent_20FB0 == 4) then
												Inst = Instr[VIP];
												A = Inst[2];
												B = Stk[Inst[3]];
												Stk[A + 1] = B;
												FlatIdent_20FB0 = 5;
											end
											if (9 == FlatIdent_20FB0) then
												Inst = Instr[VIP];
												Stk[Inst[2]]();
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_20FB0 = 10;
											end
											if (FlatIdent_20FB0 == 5) then
												Stk[A] = B[Inst[4]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												FlatIdent_20FB0 = 6;
											end
										end
									else
										local B;
										local A;
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
									end
								elseif (Enum <= 19) then
									if (Enum == 18) then
										local A = Inst[2];
										local Cls = {};
										for Idx = 1, #Lupvals do
											local List = Lupvals[Idx];
											for Idz = 0, #List do
												local Upv = List[Idz];
												local NStk = Upv[1];
												local DIP = Upv[2];
												if ((NStk == Stk) and (DIP >= A)) then
													local FlatIdent_6A091 = 0;
													while true do
														if (FlatIdent_6A091 == 0) then
															Cls[DIP] = NStk[DIP];
															Upv[1] = Cls;
															break;
														end
													end
												end
											end
										end
									else
										for Idx = Inst[2], Inst[3] do
											Stk[Idx] = nil;
										end
									end
								elseif (Enum == 20) then
									if not Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								elseif Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum <= 25) then
								if (Enum <= 23) then
									if (Enum > 22) then
										local FlatIdent_882F4 = 0;
										local B;
										local A;
										while true do
											if (FlatIdent_882F4 == 6) then
												do
													return;
												end
												break;
											end
											if (FlatIdent_882F4 == 0) then
												B = nil;
												A = nil;
												Stk[Inst[2]] = Upvalues[Inst[3]];
												FlatIdent_882F4 = 1;
											end
											if (FlatIdent_882F4 == 5) then
												Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_882F4 = 6;
											end
											if (FlatIdent_882F4 == 2) then
												B = Stk[Inst[3]];
												Stk[A + 1] = B;
												Stk[A] = B[Inst[4]];
												FlatIdent_882F4 = 3;
											end
											if (FlatIdent_882F4 == 3) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												FlatIdent_882F4 = 4;
											end
											if (FlatIdent_882F4 == 4) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												FlatIdent_882F4 = 5;
											end
											if (FlatIdent_882F4 == 1) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												FlatIdent_882F4 = 2;
											end
										end
									else
										Stk[Inst[2]] = Inst[3] ~= 0;
									end
								elseif (Enum > 24) then
									do
										return;
									end
								else
									local B;
									local A;
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
								end
							elseif (Enum <= 27) then
								if (Enum > 26) then
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if (Stk[Inst[2]] == Stk[Inst[4]]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								elseif (Stk[Inst[2]] ~= Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum > 28) then
								local A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
							else
								do
									return Stk[Inst[2]];
								end
							end
						elseif (Enum <= 44) then
							if (Enum <= 36) then
								if (Enum <= 32) then
									if (Enum <= 30) then
										Stk[Inst[2]] = Inst[3];
									elseif (Enum == 31) then
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									else
										local FlatIdent_20FE3 = 0;
										local NewProto;
										local NewUvals;
										local Indexes;
										while true do
											if (FlatIdent_20FE3 == 0) then
												NewProto = Proto[Inst[3]];
												NewUvals = nil;
												FlatIdent_20FE3 = 1;
											end
											if (FlatIdent_20FE3 == 1) then
												Indexes = {};
												NewUvals = Setmetatable({}, {__index=function(_, Key)
													local Val = Indexes[Key];
													return Val[1][Val[2]];
												end,__newindex=function(_, Key, Value)
													local Val = Indexes[Key];
													Val[1][Val[2]] = Value;
												end});
												FlatIdent_20FE3 = 2;
											end
											if (FlatIdent_20FE3 == 2) then
												for Idx = 1, Inst[4] do
													VIP = VIP + 1;
													local Mvm = Instr[VIP];
													if (Mvm[1] == 57) then
														Indexes[Idx - 1] = {Stk,Mvm[3]};
													else
														Indexes[Idx - 1] = {Upvalues,Mvm[3]};
													end
													Lupvals[#Lupvals + 1] = Indexes;
												end
												Stk[Inst[2]] = Wrap(NewProto, NewUvals, Env);
												break;
											end
										end
									end
								elseif (Enum <= 34) then
									if (Enum > 33) then
										Stk[Inst[2]] = Stk[Inst[3]] + Stk[Inst[4]];
									else
										local A = Inst[2];
										Stk[A](Stk[A + 1]);
									end
								elseif (Enum == 35) then
									if (Stk[Inst[2]] == Stk[Inst[4]]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local FlatIdent_628E3 = 0;
									local A;
									while true do
										if (3 == FlatIdent_628E3) then
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											FlatIdent_628E3 = 4;
										end
										if (1 == FlatIdent_628E3) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											FlatIdent_628E3 = 2;
										end
										if (FlatIdent_628E3 == 0) then
											A = nil;
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											FlatIdent_628E3 = 1;
										end
										if (FlatIdent_628E3 == 2) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											FlatIdent_628E3 = 3;
										end
										if (FlatIdent_628E3 == 4) then
											VIP = VIP + 1;
											Inst = Instr[VIP];
											if Stk[Inst[2]] then
												VIP = VIP + 1;
											else
												VIP = Inst[3];
											end
											break;
										end
									end
								end
							elseif (Enum <= 40) then
								if (Enum <= 38) then
									if (Enum == 37) then
										Stk[Inst[2]] = Env[Inst[3]];
									else
										local A = Inst[2];
										local C = Inst[4];
										local CB = A + 2;
										local Result = {Stk[A](Stk[A + 1], Stk[CB])};
										for Idx = 1, C do
											Stk[CB + Idx] = Result[Idx];
										end
										local R = Result[1];
										if R then
											Stk[CB] = R;
											VIP = Inst[3];
										else
											VIP = VIP + 1;
										end
									end
								elseif (Enum == 39) then
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if (Stk[Inst[2]] ~= Stk[Inst[4]]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local FlatIdent_869A9 = 0;
									local A;
									local Results;
									local Edx;
									while true do
										if (FlatIdent_869A9 == 0) then
											A = Inst[2];
											Results = {Stk[A](Stk[A + 1])};
											FlatIdent_869A9 = 1;
										end
										if (FlatIdent_869A9 == 1) then
											Edx = 0;
											for Idx = A, Inst[4] do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											break;
										end
									end
								end
							elseif (Enum <= 42) then
								if (Enum > 41) then
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								else
									do
										return Stk[Inst[2]]();
									end
								end
							elseif (Enum == 43) then
								local FlatIdent_2A644 = 0;
								local A;
								while true do
									if (FlatIdent_2A644 == 0) then
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										break;
									end
								end
							else
								Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
							end
						elseif (Enum <= 51) then
							if (Enum <= 47) then
								if (Enum <= 45) then
									local FlatIdent_7F3C8 = 0;
									local Edx;
									local Results;
									local A;
									while true do
										if (3 == FlatIdent_7F3C8) then
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_7F3C8 = 4;
										end
										if (FlatIdent_7F3C8 == 2) then
											for Idx = A, Inst[4] do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_7F3C8 = 3;
										end
										if (FlatIdent_7F3C8 == 6) then
											VIP = Inst[3];
											break;
										end
										if (0 == FlatIdent_7F3C8) then
											Edx = nil;
											Results = nil;
											A = nil;
											FlatIdent_7F3C8 = 1;
										end
										if (FlatIdent_7F3C8 == 4) then
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_7F3C8 = 5;
										end
										if (5 == FlatIdent_7F3C8) then
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_7F3C8 = 6;
										end
										if (1 == FlatIdent_7F3C8) then
											A = Inst[2];
											Results = {Stk[A](Stk[A + 1])};
											Edx = 0;
											FlatIdent_7F3C8 = 2;
										end
									end
								elseif (Enum > 46) then
									local B;
									local A;
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
								else
									Stk[Inst[2]][Inst[3]] = Inst[4];
								end
							elseif (Enum <= 49) then
								if (Enum == 48) then
									local FlatIdent_651C5 = 0;
									local A;
									while true do
										if (FlatIdent_651C5 == 0) then
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
											break;
										end
									end
								else
									local A = Inst[2];
									local B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
								end
							elseif (Enum > 50) then
								local FlatIdent_3CDED = 0;
								local A;
								while true do
									if (FlatIdent_3CDED == 1) then
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										FlatIdent_3CDED = 2;
									end
									if (6 == FlatIdent_3CDED) then
										if (Stk[Inst[2]] == Stk[Inst[4]]) then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
										break;
									end
									if (FlatIdent_3CDED == 5) then
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_3CDED = 6;
									end
									if (FlatIdent_3CDED == 2) then
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										FlatIdent_3CDED = 3;
									end
									if (4 == FlatIdent_3CDED) then
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_3CDED = 5;
									end
									if (0 == FlatIdent_3CDED) then
										A = nil;
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_3CDED = 1;
									end
									if (FlatIdent_3CDED == 3) then
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										FlatIdent_3CDED = 4;
									end
								end
							else
								local A;
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							end
						elseif (Enum <= 55) then
							if (Enum <= 53) then
								if (Enum == 52) then
									local FlatIdent_6C967 = 0;
									local A;
									while true do
										if (FlatIdent_6C967 == 4) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											FlatIdent_6C967 = 5;
										end
										if (6 == FlatIdent_6C967) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]] + Stk[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											FlatIdent_6C967 = 7;
										end
										if (2 == FlatIdent_6C967) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											FlatIdent_6C967 = 3;
										end
										if (FlatIdent_6C967 == 9) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											FlatIdent_6C967 = 10;
										end
										if (FlatIdent_6C967 == 3) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											FlatIdent_6C967 = 4;
										end
										if (FlatIdent_6C967 == 8) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											FlatIdent_6C967 = 9;
										end
										if (FlatIdent_6C967 == 7) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											FlatIdent_6C967 = 8;
										end
										if (FlatIdent_6C967 == 11) then
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											VIP = Inst[3];
											break;
										end
										if (FlatIdent_6C967 == 10) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]] + Stk[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											FlatIdent_6C967 = 11;
										end
										if (FlatIdent_6C967 == 5) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											FlatIdent_6C967 = 6;
										end
										if (FlatIdent_6C967 == 0) then
											A = nil;
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]] - Stk[Inst[4]];
											VIP = VIP + 1;
											FlatIdent_6C967 = 1;
										end
										if (1 == FlatIdent_6C967) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											FlatIdent_6C967 = 2;
										end
									end
								else
									local B;
									local A;
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]]();
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum == 54) then
								local A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
							else
								local FlatIdent_699E4 = 0;
								local A;
								while true do
									if (FlatIdent_699E4 == 0) then
										A = nil;
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_699E4 = 1;
									end
									if (FlatIdent_699E4 == 2) then
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										FlatIdent_699E4 = 3;
									end
									if (FlatIdent_699E4 == 1) then
										A = Inst[2];
										Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_699E4 = 2;
									end
									if (FlatIdent_699E4 == 3) then
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Stk[A + 1]);
										FlatIdent_699E4 = 4;
									end
									if (4 == FlatIdent_699E4) then
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										break;
									end
								end
							end
						elseif (Enum <= 57) then
							if (Enum > 56) then
								Stk[Inst[2]] = Stk[Inst[3]];
							else
								local FlatIdent_98327 = 0;
								local B;
								local A;
								while true do
									if (FlatIdent_98327 == 9) then
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										FlatIdent_98327 = 10;
									end
									if (FlatIdent_98327 == 2) then
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										FlatIdent_98327 = 3;
									end
									if (FlatIdent_98327 == 3) then
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_98327 = 4;
									end
									if (FlatIdent_98327 == 8) then
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										FlatIdent_98327 = 9;
									end
									if (FlatIdent_98327 == 6) then
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										FlatIdent_98327 = 7;
									end
									if (7 == FlatIdent_98327) then
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										FlatIdent_98327 = 8;
									end
									if (FlatIdent_98327 == 10) then
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_98327 = 11;
									end
									if (FlatIdent_98327 == 1) then
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										FlatIdent_98327 = 2;
									end
									if (FlatIdent_98327 == 11) then
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										break;
									end
									if (FlatIdent_98327 == 5) then
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_98327 = 6;
									end
									if (FlatIdent_98327 == 4) then
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										FlatIdent_98327 = 5;
									end
									if (0 == FlatIdent_98327) then
										B = nil;
										A = nil;
										Stk[Inst[2]][Inst[3]] = Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										FlatIdent_98327 = 1;
									end
								end
							end
						elseif (Enum > 58) then
							Stk[Inst[2]] = Upvalues[Inst[3]];
						else
							VIP = Inst[3];
						end
						VIP = VIP + 1;
						break;
					end
					if (FlatIdent_7A75F == 0) then
						Inst = Instr[VIP];
						Enum = Inst[1];
						FlatIdent_7A75F = 1;
					end
				end
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!0E3O00028O00026O001440026O000840026O00F03F026O00104003463O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F7469736F2O392F4861784875624D61696E2F6D61696E2F77686974656C6973742E6C7561027O004003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203053O007072696E7403133O00466574636865642057686974656C6973743A2003043O004B69636B03193O004661696C656420746F2066657463682077686974656C69737400773O00121E3O00014O0013000100093O0026093O00150001000200043A3O001500012O0013000900093O00062000093O000100042O00393O00064O00393O00044O00393O00074O00393O00084O0039000A00054O0039000B00044O001D000A00020002000615000A001200013O00043A3O001200012O0039000A00094O000F000A0001000100043A3O007500012O0039000A00084O000F000A0001000100043A3O00750001002O0E0003002400013O00043A3O0024000100121E000A00013O002609000A001D0001000400043A3O001D00012O0013000700073O00121E3O00053O00043A3O00240001002609000A00180001000100043A3O001800012O0013000600063O00062000060001000100012O00393O00033O00121E000A00043O00043A3O001800010026093O00320001000100043A3O0032000100121E000A00013O002609000A002C0001000100043A3O002C000100121E000100064O0013000200023O00121E000A00043O002609000A00270001000400043A3O0027000100022C000200023O00121E3O00043O00043A3O0032000100043A3O002700010026093O00430001000700043A3O0043000100121E000A00013O002O0E0001003C0001000A00043A3O003C0001001225000B00083O00201F000B000B000900201F0004000B000A2O0013000500053O00121E000A00043O002O0E000400350001000A00043A3O0035000100062000050003000100012O00393O00033O00121E3O00033O00043A3O0043000100043A3O00350001002O0E0004006D00013O00043A3O006D000100121E000A00013O002609000A004E0001000400043A3O004E0001001225000B000B3O00120B000C000C6O000D00036O000B000D000100124O00073O00044O006D0001002609000A00460001000100043A3O004600012O0039000B00024O0039000C00014O001D000B000200022O00390003000B3O0006140003006B0001000100043A3O006B000100121E000B00014O0013000C000C3O002609000B00580001000100043A3O0058000100121E000C00013O002609000C005B0001000100043A3O005B000100121E000D00013O002609000D005E0001000100043A3O005E0001001225000E00083O002007000E000E000900202O000E000E000A00202O000E000E000D00122O0010000E6O000E001000016O00013O00044O005E000100043A3O005B000100043A3O006B000100043A3O0058000100121E000A00043O00043A3O004600010026093O00020001000500043A3O0002000100022C000700044O0013000800083O00062000080005000100012O00393O00043O00121E3O00023O00043A3O000200012O00128O00193O00013O00063O002C3O0003083O00496E7374616E63652O033O006E657703093O005363722O656E47756903063O00506172656E7403043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C61796572030C3O0057616974466F724368696C6403093O00506C6179657247756903053O004672616D6503043O0053697A6503053O005544696D32028O00026O006940026O00594003083O00506F736974696F6E026O00E03F026O0059C0026O0049C003103O004261636B67726F756E64436F6C6F723303063O00436F6C6F7233026O00F03F03093O00546578744C6162656C026O003440026O0034C003043O005465787403113O00484158485542204B65792053797374656D030A3O0054657874436F6C6F7233030A3O00496E707574426567616E03073O00436F2O6E656374030C3O00496E7075744368616E676564030A3O00496E707574456E646564030A3O004765745365727669636503103O0055736572496E7075745365727669636503073O0054657874426F78030D3O00456E74657220746865204B657903163O004261636B67726F756E645472616E73706172656E6379030B3O00546578745772612O7065642O01030A3O005465787442752O746F6E03063O005375626D697403013O005803113O004D6F75736542752O746F6E31436C69636B03073O00476574204B657900F83O00120C3O00013O00206O000200122O000100038O0002000200122O000100053O00202O00010001000600202O00010001000700202O00010001000800122O000300096O00010003000200104O0004000100122O000100013O00202O00010001000200122O0002000A6O00010002000200122O0002000C3O00202O00020002000200122O0003000D3O00122O0004000E3O00122O0005000D3O00122O0006000F6O00020006000200102O0001000B000200122O0002000C3O00202O00020002000200122O000300113O00122O000400123O00122O000500113O00122O000600136O00020006000200102O00010010000200122O000200153O00202O00020002000200122O000300163O00122O000400163O00122O000500166O00020005000200102O00010014000200102O000100043O00122O000200013O00202O00020002000200122O000300176O00020002000200122O0003000C3O00202O00030003000200122O000400163O00122O0005000D3O00122O0006000D3O00122O000700186O00030007000200102O0002000B000300122O0003000C3O00202O00030003000200122O0004000D3O00122O0005000D3O00122O0006000D3O00122O000700196O00030007000200102O00020010000300302O0002001A001B00122O000300153O00202O00030003000200122O000400163O00122O000500163O00122O000600166O00030006000200102O0002001C000300122O000300153O00202O00030003000200122O0004000D3O00122O0005000D3O00122O0006000D6O00030006000200102O00020014000300102O0002000400014O000300063O00062000073O000100032O00393O00054O00393O00014O00393O00063O00201F00080002001D00203100080008001E000620000A0001000100042O00393O00034O00393O00054O00393O00064O00393O00014O00030008000A000100201F00080002001F00203100080008001E000620000A0002000100012O00393O00044O00030008000A000100201F00080002002000203100080008001E000620000A0003000100022O00393O00034O00393O00044O00110008000A000100122O000800053O00202O00080008002100122O000A00226O0008000A000200202O00080008001F00202O00080008001E000620000A0004000100032O00393O00044O00393O00034O00393O00074O00320008000A000100122O000800013O00202O00080008000200122O000900236O00080002000200122O0009000C3O00202O00090009000200122O000A00163O00122O000B000D3O00122O000C00113O00122O000D000D6O0009000D000200102O0008000B000900122O0009000C3O00202O00090009000200122O000A000D3O00122O000B000D3O00122O000C000D3O00122O000D000D6O0009000D000200102O00080010000900302O0008001A002400122O000900153O00202O00090009000200122O000A000D3O00122O000B000D3O00122O000C000D6O0009000C000200102O0008001C000900302O00080025001100122O000900153O00202O00090009000200122O000A00163O00122O000B00163O00122O000C00166O0009000C000200102O00080014000900302O00080026002700102O00080004000100122O000900013O00202O00090009000200122O000A00286O00090002000200122O000A000C3O00202O000A000A000200122O000B00113O00122O000C000D3O00122O000D00113O00122O000E000D6O000A000E000200102O0009000B000A00122O000A000C3O00202O000A000A000200122O000B000D3O00122O000C000D3O00122O000D00113O00122O000E000D6O000A000E000200102O00090010000A00302O0009001A002900102O00090004000100122O000A00013O00202O000A000A000200122O000B00286O000A0002000200122O000B000C3O00202O000B000B000200122O000C000D3O00122O000D00183O00122O000E000D3O00122O000F00186O000B000F000200102O000A000B000B00122O000B000C3O00202O000B000B000200122O000C00163O00122O000D00193O00122O000E000D3O00122O000F000D6O000B000F000200102A000A0010000B003038000A001A002A00122O000B00153O00202O000B000B000200122O000C00163O00122O000D00163O00122O000E00166O000B000E000200102O000A001C000B00122O000B00153O00202O000B000B000200122O000C00163O00122O000D000D3O00122O000E000D6O000B000E000200102O000A0014000B00102O000A0004000100202O000B000A002B00202O000B000B001E000620000D0005000100012O00398O002F000B000D000100122O000B00013O00202O000B000B000200122O000C00286O000B0002000200122O000C000C3O00202O000C000C000200122O000D00113O00122O000E000D3O00122O000F00113O00122O0010000D6O000C0010000200102O000B000B000C00122O000C000C3O00202O000C000C000200122O000D00113O00122O000E000D3O00122O000F00113O00122O0010000D6O000C0010000200102O000B0010000C00302O000B001A002C00102O000B0004000100202O000C0009002B00202O000C000C001E000620000E0006000100062O003B8O003B3O00014O00398O003B3O00024O003B3O00034O00393O00084O0003000C000E000100201F000C000B002B002031000C000C001E00022C000E00074O0003000C000E00012O00193O00013O00083O00083O00028O0003083O00506F736974696F6E03053O005544696D322O033O006E657703013O005803053O005363616C6503063O004F2O6673657403013O0059011F3O00121E000100014O0013000200023O002609000100020001000100043A3O0002000100201F00033O00022O003400048O0002000300044O000300013O00122O000400033O00202O0004000400044O000500023O00202O00050005000500202O0005000500064O000600023O00202O00060006000500202O00060006000700202O0007000200054O0006000600074O000700023O00202O00070007000800202O0007000700064O000800023O00202O00080008000800202O00080008000700202O0009000200084O0008000800094O00040008000200102O00030002000400044O001E000100043A3O000200012O00193O00017O00093O00030D3O0055736572496E7075745479706503043O00456E756D030C3O004D6F75736542752O746F6E3103053O00546F756368028O0003083O00506F736974696F6E026O00F03F03073O004368616E67656403073O00436F2O6E65637401223O00200400013O000100122O000200023O00202O00020002000100202O00020002000300062O0001000C0001000200043A3O000C000100201F00013O0001001225000200023O00201F00020002000100201F000200020004000623000100210001000200043A3O0021000100121E000100053O002609000100140001000500043A3O001400012O0016000200016O00025O00201F00023O00064O000200013O00121E000100073O0026090001000D0001000700043A3O000D00012O003B000200033O00201F0002000200064O000200023O00201F00023O000800203100020002000900062000043O000100022O00398O003B8O000300020004000100043A3O0021000100043A3O000D00012O00193O00013O00013O00033O00030E3O0055736572496E707574537461746503043O00456E756D2O033O00456E64000A4O001B7O00206O000100122O000100023O00202O00010001000100202O00010001000300064O00090001000100043A3O000900012O00169O003O00014O00193O00017O00043O00030D3O0055736572496E7075745479706503043O00456E756D030D3O004D6F7573654D6F76656D656E7403053O00546F756368010E3O00200400013O000100122O000200023O00202O00020002000100202O00020002000300062O0001000C0001000200043A3O000C000100201F00013O0001001225000200023O00201F00020002000100201F0002000200040006230001000D0001000200043A3O000D00019O002O00193O00017O00043O00030D3O0055736572496E7075745479706503043O00456E756D030C3O004D6F75736542752O746F6E3103053O00546F75636801113O00200400013O000100122O000200023O00202O00020002000100202O00020002000300062O0001000C0001000200043A3O000C000100201F00013O0001001225000200023O00201F00020002000100201F000200020004000623000100100001000200043A3O001000012O001600018O00016O0013000100016O000100014O00193O00019O002O00010A4O003B00015O0006233O00090001000100043A3O000900012O003B000100013O0006150001000900013O00043A3O000900012O003B000100024O003900026O00210001000200012O00193O00017O00013O0003073O0044657374726F7900044O003B7O0020315O00012O00213O000200012O00193O00017O00073O00028O00026O00F03F03043O004E616D6503073O0044657374726F7903043O005465787403053O007072696E74030D3O00456E7465726564204B65793A2000323O00121E3O00014O0013000100013O0026093O001F0001000200043A3O001F00012O003B00026O0024000300013O00202O0003000300034O000400016O00020004000200062O0002001C00013O00043A3O001C000100121E000200014O0013000300033O0026090002000D0001000100043A3O000D000100121E000300013O002609000300100001000100043A3O001000012O003B000400023O0020350004000400044O0004000200014O000400036O00040001000100044O0031000100043A3O0010000100043A3O0031000100043A3O000D000100043A3O003100012O003B000200044O000F00020001000100043A3O003100010026093O00020001000100043A3O0002000100121E000200013O002609000200260001000200043A3O0026000100121E3O00023O00043A3O00020001002609000200220001000100043A3O002200012O003B000300053O00200100010003000500122O000300063O00122O000400076O000500016O00030005000100122O000200023O00044O0022000100043A3O000200012O00193O00017O00023O00030C3O00736574636C6970626F61726403233O005061737465206865726520796F7572206C696E6B20746F2067657420746865206B657900043O0012253O00013O00121E000100024O00213O000200012O00193O00017O00043O00028O0003053O00706169727303063O00737472696E6703053O006C6F776572021F3O00121E000200013O002609000200010001000100043A3O0001000100121E000300013O002O0E000100040001000300043A3O00040001001225000400024O003B00056O002800040002000600043A3O00180001001225000900033O0020060009000900044O000A00076O00090002000200122O000A00033O00202O000A000A00044O000B8O000A0002000200062O000900180001000A00043A3O00180001000623000800180001000100043A3O001800012O0016000900014O001C000900023O0006260004000A0001000200043A3O000A00012O001600046O001C000400023O00043A3O0004000100043A3O000100012O00193O00017O00053O00028O00026O00F03F03043O0067616D6503073O00482O747047657403053O007063612O6C01233O00121E000100014O0013000200043O0026090001000B0001000200043A3O000B00010006150003000800013O00043A3O000800012O001C000400023O00043A3O002200012O0013000500054O001C000500023O00043A3O00220001002609000100020001000100043A3O0002000100121E000500013O002O0E000200120001000500043A3O0012000100121E000100023O00043A3O000200010026090005000E0001000100043A3O000E0001001225000600033O0020180006000600044O00088O0006000800024O000200063O00122O000600053O00062000073O000100012O00393O00024O002D0006000200074O000400076O000300063O00122O000500023O00044O000E000100043A3O000200012O00193O00013O00013O00013O00030A3O006C6F6164737472696E6700063O00120A3O00016O00019O00000200026O00019O008O00017O00053O00028O0003053O00706169727303063O00737472696E6703053O006C6F77657203043O004E616D6501233O00121E000100014O0013000200023O002609000100020001000100043A3O0002000100121E000200013O002O0E000100050001000200043A3O0005000100121E000300013O002609000300080001000100043A3O00080001001225000400024O003B00056O002800040002000600043A3O001A0001001225000900033O0020330009000900044O000A00076O00090002000200122O000A00033O00202O000A000A000400202O000B3O00054O000A0002000200062O0009001A0001000A00043A3O001A00012O0016000900014O001C000900023O0006260004000E0001000200043A3O000E00012O001600046O001C000400023O00043A3O0008000100043A3O0005000100043A3O0022000100043A3O000200012O00193O00017O000B3O00028O0003053O007072696E7403173O0057686974656C697374656421204C6F6164696E673O2E03043O0077616974026O660240026O00F03F030E3O004C6F6164656420312O302F312O30030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403213O00682O7470733A2O2F706173746562696E2E636F6D2F7261772F505A666964696A72001F3O00121E3O00014O0013000100013O0026093O00020001000100043A3O0002000100121E000100013O0026090001000E0001000100043A3O000E0001001225000200023O001237000300036O00020002000100122O000200043O00122O000300056O00020002000100122O000100063O002609000100050001000600043A3O00050001001225000200023O001210000300076O00020002000100122O000200083O00122O000300093O00202O00030003000A00122O0005000B6O000300056O00023O00024O00020001000100044O001E000100043A3O0005000100043A3O001E000100043A3O000200012O00193O00017O00023O0003043O004B69636B03403O004E6F742057686974656C6973746564207C20496620796F752061726520612062757965722C20616C61726D20404841584E4153206F7220405469736F20E2AD9000054O00177O00206O000100122O000200028O000200016O00017O00", GetFEnv(), ...);
