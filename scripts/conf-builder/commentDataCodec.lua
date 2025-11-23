-- simple data codec that can be stored in the header of an mpv conf file in comments

local CommentDataCodec = {}

local function Trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Trims only the right side (to detect backslashes even if there is invisible trailing whitespace)
local function TrimRight(s)
	return (s:gsub("%s*$", ""))
end

local function ParseValue(v)
	local num = tonumber(v)
	if num then return num end
	if v == "true" then return true end
	if v == "false" then return false end
	return v
end

-- Helper to handle the backslash logic
-- Returns: ProcessedContent, IsContinuation
local function ProcessStringLine(text)
	-- Remove trailing whitespace so we can find the backslashes
	text = TrimRight(text)
	
	-- Count the number of consecutive backslashes at the end
	local backslashes = text:match("([\\]*)$") or ""
	local count = #backslashes
	local isContinuation = false

	-- If odd, the last one is the continuation marker
	if count % 2 == 1 then
		isContinuation = true
		count = count - 1
	end

	-- Get the text before the trailing backslashes
	local content = text:sub(1, #text - #backslashes)

	-- The remaining backslashes are pairs (literals).
	-- We unescape them (halve the count) for the final value.
	-- e.g., "\\\\" (4) -> "\\" (2)
	local suffix = string.rep("\\", count / 2)

	return content .. suffix, isContinuation
end

function CommentDataCodec.Parse(content)
	local result = {}
	local stack = {result}
	local inMetadata = false
	
	-- State for multiline strings
	local inString = false
	local currentKey = nil
	local stringBuffer = ""
	
	for line in content:gmatch("([^\r\n]*)\r?\n?") do
		-- Only process comment lines
		local commentContent = line:match("^%s*#(.*)")
		
		if commentContent then
			-- Handle Multiline Strings
			if inString then
				-- We do not Trim() the start to preserve indentation in the string,
				-- but we use ProcessStringLine which Trims the end.
				local processedPart, continues = ProcessStringLine(commentContent)
				
				if continues then
					stringBuffer = stringBuffer .. processedPart .. "\n"
				else
					stringBuffer = stringBuffer .. processedPart
					
					-- Finish string assignment
					local currentTable = stack[#stack]
					currentTable[currentKey] = ParseValue(stringBuffer)
					
					-- Reset state
					inString = false
					stringBuffer = ""
					currentKey = nil
				end

			-- Handle Structure
			else
				local cleanLine = Trim(commentContent)
				
				if not inMetadata then
					if cleanLine == "metadata" then
						inMetadata = true
					end
				else
					if cleanLine == "end" then
						table.remove(stack)
						if #stack == 0 then break end
					elseif cleanLine ~= "" then
						local key, value = cleanLine:match("^([^=]+)=(.*)")
						
						if key then
							key = Trim(key)
							value = Trim(value)
							
							local processedPart, continues = ProcessStringLine(value)
							
							if continues then
								inString = true
								currentKey = key
								stringBuffer = processedPart .. "\n"
							else
								local currentTable = stack[#stack]
								currentTable[key] = ParseValue(processedPart)
							end
						else
							-- No equals sign implies new nested table
							local newTable = {}
							local currentTable = stack[#stack]
							currentTable[cleanLine] = newTable
							table.insert(stack, newTable)
						end
					end
				end
			end
		end
	end

	return result
end

return CommentDataCodec