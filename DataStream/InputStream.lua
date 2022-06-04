--[[
	Copyright (C) 2020-2022, AtAltitude, Distributed under MIT License.
	Roblox Profile: https://www.roblox.com/users/1094977/profile
	GitHub Profile: https://github.com/AtAltitude/
	Website: https://www.ataltitude.me/
	
	Utility to create InputStream-like behavior from a string of data
	
	Constructors:
		InputStream stream = InputStream.new(string data, table? options)
			Returns an InputStream representing the data in 'data'.
			
			Options is an optional table with the following fields:
				- CalculateCRC32: A boolean that determines whether or not a CRC32 should be calculated as data is read 
				                  from the stream.
			
	Methods:
		String out = InputStream:read(int nBytes)
			Reads 'nBytes' bytes from the stream and returns them as a string, and advances the stream position.
		
		unsigned int out = InputStream:readByte()
			Reads one byte from the stream and returns it as an unsigned integer, and advances the stream position.
		
		unsigned int out = InputStream:readShort()
			Reads 2 bytes from the stream and returns them as an unsigned integer, and advances the stream position.
		
		unsigned int out = InputStream:readInt()
			Reads 4 bytes from the stream and returns them as an unsigned integer, and advances the stream position.
		
		number out = InputStream:readFloat()
			Reads 4 bytes from the stream and returns them as number, and advances the stream position.
		
		number out = InputStream:readDouble()
			Reads 8 bytes from the stream and returns them as number, and advances the stream position.
		
		String out = InputStream:lookAhead(int nBytes)
			Reads 'nBytes' bytes from the stream and returns them as a string, without advancing the stream position.
		
		nil = InputStream:skip(int nBytes)
			Advances the stream position by 'nBytes' bytes, but doesn't return them.
		
		nil = InputStream:jumpBack(int nBytes)
			Decreases the stream position by 'nBytes' bytes.
		
		boolean hasData = InputStream:hasData()
			Returns true if the stream has at least 1 byte of data left, false otherwise.
		
		unsigned int available = InputStream:available()
			Returns the number of bytes left on the stream.
		
		nil = InputStream:setName(string name)
			Sets the name of the InputStream, used for debugging purposes.
		
		nil = InputStream:checkCRC32()
			Reads 4 bytes from the stream, advances the stream position, and compares the value read to the CRC32 calculated
			from the returned data. Errors if the CRC doesn't match.
		
		nil = InputStream:resetCRC32()
			Resets the CRC on the stream to 0.
--]]


--InputStream class setup
local InputStream = {}
InputStream.__index = InputStream

--Module dependencies
local CRC32  = require(script.Parent.CRC32)
local Binary = require(script.Parent.Parent.Encoding.Binary)

--Constructor
function InputStream.new(data, options)
	options = options or {}
	
	return setmetatable({
		Data     = data;
		Position = 1;
		Options  = options;
		CRC32    = 0;
		Name     = options.Name;
	}, InputStream)
end

--Method to read a given number of bytes
function InputStream:read(nBytes)
	--Return nil if we've reached the end of the InputStream
	if (self.Position > #self.Data) then return nil end
	
	--Return data and increment position
	local out = self.Data:sub(self.Position, self.Position+(nBytes-1))
	self.Position = self.Position + nBytes
	
	--Update CRC32 if needed
	if (self.Options.CalculateCRC32) then
		self.CRC32 = CRC32.crc32(out, self.CRC32)
	end
	
	return out
end

--Method to read a given number of bytes without stepping ahead
function InputStream:lookAhead(nBytes)
	--Return nil if we've reached the end of the InputStream
	if (self.Position > #self.Data) then return nil end
	
	--Return data and increment position
	local out = self.Data:sub(self.Position, self.Position+(nBytes-1))
	return out
end

--Method to skip a given number of bytes
function InputStream:skip(nBytes)
	self.Position = self.Position + nBytes
end

--Method to jump back a number of bytes
function InputStream:jumpBack(nBytes)
	self.Position = math.max(self.Position - nBytes, 1)
end

--Read numeric values
function InputStream:readByte(littleEndian)   return Binary.decodeInt   (self:read(1), littleEndian) end
function InputStream:readShort(littleEndian)  return Binary.decodeInt   (self:read(2), littleEndian) end
function InputStream:readInt(littleEndian)    return Binary.decodeInt   (self:read(4), littleEndian) end
function InputStream:readFloat(littleEndian)  return Binary.decodeFloat (self:read(4), littleEndian) end
function InputStream:readDouble(littleEndian) return Binary.decodeDouble(self:read(8), littleEndian) end

--Method to check if we have data
function InputStream:hasData()
	return self.Position <= #self.Data
end

--Method to check how many bytes are available
function InputStream:available()
	return (#self.Data - self.Position) + 1
end

--Method to reset the CRC32
function InputStream:resetCRC32()
	self.CRC32 = 0
end

--Method to check the CRC32
function InputStream:checkCRC32()
	--Get data block name
	local name = self.Name or "Unnamed Block"
	
	--Error if CRC32 calculations are not enabled on this stream
	if (not self.Options.CalculateCRC32) then error("Cannot check CRC32 in block '" .. name .. "': CRC32 not enabled") end
	
	--Error if we've reached the end of the InputStream
	if (self.Position > #self.Data) then error("Cannot check CRC32 in block '" .. name .. "': End of stream") end

	--Return data and increment position
	local out = self.Data:sub(self.Position, self.Position+3)
	self.Position = self.Position + 4
	
	--Check CRC32
	local crc = Binary.decodeInt(out)
	assert(crc == self.CRC32, "CRC32 mismatch in block '" .. name .. "': " .. crc .. " ~= " .. self.CRC32)
end

--Method to set a new name for the stream
function InputStream:setName(name)
	self.Name = name
end

--Output API
return InputStream
