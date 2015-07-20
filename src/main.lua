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
    
  local _metadata = parseLine(table.remove(_lines, 1))
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
  
  --TODO: Create a way to go from these table entries to a struct.  
  --Maybe nest tables.  So entry.wand1.Position.x
  
  local index = 1
  for key,line in pairs(_lines) do
    local t = parseLine(line, sep)
    local e = createLabelledEntry(_labels, t)
    local ee = createNestedEntry(_names, _types, _fields, t)
    if index < 20 then
      printTable(e)      
    end --if
    index = index + 1
    
    table.insert(results,ee)
  end

  return results

end --loadMotiveMocapCSVFile

function createCombinedLabels(names, types, fields)
  local e = {}
  for i, field in ipairs(fields) do
    local name = names[i]
    local type = types[i]
    e[i] = name..'-'..type..'-'..field 
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
     print(k,v)
  end
end --printTable

loadMotiveMocapCSVFile("../mocap_test/test01.csv")