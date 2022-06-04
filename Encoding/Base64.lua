--[[
	Copyright (C) 2020-2022, AtAltitude, Distributed under MIT License.
	Roblox Profile: https://www.roblox.com/users/1094977/profile
	GitHub Profile: https://github.com/AtAltitude/
	Website: https://www.ataltitude.me/
	
	Functions to encode and decode Base64 strings:
		String b64 = Base64.encode(String binary)
			Returns the Base64-encoded data as a string
		
		String binary = Base64.decode(String b64)
			Returns the binary data contained in the Base64 string as a string
--]]

local Base64 = {}

--Characters to perform encoding
local CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

--Function to encode a string in Base64
function Base64.encode(str)
	--Get length and pre-allocate output array
	local len = #str
	local base64 = {}
	
	--We create a bit output 'stream' and write a Base64 character
	--to the output buffer if it contains more than 6 bits. We use these
	--characters to keep track of that information.
	local tempBits, nBits = 0, 0
	for i = 1, len do
		local byte = string.byte(str, i, i)
		
		--Write 8 bits to the output bit stream
		tempBits = 256*tempBits + byte
		nBits = nBits + 8
		
		--Write Base64 characters until there are less than 6 remaining bits
		while (nBits >= 6) do
			--Get 6 most significant bits
			local factor = math.pow(2, nBits - 6)
			local value  = math.floor(tempBits / factor) + 1
			table.insert(base64, CHARACTERS:sub(value, value))
			
			tempBits = tempBits % factor
			nBits = nBits - 6
		end
	end
	
	--There may be a final character to encode
	if (nBits > 0) then
		--Shift the remaining bits to start at the beginning of the
		--next 6 bit
		local value = tempBits * math.pow(2, 6 - nBits) + 1
		table.insert(base64, CHARACTERS:sub(value, value))
	end
	
	--Pad the string length to a multiple of 4
	if (#base64 % 4 ~= 0) then
		for i = #base64 % 4, 3 do
			table.insert(base64, "=")
		end
	end
	
	return table.concat(base64)
end

--Function to decode a Base64-encoded string
--Function to encode a string in Base64
function Base64.decode(str)
	--Get length and pre-allocate output array
	local len = #str
	local ascii = {}
	
	--We create a bit output 'stream' and write an ASCII character
	--to the output buffer if it contains more than 8 bits. We use these
	--characters to keep track of that information.
	local tempBits, nBits = 0, 0
	for i = 1, len do
		local chr = str:sub(i, i)
		local bits
		
		--We read a "=" character as a 0 when writing to the bit output stream
		if (chr ~= "=") then
			local position = CHARACTERS:find(chr)
			if (position == nil) then
				error("Invalid character '" .. chr .. "' at position " .. i .. " in Base64 string")
			end
			
			bits = position - 1
		else
			bits = 0
		end
		
		--Write 6 bits to the output
		tempBits = 64*tempBits + bits
		nBits = nBits + 6
		
		--Write bytes until there are no full bytes left
		while (nBits >= 8) do
			--Get 8 most significant bits
			local factor = math.pow(2, nBits - 8)
			local value  = math.floor(tempBits / factor)
			table.insert(ascii, string.char(value))
			
			tempBits = tempBits % factor
			nBits = nBits - 8
		end
	end
	
	return table.concat(ascii)
end

return Base64
