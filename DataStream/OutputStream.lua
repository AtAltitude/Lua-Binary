--[[
	Copyright (C) 2020-2022, AtAltitude, Distributed under MIT License.
	Profile: https://www.roblox.com/users/1094977/profile
	
	Utility to create OutputStream-like behavior from a string of data
	
	Constructors:
		OutputStream stream = OutputStream.new(string data, table? options)
			Returns an OutputStream representing the data in 'data'.
			
			Options is an optional table with the following fields:
				- CalculateCRC32: A boolean that determines whether or not a CRC32 should be calculated as data is written 
				                  to the stream.
			
	Methods:
		nil = OutputStream:write(string data)
			Writes the string to the end of the stream.
		
		nil = OutputStream:writeByte(unsigned int n)
			Writes a value in range [0, 255] to the end of the stream as one byte.
		
		nil = OutputStream:writeShort(unsigned int n)
			Writes a value in range [0, 65535] to the end of the stream as 2 bytes.
		
		nil = OutputStream:writeInt(unsigned int n)
			Writes a value in range [0, 4294967295] to the end of the stream as 4 bytes.
		
		nil = OutputStream:writeFloat(number n)
			Writes a number to the end of the stream as 4 bytes.
		
		nil = OutputStream:writeDouble(number n)
			Writes a number to the end of the stream as 8 bytes.
		
		nil = OutputStream:resetCRC32()
			Resets the CRC on the stream to 0.
		
		nil = OutputStream:writeCRC32()
			Writes the current CRC32 to the end of the stream as 4 bytes.
		
		string out = OutputStream:toString()
			Returns the data written to the stream as a string.
--]]


--OutputStream class setup
local OutputStream = {}
OutputStream.__index = OutputStream

--Module dependencies
local CRC32  = require(script.Parent.CRC32)
local Binary = require(script.Parent.Parent.Encoding.Binary)

--Constructor
function OutputStream.new(options)
	return setmetatable({
		Data    = {};
		Length  = 0;
		CRC32   = 0;
		Options = options or {};
	}, OutputStream)
end

--Method to write some binary string
function OutputStream:write(data)
	table.insert(self.Data, tostring(data))
	self.Length = self.Length + #data
	
	if (self.Options.CalculateCRC32) then
		self.CRC32 = CRC32.crc32(data, self.CRC32)
	end
end

--Methods to write discrete data types
function OutputStream:writeByte(n)   self:write(Binary.encodeInt(n, 1)) end
function OutputStream:writeShort(n)  self:write(Binary.encodeInt(n, 2)) end
function OutputStream:writeInt(n)    self:write(Binary.encodeInt(n, 4)) end
function OutputStream:writeFloat(n)  self:write(Binary.encodeFloat(n))  end
function OutputStream:writeDouble(n) self:write(Binary.encodeDouble(n)) end

--Method to reset the calculated CRC32
function OutputStream:resetCRC32()
	assert(self.Options.CalculateCRC32, "CRC32 is not enabled")
	self.CRC32 = 0
end

--Method to write a CRC32 to the stream
function OutputStream:writeCRC32()
	assert(self.Options.CalculateCRC32, "CRC32 is not enabled")
	table.insert(self.Data, Binary.encodeInt(self.CRC32, 4))
	self.Length = self.Length + 4
end

--Method to get the raw data
function OutputStream:toString()
	return table.concat(self.Data)
end

--Output API
return OutputStream
