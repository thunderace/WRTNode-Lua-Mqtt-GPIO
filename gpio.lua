--@author: Ewelina, Rafa, Rafa
--GPIO utilities

--Writes 'what' to 'where'
function writeToFile (where,what)
  local fileToWrite=io.open(where, 'w')
  fileToWrite:write(what)
  fileToWrite:close()	
end
--Reads a character from file 'where' and returns the string
function readFromFile (where)
  local fileToRead=io.open(where, 'r')
  if fileToRead~=nil then
    fileStr = fileToRead:read(1)
    fileToRead:close()
    return fileStr
  end
  return nil
end

--Returns true if file exists
function file_exists(name)
  local f=io.open(name,"r")
  if f~=nil then io.close(f) return true else return false end
end

--Exports gpio ID to use as an output pin
function configureOutGPIO (id)
  if file_exists('/sys/class/gpio/gpio'..id..'/direction') then
    writeToFile('/sys/class/gpio/unexport',id)
  end
  writeToFile('/sys/class/gpio/export',id)
  writeToFile('/sys/class/gpio/gpio'..id..'/direction','out')
end

--Exports gpio ID to use as an input pin
function configureInGPIO (id)
  if file_exists('/sys/class/gpio/gpio'..id..'/direction') then
    writeToFile('/sys/class/gpio/unexport',id)
  end
  writeToFile('/sys/class/gpio/export',id)
  writeToFile('/sys/class/gpio/gpio'..id..'/direction','in')
end

--Reads GPIO 'id' and returns it's value
--@Pre: GPIO 'id' must be exported with configureInGPIO
function readGPIO(id)
  gpioVal = readFromFile('/sys/class/gpio/gpio'..id..'/value')
  return gpioVal
end

--Writes a value to GPIO 'id'
--@Pre: GPIO 'id' must be exported with configureOutGPIO
function writeGPIO(id, val)
  gpioVal = writeToFile('/sys/class/gpio/gpio'..id..'/value', val)
end

function sleep(n)
  os.execute("sleep " .. tonumber(n))
end

--  examples
-- input
-- require ("gpio") --import library
-- configureInGPIO (83) --configure input gpio
-- local val = readGPIO(83) --read the value of the pin

-- output
-- require ("gpio") -- import library
-- configureOutGPIO (83) -- configure input gpio
-- writeGPIO(83,1) -- write the value to the pin
-- writeGPIO(83,0)

