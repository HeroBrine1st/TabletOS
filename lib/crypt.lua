--[[ Алгоритм шифрования-дешифрования на основе сети Фейстеля
     Created by Dimus
     No rights reserved ]]

--[[ Нахождение хеш-функции по алгоритму md5
   *Apokalypsys, Dimus
   *http://minecrafting.ru/forum/viewtopic.php?f=32&t=5331
]]

local bit = require("bit32")
local hex_char = "0123456789abcdef"
local crypt = {}
local function getHex(seed)
   local str = ""
   for i = 0, 3 do
      local ind1, ind2 = bit.band(bit.rshift(seed, i * 8 + 4), 15) + 1, bit.band(bit.rshift(seed, i * 8), 15) + 1
      str = str..
      hex_char:sub(ind1, ind1)..
      hex_char:sub(ind2, ind2)
   end
   return str
end

local function string_to_blks(str)
   local nblk = bit.rshift((str:len() + 8), 6) + 1
   local blks = {}
   local len = str:len()
   for i = 0, nblk * 16 - 1 do
      blks[i] = 0
   end
   for i = 0, str:len() - 1 do
      blks[bit.rshift(i, 2)] =
      bit.bor(
         blks[bit.rshift(i, 2)],
         bit.lshift(
            str:byte(i+1),
             (((i) % 4) * 8)
          )
      )
   end
      blks[bit.rshift(len, 2)] =
      bit.bor(
         blks[bit.rshift(len, 2)],
         bit.lshift(
            128,
            (((len) % 4) * 8)
         )
      )
      blks[nblk * 16 - 2] = len * 8
   return blks
end

local function add(x, y)
   return x + y > 4294967296 and x + y or x + y - 4294967296
end

local function rol(number, count)
   return bit.bor(bit.lshift(number, count), bit.rshift(number, (32 - count)))
end

local function X(a, b, c, x, s, t)
   return add(rol(add(add(b, a), add(x, t)), s), c)
end

local function F(a, b, c, d, x, s, t)
   return X(bit.bor(bit.band(b, c), bit.band(bit.bnot(b), d)), a, b, x, s, t)
end

local function G(a, b, c, d, x, s, t)
   return X(bit.bor(bit.band(b, d), bit.band(c, bit.bnot(d))), a, b, x, s, t)
end

local function H(a, b, c, d, x, s, t)
   return X(bit.bxor(bit.bxor(b, c), d), a, b, x, s, t)
end

local function I(a, b, c, d, x, s, t)
   return X(bit.bxor(c, bit.bor(b, bit.bnot(d))), a, b, x, s, t)
end

function crypt.md5(encoding_string)
   local blks = string_to_blks(encoding_string)

   local a = 1732584193
   local b = -271733879
   local c = -1732584194
   local d = 271733878

   for i = 0, #blks-1, 16 do
      local olda, oldb, oldc, oldd = a, b, c, d

      a = F(a, b, c, d, blks[i+ 0], 7, -680876936)
      d = F(d, a, b, c, blks[i+ 1], 12, -389564586)
      c = F(c, d, a, b, blks[i+ 2], 17, 606105819)
      b = F(b, c, d, a, blks[i+ 3], 22, -1044525330)
      a = F(a, b, c, d, blks[i+ 4], 7, -176418897)
      d = F(d, a, b, c, blks[i+ 5], 12, 1200080426)
      c = F(c, d, a, b, blks[i+ 6], 17, -1473231341)
      b = F(b, c, d, a, blks[i+ 7], 22, -45705983)
      a = F(a, b, c, d, blks[i+ 8], 7, 1770035416)
      d = F(d, a, b, c, blks[i+ 9], 12, -1958414417)
      c = F(c, d, a, b, blks[i+10], 17, -42063)
      b = F(b, c, d, a, blks[i+11], 22, -1990404162)
      a = F(a, b, c, d, blks[i+12], 7, 1804603682)
      d = F(d, a, b, c, blks[i+13], 12, -40341101)
      c = F(c, d, a, b, blks[i+14], 17, -1502002290)
      b = F(b, c, d, a, blks[i+15], 22, 1236535329)

      a = G(a, b, c, d, blks[i+ 1], 5, -165796510)
      d = G(d, a, b, c, blks[i+ 6], 9, -1069501632)
      c = G(c, d, a, b, blks[i+11], 14, 643717713)
      b = G(b, c, d, a, blks[i+ 0], 20, -373897302)
      a = G(a, b, c, d, blks[i+ 5], 5, -701558691)
      d = G(d, a, b, c, blks[i+10], 9, 38016083)
      c = G(c, d, a, b, blks[i+15], 14, -660478335)
      b = G(b, c, d, a, blks[i+ 4], 20, -405537848)
      a = G(a, b, c, d, blks[i+ 9], 5, 568446438)
      d = G(d, a, b, c, blks[i+14], 9, -1019803690)
      c = G(c, d, a, b, blks[i+ 3], 14, -187363961)
      b = G(b, c, d, a, blks[i+ 8], 20, 1163531501)
      a = G(a, b, c, d, blks[i+13], 5, -1444681467)
      d = G(d, a, b, c, blks[i+ 2], 9, -51403784)
      c = G(c, d, a, b, blks[i+ 7], 14, 1735328473)
      b = G(b, c, d, a, blks[i+12], 20, -1926607734)

      a = H(a, b, c, d, blks[i+ 5], 4, -378558)
      d = H(d, a, b, c, blks[i+ 8], 11, -2022574463)
      c = H(c, d, a, b, blks[i+11], 16, 1839030562)
      b = H(b, c, d, a, blks[i+14], 23, -35309556)
      a = H(a, b, c, d, blks[i+ 1], 4, -1530992060)
      d = H(d, a, b, c, blks[i+ 4], 11, 1272893353)
      c = H(c, d, a, b, blks[i+ 7], 16, -155497632)
      b = H(b, c, d, a, blks[i+10], 23, -1094730640)
      a = H(a, b, c, d, blks[i+13], 4, 681279174)
      d = H(d, a, b, c, blks[i+ 0], 11, -358537222)
      c = H(c, d, a, b, blks[i+ 3], 16, -722521979)
      b = H(b, c, d, a, blks[i+ 6], 23, 76029189)
      a = H(a, b, c, d, blks[i+ 9], 4, -640364487)
      d = H(d, a, b, c, blks[i+12], 11, -421815835)
      c = H(c, d, a, b, blks[i+15], 16, 530742520)
      b = H(b, c, d, a, blks[i+ 2], 23, -995338651)

      a = I(a, b, c, d, blks[i+ 0], 6, -198630844)
      d = I(d, a, b, c, blks[i+ 7], 10, 1126891415)
      c = I(c, d, a, b, blks[i+14], 15, -1416354905)
      b = I(b, c, d, a, blks[i+ 5], 21, -57434055)
      a = I(a, b, c, d, blks[i+12], 6, 1700485571)
      d = I(d, a, b, c, blks[i+ 3], 10, -1894986606)
      c = I(c, d, a, b, blks[i+10], 15, -1051523)
      b = I(b, c, d, a, blks[i+ 1], 21, -2054922799)
      a = I(a, b, c, d, blks[i+ 8], 6, 1873313359)
      d = I(d, a, b, c, blks[i+15], 10, -30611744)
      c = I(c, d, a, b, blks[i+ 6], 15, -1560198380)
      b = I(b, c, d, a, blks[i+13], 21, 1309151649)
      a = I(a, b, c, d, blks[i+ 4], 6, -145523070)
      d = I(d, a, b, c, blks[i+11], 10, -1120210379)
      c = I(c, d, a, b, blks[i+ 2], 15, 718787259)
      b = I(b, c, d, a, blks[i+ 9], 21, -343485551)

      a = add(a, olda)
      b = add(b, oldb)
      c = add(c, oldc)
      d = add(d, oldd)
   end
   return getHex(a)..getHex(b)..getHex(c)..getHex(d), a,b,c,d
end
 ----------------- End md5 ------------------
 
local Base=2^32
--[[ функции преобразования подблока по ключу 
subblock - преобразуемый подблок
key - ключ
возвращаяемое значение - преобразованный блок]]
local function f(subblock, key)
  local _,res=crypt.md5(subblock..key)
  return res
--  return math.fmod(subblock + key, Base)
end

--[[Шифрование открытого текста
left - левый входной подблок
right - правый входной подблок
key - массив ключей]]
local function C(left, right, key)
	for i = 1,#key do
		left,right = bit.bxor(right, f(left, key[i])), left
	end
    return left,right
end
--[[Расшифрование текста
left - левый зашифрованный подблок
right - правый зашифрованный подблок]]
local function D(left, right, key)
	for i = #key,1,-1 do
		left,right = right, bit.bxor(left, f(right, key[i]))
	end
    return left,right
end
--Функция формирования массива ключей
function crypt.getkey(pwd)
  local key={}
  local hesh=pwd
  for i=0,3 do
    hesh,key[i*4+1],key[i*4+2],key[i*4+3],key[i*4+4]=crypt.md5(hesh)
  end
  return key
end

local function StrToInt(str)
   local int = 0
   local byte
   for i = 0, 3 do
     byte=str:sub(1,1)
     str=str:sub(2)
     int=bit.lshift(int,8)+(string.byte(byte) or 0)
   end
   return int, str
end

local function IntToHex(int)
   local str = ""
   local char
   for i = 0, 7 do
      char=bit.band(bit.rshift(int, 28), 15)
      int=bit.lshift(int,4)
      str=str..string.format('%x',char)
   end
   return str
end

 local function HexToInt(str)
   local int = 0
   local byte
   for i = 0, 3 do
     byte=tonumber(str:sub(1,2),16) or 0
     str=str:sub(3)
     int=bit.lshift(int,8)+byte
   end
   return int, str
end

 local function IntToStr(int)
   local str = ""
   local char
   for i = 0, 3 do
      char=bit.band(bit.rshift(int, 24), 255)
      int=bit.lshift(int,8)
      str=str..string.char(char)
   end
   return str
end

--[[Шифрование открытого текста
str - входной текст
key - массив ключей]]
function crypt.crypt(str,key)
  local str1=""
  local left,right
  while #str>0 do
    left,str=StrToInt(str)
    right,str=StrToInt(str)
    left,right=C(left, right, key)
    str1=str1..IntToHex(left)
    str1=str1..IntToHex(right)
  end
  return str1
end

--[[Расшифрование текста
str - зашифрованный текст
key - массив ключей]]
function crypt.decrypt(str,key)
  local str1=""
  local left,right
  while #str>0 do
    left,str=HexToInt(str)
    right,str=HexToInt(str)
    left,right=D(left, right, key)
    str1=str1..IntToStr(left)
    str1=str1..IntToStr(right)
  end
  return str1
end

return crypt