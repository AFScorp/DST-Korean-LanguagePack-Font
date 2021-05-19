
local function utf8CodePoint(str, k)
    local c0, c1, c2, c3
    local bytes = 1
    local idx = k * -1
    c0 = string.byte(str,idx,idx)
	
	if c0 == nil then return nil, 0 end                                           --nil value
	
    if c0 ~= nil and c0 >= 128 then                                               --if not then it's 1 Byte char
        c1 = string.byte(str,idx-1,idx-1)
		bytes = bytes + 1
		if c1 >= 128 and c1 < 192 then                                            --if not then it's 2 Byte char
		    c2 = string.byte(str,idx-2,idx-2)
			bytes = bytes + 1
			if c2 >= 128 and c2 < 192 then                                        --if not then it's 3 Byte char
			    c3 = string.byte(str,idx-3,idx-3)
				bytes = bytes + 1
				return (c3-240)*262144+(c2-128)*4096+(c1-128)*64+(c0-128), bytes  --4 Bytes char
			else
			    return (c2-224)*4096+(c1-128)*64+(c0-128), bytes --3 Bytes char
			end
		else
		    return (c1-192)*64+(c0-128), bytes --2 Bytes char
	    end
	else
	    return c0, bytes --1 Byte char
	end
end


--finds first char in the field, from the last character
local function FirstValidChar(keyword)
	local searchpoint = 1
	local firstchar, bytelen
	local isValid
	while true do
	    firstchar, bytelen = utf8CodePoint(keyword, searchpoint)
		searchpoint = searchpoint + bytelen
		if firstchar == nil or
				(firstchar >= 48 and firstchar <= 57) or     --Number Field
				(firstchar >= 65 and firstchar <= 90) or     --Alphabet Uppercase Field
				(firstchar >= 97 and firstchar <= 122) or    --Alphabet Lowercase Field
				(firstchar >= 44032 and firstchar <= 55203) then  --Hangul Syllable Field
		    return firstchar
		end
	end
end

--matchtable = 2459AEHIORSTUZaehiorstuz
--0: no coda
--1: has coda 'ㄹ'
--2: has coda but not 'ㄹ'
local function PPhandler(keyword)
	local matchtable1 = {49, 55, 56, 76, 108}
	local matchtable2 = {
	    48, 51, 54, 66,
		67, 68, 71, 75,
		80, 81, 84, 98,
		99, 100, 103,107,
		112, 113, 116
		}
	local pp
	local firstchar = FirstValidChar(keyword)
	if firstchar ~= nil and (firstchar >= 44032 and firstchar <= 55203) then  --firstchar in Hangul Syllable Field
	    if firstchar % 28 == 16 then  --Hangul has coda-less syllable in every 28 chars
		    return 0
		elseif firstchar % 28 == 24 or firstchar % 28 == 3 then
		    return 1
		else
		    return 2
		end
	else
		return 0
    end
end

local function replacePP(str, pattern, name)
    local pptable = {
	    {'는','은'}, {'가','이'}, {'를','을'},
	    {'와','과'}, {'랑','이랑'}, {'고','이고'},
	    {'야','이야'}, {'여','이여'}, {'랑','이랑'},
		{'다', '이다'}}
	if PPhandler(name) ~= 2 then
	   str = str:gsub(pattern .. "으", pattern .. "")
    end
	if PPhandler(name) ~= 0 then
		for _, v in pairs(pptable) do
		    str = str:gsub(pattern .. v[1], pattern .. v[2])
	    end
	end
	return str
end

return
{
    utf8CodePoint = utf8CodePoint,
	FirstValidChar = FirstValidChar,
	PPhandler = PPhandler,
	replacePP = replacePP
}
