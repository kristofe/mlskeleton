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

function loadMotiveMocapCSVFile(filename, nestLabels)
  --first line is metadata
  --second line is blank
  --third line is labels
  --rest is data
  
  local results = {}
  local useLableNesting = nestLabels or 0
  
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
  
  
  printTable(_metadata)
  printTable(_names)
  printTable(_types)
  printTable(_fields)
  
  local _labels = createCombinedLabels(_names, _types, _fields)
  
  printTable(_labels)

  local index = 1
  for key,line in pairs(_lines) do
    local t = parseLine(line, sep)
    local e = {}
    if useLabelNesting then
      e = createLabelledEntry(_labels, t)
    else
      e = createNestedEntry(_names, _types, _fields, t)
    end
    if index < 20 then
      --printTable(e)      
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
  
  for k,v in pairs(d) do
    print(k,v)
  end
  
  return d

end--parseMetaData

function createCombinedLabels(names, types, fields)
  local e = {}
  for i, field in ipairs(fields) do
    local name = names[i]
    local type = types[i]
    e[i] = name..'.'..type..'.'..field 
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
  --TODO:This can be modified so the it is nested. So 
  local e = {}
  for i, label in ipairs(labels) do
    local d = entry[i]
    local tmp = {}
    e[label] = d 
    --table.insert(e,tmp)
  end--for

  return e
end --createLabelledEntry

function printTable(t)
  for k,v in pairs(t) do
     if type(v) == "table" then
       print(k)
       print(printTable(v))
     else
       print(k,v)
     end-- if
  end
end --printTable

function safePrint(value, sep, default)
  if value ~= nil then
    io.write(tostring(value).. sep)
    return false
  else 
    io.write(default)
    return true
  end
end


function writeDataToFile(filename, metadata, labels, data)
  --output fieldnames
  for label_index,label in pairs(labels) do
    io.write(label.."\t")
  end--for
  io.write("\n")

  --Now output data
  --TODO: Make the markername order be the same as above.  Use the above loop as a lookup
  --FIXME: The fields don't match the first line label output.  Fix
  local count = 0
  local def = "0.0"
  local sep = "\t"
  for record_key,record_data in pairs(data) do
    if count < 10 then 
      local missing_data = false
      io.write(record_key .. "\t")--write record number
      --now write each field 
      --get name
      for marker_name, marker_data in pairs(record_data) do
        --io.write(marker_name .. "\t")
        if marker_data.Rotation ~= nil then
          missing_data = missing_data or safePrint(marker_data.Rotation.X, sep, def)
          missing_data = missing_data or safePrint(marker_data.Rotation.Y, sep, def)
          missing_data = missing_data or safePrint(marker_data.Rotation.Z, sep, def)
          missing_data = missing_data or safePrint(marker_data.Rotation.W, sep, def)
        end
        if marker_data.Position ~= nil then
          missing_data = missing_data or safePrint(marker_data.Position.X, sep, def)
          missing_data = missing_data or safePrint(marker_data.Position.Y, sep, def)
          missing_data = missing_data or safePrint(marker_data.Position.Z, sep, def)
        end
      end --for marker_name

      io.write(tostring(missing_data))
      io.write("\n")
    end -- count
    count = count +1
  end--for

end--writeDataToFile

metadata_,labels_, data_ = loadMotiveMocapCSVFile("../mocap_test/test01.csv")
print("---------")
writeDataToFile("mocap_data_cleaned.txt", metadata_, labels_, data_)

