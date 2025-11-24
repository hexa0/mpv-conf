return function(sourceString)
	assert(type(sourceString) == "string", "must be a string")

	return sourceString:gsub("([%\\\"$`])", "\\%1")
end