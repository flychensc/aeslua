require("bit");

local public = {};
local private = {};

aeslua.util = public;

--
-- calculate the parity of one byte
--
function public.byteParity(byte)
    byte = bit.bxor(byte, bit.rshift(byte, 4));
    byte = bit.bxor(byte, bit.rshift(byte, 2));
    byte = bit.bxor(byte, bit.rshift(byte, 1));
    return bit.band(byte, 1);
end

-- 
-- get byte at position index
--
function public.getByte(number, index)
    if (index == 0) then
        return bit.band(number,0xff);
    else
        return bit.band(bit.rshift(number, index*8),0xff);
    end
end


--
-- put number into int at position index
--
function public.putByte(number, index)
    if (index == 0) then
        return bit.band(number,0xff);
    else
        return bit.lshift(bit.band(number,0xff),index*8);
    end
end

--
-- convert byte array to int array
--
function public.bytesToInts(bytes, start, n)
    local ints = {};
    for i = 0, n - 1 do
        ints[i] = public.putByte(bytes[start + (i*4)    ], 3)
                + public.putByte(bytes[start + (i*4) + 1], 2) 
                + public.putByte(bytes[start + (i*4) + 2], 1)    
                + public.putByte(bytes[start + (i*4) + 3], 0);
    end
    return ints;
end

--
-- convert int array to byte array
--
function public.intsToBytes(ints, output, outputOffset, n)
    n = n or #ints;
    for i = 0, n do
        for j = 0,3 do
            output[outputOffset + i*4 + (3 - j)] = public.getByte(ints[i], j);
        end
    end
    return output;
end

--
-- convert bytes to hexString
--
function private.bytesToHex(bytes)
    local hexBytes = "";
    
    for i,byte in ipairs(bytes) do 
        hexBytes = hexBytes .. string.format("%02x ", byte);
    end

    return hexBytes;
end

--
-- convert data to hex string
--
function public.toHexString(data)
    local type = type(data);
    if (type == "number") then
        return string.format("%08x",data);
    elseif (type == "table") then
        return private.bytesToHex(data);
    elseif (type == "string") then
        local bytes = {string.byte(data, 1, #data)}; 

        return private.bytesToHex(bytes);
    else
        return data;
    end
end

function public.padByteString(data)
    local dataLength = #data;

    local paddingLength = math.floor( (#data+16)/16) *16 - #data;
    local padding = "";
    for i=1,paddingLength do
        padding = padding .. string.char(paddingLength);
    end 

    return data .. padding;
end

function private.properlyDecrypted(data)
    local paddingLength = string.byte(data,#data,#data);
    if paddingLength == 0 then
        return false
    end
    
    local padding = {string.byte(data,#data-paddingLength+1,#data)};
    if paddingLength ~= #padding then
        return false
    end

    for i=1,#padding do
        if paddingLength ~= padding[i] then
            return false;
        end
    end
    
    return true;
end

function public.unpadByteString(data)
    if (not private.properlyDecrypted(data)) then
        return nil;
    end
    
    local paddingLength = string.byte(data,#data,#data);
    
    return string.sub(data,1,#data-paddingLength);
end

function public.xorIV(data, iv)
    for i = 1,16 do
        data[i] = bit.bxor(data[i], iv[i]);
    end 
end

return public;