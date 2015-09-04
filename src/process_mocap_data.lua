function loadDelimetedTextFile(filename, sep)
  if not fileExists(filename) then 
    print(filename .. "was not found")
    return {}
  end
    
  for line in io.lines(filename) do
    print(parseLine(line, sep))
  end
end --loadDelimitedTextFile

function fileExists(filename)
  local f = io.open(filename, "r")
  if f then f:close() end
  return f ~= nil
end --fileExists

function parseLine (line,sep) 
  local res = {}
  local pos = 1
  sep = sep or ','
  while true do 
    local c = string.sub(line,pos,pos)
    if (c == "") then break end
    if (c == '"') then
      -- quoted value (ignore separator within)
      local txt = ""
      repeat
        local startp,endp = string.find(line,'^%b""',pos)
        txt = txt..string.sub(line,startp+1,endp-1)
        pos = endp + 1
        c = string.sub(line,pos,pos) 
        if (c == '"') then txt = txt..'"' end 
        -- check first char AFTER quoted string, if it is another
        -- quoted string without separator, then append it
        -- this is the way to "escape" the quote char in a quote. example:
        --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
      until (c ~= '"')
      table.insert(res,txt)
      assert(c == sep or c == "")
      pos = pos + 1
    else  
      -- no quotes used, just look for the first separator
      local startp,endp = string.find(line,sep,pos)
      if (startp) then 
        table.insert(res,string.sub(line,pos,startp-1))
        pos = endp + 1
      else
        -- no separator found -> use rest of string and terminate
        table.insert(res,string.sub(line,pos))
        break
      end 
    end
  end
  return res
end

function loadMotiveMocapCSVFile(filename)
  --first line is metadata
  --second line is blank
  --third line is labels
  --rest is data
  
  local results = {}
  
  if not fileExists(filename) then 
    print(filename .. "was not found")
    return {}
  end
  
  local _lines = {}
  for line in io.lines(filename) do
    --_lines[#_lines+1] = line --lua 5.1
    table.insert(_lines, line) -- will insert at end
  end
    
  local _metadata = parseMetaData(parseLine(table.remove(_lines, 1)))
  local _gap = table.remove(_lines,1)
  local _types = parseLine(table.remove(_lines,1))
  local _names = parseLine(table.remove(_lines,1))
  local _hashes = parseLine(table.remove(_lines,1))
  local _types = parseLine(table.remove(_lines,1))
  local _fields = parseLine(table.remove(_lines,1))
  
  
  --printTable(_metadata,"")
  --printTable(_names,"")
  --printTable(_types,"")
  --printTable(_fields,"")
  
  local _labels = createCombinedLabels(_names, _types, _fields)
  
  --printTable(_labels,"")

  local index = 1
  for key,line in pairs(_lines) do
    local t = parseLine(line, sep)
    local e = createLabelledEntry(_labels, t)
    if index < 20 then
      --printTable(e,"")      
    end --if
    index = index + 1
    
    table.insert(results,e)
  end

  return _metdata, _labels,  results

end --loadMotiveMocapCSVFile

function parseMetaData(data)
	--metdata is field,data,field,data
	local d = {}
	local d_len = #data
	if d_len % 2 ~= 0 then 
	 print("Metadata is not in pairs")
	 return d
  end
  
  for i = 1, d_len, 2 do
    d[data[i]] = data[i+1]
  end
  
  return d

end--parseMetaData

function createCombinedLabels(names, types, fields)
  local e = {}
  for i, field in ipairs(fields) do
    local name = names[i]
    local type = types[i]
    if name ~= "" and type ~= "" then
      e[i] = trim(name..'.'..type..'.'..field)
    else
      e[i] = trim(field)
    end
  end--for

  return e
end --createLabelledEntry

function createNestedEntry(names, types, fields, sample)
  local e = {}
  for i, field in ipairs(fields) do
    local name = names[i]
    local type = types[i]
    local d = sample[i]
    
    local nameEntry = {}
    --find if name entry already exists
    if(e[name]) then
      nameEntry = e[name]
    else
      e[name] = nameEntry 
    end
    
    
    --find if name already has type
    local typeEntry = {}
    if (nameEntry[type]) then
      typeEntry = nameEntry[type]
    end
    
    typeEntry[field] = d      
    nameEntry[type] = typeEntry
    --table.insert(e,tmp)
  end--for

  return e
end --createLabelledEntry

function createLabelledEntry(labels, entry)
  local e = {}
  for i, label in ipairs(labels) do
    local d = entry[i]
    local tmp = {}
    e[label] = d 
    --table.insert(e,tmp)
  end--for

  return e
end --createLabelledEntry

function printTable(t,sep)
  for k,v in pairs(t) do
     if type(v) == "table" then
       io.write(sep)
       io.write(k)
       io.write("\n")
       io.write(printTable(v, sep.."."))
     else
       io.write(sep)
       io.write(k.." "..v)
       io.write("\n")
     end-- if
  end
end --printTable

function safePrint(value, sep, default)
  if value ~= nil then
    io.write(tostring(value).. sep)
    return true
  else 
    io.write(default)
    return false
  end
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function writeDataToFile(filename, metadata, labels, data)
  local file
  if(filename ~= nil) then
    file = io.open(filename, "w")
    io.output(file)
  end
  --output fieldnames
  for label_index,label in pairs(labels) do
    io.write(label.."\t")
  end--for
  io.write("valid");
  io.write("\n")

    
  local count = 0
  local def = "0.0"
  local sep = "\t"
  for line,record_data in ipairs(data) do
      local complete = true
      for label_index,label in pairs(labels) do
        --io.write(label.."\t")
        local c = safePrint(record_data[label], sep , def)
        if(c == false) then
          complete = false
        end -- if(c...
      end--for
    if( complete == false ) then
      io.write("\tfalse")
    else
      io.write("\ttrue")
    end--if(comple 

    io.write("\n")
    count = count + 1
  end --for
  if(filename ~= nil) then
    io.close(file)
  end

end--writeDataToFile

metadata_,labels_, data_ = loadMotiveMocapCSVFile("../mocap_test/test01.csv")
writeDataToFile(arg[1], metadata_, labels_, data_)

