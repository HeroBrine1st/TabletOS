  local rom = {}
  function rom.invoke(method, ...)
    return component.invoke(computer.getBootAddress(), method, ...)
  end
  function rom.open(file) return rom.invoke("open", file) end
  function rom.read(handle) return rom.invoke("read", handle, math.huge) end
  function rom.close(handle) return rom.invoke("close", handle) end
  function rom.inits() return ipairs(rom.invoke("list", "boot")) end
  function rom.isDirectory(path) return rom.invoke("isDirectory", path) end

  local function loadfile(file)
    local handle, reason = rom.open(file)
    if not handle then
      error(reason)
    end
    local buffer = ""
    repeat
      local data, reason = rom.read(handle)
      if not data and reason then
        error(reason)
      end
      buffer = buffer .. (data or "")
    until not data
    rom.close(handle)
    return load(buffer, "=" .. file)
  end

  local function dofile(file)
    local program, reason = loadfile(file)
    if program then
      local result = table.pack(pcall(program))
      if result[1] then
        return table.unpack(result, 2, result.n)
      else
        error(result[2])
      end
    else
      error(reason)
    end
  end


local function pullFilteredSignal(signal)
  while true do
    local signalA = {computer.pullSignal()}
    if signalA[1] == signal then return table.unpack(signalA) end
  end
end
local initSuccess, initReason
if not computer.pullSignal(1) then
initSuccess, initReason = pcall(loadfile("/boot.lua"))
end

local gpu = component.proxy(component.list("gpu")())
gpu.set(1,1,"Press again for enter to fastboot menu")
if not computer.pullSignal(1) then
gpu.set(1,2,"Booting kernel")
initSuccess, initReason = pcall(loadfile("/boot.lua"))
end



local success, reason = pcall(function()
  filesystem = component.proxy(computer.getBootAddress())
  
  local screen = component.list("screen")()
  gpu.bind(screen)
  local w, h = gpu.getResolution()
  fastboot = {}
  --setup fastboot logging
  fastboot.cursor = 3
  fastboot.print = function(msg)
    gpu.set(1,fastboot.cursor,msg)
    if fastboot.cursor == h then 
      gpu.copy(1,2,w,h-1,0,-1) 
      gpu.fill(1,h,w,h," ") 
    else 
      fastboot.cursor = fastboot.cursor + 1 
    end
    if msg:len() > w then
      fastboot.print(msg:sub(w+1))
    end
  end
  fastboot.keys = {
  ["1"]           = 0x02,
  ["2"]           = 0x03,
  ["3"]           = 0x04,
  ["4"]           = 0x05,
  ["5"]           = 0x06,
  ["6"]           = 0x07,
  ["7"]           = 0x08,
  ["8"]           = 0x09,
  ["9"]           = 0x0A,
  ["0"]           = 0x0B,
  a               = 0x1E,
  b               = 0x30,
  c               = 0x2E,
  d               = 0x20,
  e               = 0x12,
  f               = 0x21,
  g               = 0x22,
  h               = 0x23,
  i               = 0x17,
  j               = 0x24,
  k               = 0x25,
  l               = 0x26,
  m               = 0x32,
  n               = 0x31,
  o               = 0x18,
  p               = 0x19,
  q               = 0x10,
  r               = 0x13,
  s               = 0x1F,
  t               = 0x14,
  u               = 0x16,
  v               = 0x2F,
  w               = 0x11,
  x               = 0x2D,
  y               = 0x15,
  z               = 0x2C,

  ["/"]      = 0x28,
  at              = 0x91,
  back            = 0x0E, -- backspace
  ["\\"]       = 0x2B,
  capital         = 0x3A, -- capslock
  colon           = 0x92,
  comma           = 0x33,
  enter           = 0x1C,
  equals          = 0x0D,
  grave           = 0x29, -- accent grave
  lbracket        = 0x1A,
  lcontrol        = 0x1D,
  lmenu           = 0x38, -- left Alt
  lshift          = 0x2A,
  minus           = 0x0C,
  numlock         = 0x45,
  pause           = 0xC5,
  period          = 0x34,
  rbracket        = 0x1B,
  rcontrol        = 0x9D,
  rmenu           = 0xB8, -- right Alt
  rshift          = 0x36,
  scroll          = 0x46, -- Scroll Lock
  semicolon       = 0x27,
  slash           = 0x35, -- / on main keyboard
  space           = 0x39,
  stop            = 0x95,
  tab             = 0x0F,
  underline       = 0x93,

  -- Keypad (and numpad with numlock off)
  up              = 0xC8,
  down            = 0xD0,
  left            = 0xCB,
  right           = 0xCD,
  home            = 0xC7,
  ["end"]         = 0xCF,
  pageUp          = 0xC9,
  pageDown        = 0xD1,
  insert          = 0xD2,
  delete          = 0xD3,

  -- Function keys
  f1              = 0x3B,
  f2              = 0x3C,
  f3              = 0x3D,
  f4              = 0x3E,
  f5              = 0x3F,
  f6              = 0x40,
  f7              = 0x41,
  f8              = 0x42,
  f9              = 0x43,
  f10             = 0x44,
  f11             = 0x57,
  f12             = 0x58,
  f13             = 0x64,
  f14             = 0x65,
  f15             = 0x66,
  f16             = 0x67,
  f17             = 0x68,
  f18             = 0x69,
  f19             = 0x71,

  -- Japanese keyboards
  kana            = 0x70,
  kanji           = 0x94,
  convert         = 0x79,
  noconvert       = 0x7B,
  yen             = 0x7D,
  circumflex      = 0x90,
  ax              = 0x96,

  -- Numpad
  numpad0         = 0x52,
  numpad1         = 0x4F,
  numpad2         = 0x50,
  numpad3         = 0x51,
  numpad4         = 0x4B,
  numpad5         = 0x4C,
  numpad6         = 0x4D,
  numpad7         = 0x47,
  numpad8         = 0x48,
  numpad9         = 0x49,
  numpadmul       = 0x37,
  numpaddiv       = 0xB5,
  numpadsub       = 0x4A,
  numpadadd       = 0x4E,
  numpaddecimal   = 0x53,
  numpadcomma     = 0xB3,
  numpadenter     = 0x9C,
  numpadequals    = 0x8D,
}

-- Create inverse mapping for name lookup.
do
  local keys = {}
  for k in pairs(fastboot.keys) do
    table.insert(keys, k)
  end
  for _, k in pairs(keys) do
    fastboot.keys[fastboot.keys[k]] = k
  end
end
  fastboot.read = function()
  local str = ""
    while true do
      local key = {pullFilteredSignal("key_down")}
      if fastboot.keys[key[4]] == "back" then 
        str = string.sub(str,1,string.len(str)-1) 
      elseif fastboot.keys[key[4]] == "enter" then 
        fastboot.cursor = fastboot.cursor + 1 
        return str 
      else
        str = str .. fastboot.keys[key[4]]
      end
      gpu.fill(1,fastboot.cursor,w,fastboot.cursor," ")
      gpu.set(1,fastboot.cursor,str)
    end
  end
  fastboot.print("Booting fastboot")
  if not initSuccess and initReason then fastboot.print("Boot.lua has crashed. Reason:" .. initReason) end
  local modemAddress = component.list("modem")()
  local modem
  if modemAddress and component.invoke(modemAddress,"isWireless") then modem = component.proxy(modemAddress) else fastboot.print("Not available component modem (Wireless network card)") while true do computer.pullSignal(0.5) computer.beep(1000,0.4) end end 
  local port = math.floor(math.random()*math.pow(2,15))
  modem.open(port)
  fastboot.print("Port: " .. tostring(port))
  fastboot.print("Fastboot state: unlocked")
  fastboot.print("Wait computer command")
 
  while true do
   local signal = {pullFilteredSignal("modem_message")}
   local success, reason = pcall(load(signal[6],"=message"))
   if not success then fastboot.print(reason) end
   fastboot.print("Wait computer command")
 end
end)

if not success then error(reason) end