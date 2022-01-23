--[[
  CHRxPNG Converter
  Creates NES CHR files out of PNGs and vice versa.
  PNGs must be 128 x 128 pixels and use exactly 4 colors.
  CHRs are expected to contain 512 tiles.
  by 2022 marc2o / Marc Oliver Orth
  https://marc2o.github.io
--]]

CHRxPNG = {
  chrdat = "",
  canvas = nil,
  colors = nil,
  paletteIndex = 1,
  palettes = {
    {
      -- https://lospec.com/palette-list/2-bit-grayscale
      { 0x00, 0x00, 0x00 },
      { 0x67, 0x67, 0x67 },
      { 0xb6, 0xb6, 0xb6 },
      { 0xff, 0xff, 0xff }
    },
    {
      -- https://lospec.com/palette-list/kirokaze-gameboy
      { 0x33, 0x2c, 0x50 },
      { 0x46, 0x87, 0x8f },
      { 0x94, 0xe3, 0x44 },
      { 0xe2, 0xf3, 0xe4 }
    },
    {
      -- https://lospec.com/palette-list/2bit-demichrome
      { 0x21, 0x1e, 0x20 },
      { 0x55, 0x55, 0x68 },
      { 0xa0, 0xa0, 0x8b },
      { 0xe9, 0xef, 0xec }
    },
    {
      -- https://lospec.com/palette-list/nintendo-super-gameboy
      { 0x33, 0x1e, 0x50 },
      { 0xa6, 0x37, 0x25 },
      { 0xd6, 0x8e, 0x49 },
      { 0xf7, 0xe7, 0xc6 }
    },
    {
      -- https://lospec.com/palette-list/nintendo-gameboy-bgb
      { 0x08, 0x18, 0x20 },
      { 0x34, 0x68, 0x56 },
      { 0x88, 0xc0, 0x70 },
      { 0xe0, 0xf8, 0xd0 }
    },
    {
      -- https://lospec.com/palette-list/pokemon-sgb
      { 0x18, 0x10, 0x10 },
      { 0x84, 0x73, 0x9c },
      { 0xf7, 0xb5, 0x8c },
      { 0xff, 0xef, 0xff }
    },
    {
      -- https://lospec.com/palette-list/cga-palette-1-high
      { 0x00, 0x00, 0x00 },
      { 0x55, 0xff, 0xff },
      { 0xff, 0x55, 0xff },
      { 0xff, 0xff, 0xff }
    },
    {
      -- https://lospec.com/palette-list/kid-icarus-sgb
      { 0x1e, 0x00, 0x00 },
      { 0x9e, 0x00, 0x00 },
      { 0xf7, 0x8e, 0x50 },
      { 0xce, 0xf7, 0xf7 }
    },
    {
      -- https://lospec.com/palette-list/super-mario-land-2-sgb
      { 0x00, 0x00, 0x00 },
      { 0x11, 0xc6, 0x00 },
      { 0xdf, 0xa6, 0x77 },
      { 0xef, 0xf7, 0xb6 }
    }
  },
  chrbanks = 1,
  colcount = 0,
  nestiles = nil,
  imagedat = nil,
  imagecol = {},
  imagehgt = 0,
  contents = "",
  filesize = 0,
  filetype = "",
  filename = "",
  fullpath = ""
} 
CHRxPNG.__index = CHRxPNG

function CHRxPNG:init()
  self.canvas = love.graphics.newCanvas(128, 128)
  self.canvas:setFilter("nearest", "nearest")
  self:reset()
end

function CHRxPNG:reset()
  self.chrdat = ""
  self.colcount = 0
  self.imagecol = {}
end

function CHRxPNG:resizeCanvas(width, height)
  self.canvas = love.graphics.newCanvas(width, height)
  self.canvas:setFilter("nearest", "nearest")
end

function CHRxPNG:setPalette(palette)
  if self.filetype == ".chr" or self.filetype == "" then
    self.colors = self.palettes[palette]
    self:drawCHR()
  else
    self.colors = self.imagecol
  end
end

function CHRxPNG:switchPalette()
  self.paletteIndex = self.paletteIndex + 1
  if self.paletteIndex > #self.palettes then
    self.paletteIndex = 1
  end
  self:setPalette(self.paletteIndex)
end

function CHRxPNG:getColor(color)
  if self.colors == nil then
    self:setPalette(self.paletteIndex)
  end
  local r, g, b = 1, 2, 3
  return { self.colors[color][r] / 255, self.colors[color][g] / 255, self.colors[color][b] / 255 }
end

function CHRxPNG:openFile(file)
  local success = true

  self.nestiles = file
  self.fullpath = file:getFilename()
  self.filetype = self.fullpath:match("^.+(%..+)$"):lower()
  if love.system.getOS() == "Windows" then
    self.filename = self.fullpath:match("^.+\\(.+)$")
  else
    self.filename = self.fullpath:match("^.+/(.+)$")
  end
  self.filename = string.sub(self.filename, 1, #self.filename - #self.filetype)
  self.contents, self.filesize = file:read()
  
  if self.filetype == ".chr" then
    if self.filesize / 32 > 16 then
      self.banks = 2
    else
      self.banks = 1
    end
    self:resizeCanvas(128, self.filesize / 32)
    self:setPalette(self.paletteIndex)
    self:readCHR()
  elseif self.filetype == ".png" then
    self:setPalette(1)
    self:readPNG()
  else
    self:displayDialog("File type not supported.")
    success = false
  end
  
  return success
end

function CHRxPNG:displayDialog(msg, title)
  local title = title or "ERROR"
  local success = love.window.showMessageBox( title, msg, "info", true )
end

function CHRxPNG:readPNG()
  self:reset()
  local image = love.graphics.newImage(self.nestiles)

  self:resizeCanvas(128, image:getHeight())
  if image:getHeight() > 128 then
    self.banks = 2
  else
    self.banks = 1
  end

  self:drawPNG(image)
  self.imagedat = self.canvas:newImageData()
  self:imageColors()
  self:setPalette()
end

function CHRxPNG:writePNG()
  local data = self.canvas:newImageData()
  local file = data:encode("png", self.filename .. ".png")
  
  self:fileWritten("PNG")    
end

function CHRxPNG:drawPNG(image)
  love.graphics.setCanvas(self.canvas)
  love.graphics.draw(image, 0, 0)
  love.graphics.setCanvas()
end

function CHRxPNG:readCHR()
  self:reset()
  self:drawCHR()
end

function CHRxPNG:writeCHR()
  if not self.colcount == 4 then return end
  self.chrdat = "" 
  local file = love.filesystem.newFile(self.filename .. ".chr", "w")

  local tile = {
    -- bitplane 1
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    -- bitplane 2
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 }
  }

  for i = 0, self.imagedat:getHeight() * 2 - 1 do
    local x, y = (i % 16) * 8, math.floor(i / 16) * 8
    local r, g, b, a
    
    for ty = 1, 8 do
      for tx = 1, 8 do
        
        local function getPixelRGB(x, y)
          local r, g, b, a = self.imagedat:getPixel(x, y)
          r = math.floor(r * 255)
          g = math.floor(g * 255)
          b = math.floor(b * 255)
          return r, g, b
        end
        
        r, g, b = getPixelRGB(x + (tx - 1), y + (ty - 1))
        
        for color = 1, 4 do
          if self.imagecol[color][1] == r and
             self.imagecol[color][2] == g and
             self.imagecol[color][3] == b then
            if color == 1 then
              tile[ty    ][tx] = 0
              tile[ty + 8][tx] = 0
            elseif color == 2 then
              tile[ty    ][tx] = 1
              tile[ty + 8][tx] = 0
            elseif color == 3 then
              tile[ty    ][tx] = 0
              tile[ty + 8][tx] = 1
            elseif color == 4 then
              tile[ty    ][tx] = 1
              tile[ty + 8][tx] = 1
            end
          end
        end
        
      end
    end
    
    for byte = 1, 16 do
      local bits = self:toByte(tile[byte])
      self.chrdat = self.chrdat .. string.char(bits)
    end
    
  end
  
  file:write(self.chrdat)
  file:close()
  file = nil
  
  self:fileWritten("CHR")
end

function CHRxPNG:drawCHR()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear(self:getColor(1))

  -- byte index
  for i = 1, self.filesize, 16 do
    -- one tile at byte index: 2 * 8 bytes
    for t = 1, 8 do
      local bpl1 = self:toBits(self.contents:byte(i + (t - 1)))     -- bitplane 1
      local bpl2 = self:toBits(self.contents:byte(i + 8 + (t - 1))) -- bitplane 2
      local cval = {} -- color values
      local x, y = ((i - 1) % 256) / 2, math.floor((i - 1) / 256) * 8
      -- 8 bits of each byte in a row
      for b = 1, 8 do
        if bpl1[b] == 0 and bpl2[b] == 0 then cval[b] = 1 end
        if bpl1[b] == 1 and bpl2[b] == 0 then cval[b] = 2 end
        if bpl1[b] == 0 and bpl2[b] == 1 then cval[b] = 3 end
        if bpl1[b] == 1 and bpl2[b] == 1 then cval[b] = 4 end
        
        love.graphics.setColor(self:getColor(cval[b]))
        love.graphics.points(x + (b - 1), y + t)
      end
    end
  end

  love.graphics.setCanvas()
end

function CHRxPNG:imageColors()
  if self.imagedat == nil then return end
  self.imagecol = {}
  local colorIsNew = 0
  local r, g, b, a
  
  for i = 0, 16383 do
    r, g, b, a = self.imagedat:getPixel(i % 128, math.floor(i / 128))
    r = math.floor(r * 255)
    g = math.floor(g * 255)
    b = math.floor(b * 255)
    
    colorIsNew = 0
    
    if #self.imagecol > 0 then
      for c = 1, #self.imagecol do
        if self.imagecol[c][1] ~= r and self.imagecol[c][2] ~= g and self.imagecol[c][3] ~= b then
          colorIsNew = colorIsNew + 1
        end
      end
    else
      colorIsNew = colorIsNew + 1
    end
    
    if colorIsNew >= #self.imagecol then
      self.imagecol[#self.imagecol + 1] = { r, g, b }
    end
  end
  
  self.colcount = #self.imagecol
  if self.colcount ~= 4 then
    local only = ""
    if self.colcount < 4 then only = "only " end
    self:displayDialog("Exactly 4 colors required, but " .. only .. self.colcount .. " in " .. self.filename .. self.filetype ..  " found.", "ERROR")
  end

  local function sort(colors)
    local sorted = false
    while not sorted do
      for c = 1, 3 do
        if colors[c][1] > colors[c+1][1] then
          local color = colors[c]
          colors[c] = colors[c + 1]
          colors[c + 1] = color
        end
      end
      if colors[1][1] <= colors[2][1] and
         colors[2][1] <= colors[3][1] and
         colors[3][1] <= colors[4][1] then
        sorted = true
      end 
    end
    return colors
  end
  self.imagecol = sort(self.imagecol)
end

function CHRxPNG:fileWritten(type)
  local fileLengthInfo = ""
  local path = {}
  path.result = "."
  path["Windows"] = " to %appdata%\\LOVE\\."
  path["OS X"] = " to ~/Library/Application Support/LOVE/."
  local osString = love.system.getOS()
  if path[osString] ~= nil then
    path.result = path[osString]
  end
  if type == "CHR" then
    fileLengthInfo = #self.chrdat .. " bytes written.\n"
  end
  self:displayDialog( fileLengthInfo .. type .. " file saved" .. path.result, "Done.")
end

function CHRxPNG:toBits(number)
  local result = { 0, 0, 0, 0, 0, 0, 0, 0 }
  for i = 1, 8 do
    if number % 2 ~= 0 then
      result[8 - (i - 1)] = 1
    else
      result[8 - (i - 1)] = 0
    end
    number = math.floor(number / 2)
  end
  return result
end

function CHRxPNG:toByte(bits)
  local byte = 0
  for i = 1, 8 do
    local value = bits[8 - (i - 1)]
    byte = byte + value * 2 ^ (i - 1)
  end
  return byte
end
