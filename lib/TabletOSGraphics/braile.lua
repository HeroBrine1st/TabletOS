--                                --
--        Braille  Bicycle        -- 
--      use your imagination      --
--            ** ** **            --
--        Totoro  (c) 2016        --
--        computercraft.ru        --
--  doubleBuffering modification  --
local unicode = require('unicode')
local buffer = require("doubleBuffering")
local braille = {}

function sign(x)
   if x<0 then
     return -1
   elseif x>0 then
     return 1
   else
     return 0
   end
end
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

braille.matrix = function(width, height)
    local matrix = {}
    matrix.width = width
    matrix.height = height
    return matrix
end

braille.set = function(matrix, sx, sy, value)
    local x, y, v = sx-1, sy-1, value or 1
    if (x >= 0 and x < matrix.width) and (y >= 0 and y < matrix.height) then
        matrix[matrix.width*y + x] = value
    end
end

braille.get = function(matrix, sx, sy)
    local x, y = sx-1, sy-1
    if (x >= 0 and x < matrix.width) and (y >= 0 and y < matrix.height) then
        return (matrix[matrix.width*y + x] or 0)
    else
        return 0
    end
end

braille.clear = function(matrix)
    for i = 1, matrix.width * matrix.height do matrix[i] = nil end
end

braille.line = function(matrix, x1, y1, x2, y2, value)
    local dx, dy = math.abs(x1-x2), math.abs(y1-y2)
    local v = value or 1
    if dx > 0 or dy > 0 then
        if dx > dy then
            local y = y1
            for x = x1, x2, sign(x2-x1) do
                braille.set(matrix, x, round(y), v)
                y = y + (dy / dx) * sign(y2-y1)
            end
        else
            local x = x1
            for y = y1, y2, sign(y2-y1) do
                braille.set(matrix, round(x), y, v)
                x = x + (dx / dy) * sign(x2-x1)
            end
        end
    end
end

braille.render = function(matrix, sx, sy,back, fore)
    local y = 0
    for dy = 1, matrix.height, 4 do
        for dx = 1, matrix.width, 2 do
            local unit = braille.unit(braille.get(matrix, dx, dy),
                                      braille.get(matrix, dx, dy+1),
                                      braille.get(matrix, dx, dy+2),
                                      braille.get(matrix, dx, dy+3),
                                      braille.get(matrix, dx+1, dy),
                                      braille.get(matrix, dx+1, dy+1),
                                      braille.get(matrix, dx+1, dy+2),
                                      braille.get(matrix, dx+1, dy+3))
            buffer.set(sx + math.floor(dx/2), sy + math.floor(dy/4),back,fore,unit)
        end
        y = y + 1
    end
end

braille.unit = function(a, b, c, d, e, f, g, h)
    return unicode.char(10240 + 128*h + 64*d + 32*g + 16*f + 8*e + 4*c + 2*b + a);
end

return braille