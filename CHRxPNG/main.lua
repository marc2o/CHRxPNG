--[[
  CHRxPNG Converter
  Creates NES CHR files out of PNGs and vice versa.
  PNGs must be 128 x 128 pixels and use exactly 4 colors.
  CHRs are expected to contain 512 tiles.
  by 2022 marc2o / Marc Oliver Orth
                                       ___
       ______    ___    ___   ___    /    \   ___
    _/       \_/    \_/ _  \_/   \  _--   / _/   \
   /   /  /  /   /  /   /__/  /__/ /  ___/ /   / /
  /___/__/__/\__/\_/___/   \____/ /     /  \____/
                                 /_____/
  https://marc2o.github.io
--]]

require("CHRxPNG")

load = {}
function load.update(dt)
end
function load.draw()
  love.graphics.clear(CHRxPNG:getColor(1))
  love.graphics.setColor(CHRxPNG:getColor(4))
  love.graphics.print("CHRxPNG v1.0, 2022 by @marc2o", 10, 10)
  love.graphics.print("https://marc2o.github.io · https://marc2o.itch.io", 10, 26)
  love.graphics.print("Drop CHR or PNG file…", 10, 58)
end

edit = {}
edit.showGrid = true
edit.bankSwitch = false
edit.scrollBank = false
edit.bankOffset = 0
edit.bankNumber = 1
function edit.update(dt)
  if edit.bankSwitch and not edit.scrollBank then
    edit.scrollBank = true
  end
  if edit.bankSwitch and edit.scrollBank then
    if edit.bankNumber == 1 then
      edit.bankOffset = edit.bankOffset - 2
      if edit.bankOffset <= -128 then
        edit.bankOffset = -128
        edit.bankNumber = 2
        edit.scrollBank = false
        edit.bankSwitch = false
      end
    else
      edit.bankOffset = edit.bankOffset + 2
      if edit.bankOffset >= 0 then
        edit.bankOffset = 0
        edit.bankNumber = 1
        edit.scrollBank = false
        edit.bankSwitch = false
      end
    end
  end
end
function edit.draw()
  -- draw drop zone
  love.graphics.setColor(CHRxPNG:getColor(2))
  love.graphics.rectangle("line", 512 + 32, 544 - 172, 128, 64, 4, 4)
  love.graphics.print("Drop CHR or \nPNG file…", 512 + 40, 544 - 164)

  -- draw commands
  love.graphics.setColor(CHRxPNG:getColor(4))
  love.graphics.print("[G] to toggle grid", 512 + 32, 544 - 64 - 16)
  if CHRxPNG.banks == 2 then
    love.graphics.print("[B] to switch bank", 512 + 32, 544 - 48 - 16)
  end
  if CHRxPNG.filetype == ".chr" then
    love.graphics.print("[P] to switch palette", 512 + 32, 544 - 80 - 16)
    love.graphics.print("[S] to save as PNG", 512 + 32, 544 - 32 - 16)
  else
    love.graphics.print("[S] to save as CHR", 512 + 32, 544 - 32 - 16)
  end
  love.graphics.print("[Esc] to exit", 512 + 32, 544 - 16 - 16)

  -- draw color swatches
  love.graphics.print("Palette:", 512 + 32, CHRxPNG.canvas:getHeight() + 32)
  for i = 1, 4 do
    love.graphics.setColor(CHRxPNG:getColor(i))
    love.graphics.rectangle("fill", 512 + 32 + (i - 1) * 32, CHRxPNG.canvas:getHeight() + 56, 32, 32)
  end
  love.graphics.setColor(CHRxPNG:getColor(4))
  love.graphics.rectangle("line", 512 + 32, CHRxPNG.canvas:getHeight() + 56, 128, 32)
  -- draw canvas
  love.graphics.push()
  love.graphics.draw(CHRxPNG.canvas, 512 + 32, 16)
  love.graphics.translate(16, 16)
  love.graphics.scale(
    4,
    4
  )
  local y = 0
  if CHRxPNG.canvas:getHeight() and edit.bankSwitch then y = -128 end
  love.graphics.draw(CHRxPNG.canvas, 0, edit.bankOffset)
  love.graphics.pop()
  
  -- draw grid
  if edit.showGrid and not edit.scrollBank then
    for i = 1, 15 do
      love.graphics.setColor(CHRxPNG:getColor(1))
      love.graphics.line(16, 16 + (i * 32), 16 + 512, 16 + (i * 32))
      love.graphics.line(16 + (i * 32), 16, 16 + (i * 32), 16 + 512)
    end
  end
  love.graphics.setColor(1, 1, 1)
end

function love.load()
  CHRxPNG:init()
  love.graphics.setLineStyle("rough")

  u, d = load.update, load.draw
end

function love.filedropped(file)
  local success = CHRxPNG:openFile(file)
  edit.bankOffset = 0
  edit.bankNumber = 1
  edit.scrollBank = false
  edit.bankSwitch = false
  if success then
    love.window.setTitle("CHRxPNG: " .. CHRxPNG.filename .. CHRxPNG.filetype)
    u, d = edit.update, edit.draw
  end
end

function love.keyreleased(key)
  if key == "s" then
    if CHRxPNG.filetype == ".chr" then
      CHRxPNG:writePNG()
    else
      CHRxPNG:writeCHR()
    end
  end
  if key == "g" then
    edit.showGrid = not edit.showGrid
  end
  if key == "p" then
    CHRxPNG:switchPalette()
  end
  if key == "b" and CHRxPNG.banks == 2 and not edit.scrollBank then
    edit.bankSwitch = not edit.bankSwitch
  end
end

function love.update(dt)
  if dt < 1 / 50 then
    love.timer.sleep(1 / 50 - dt)
  end

  if love.keyboard.isDown("escape") then
    love.event.quit()
  end

  u(dt)
end

function love.draw()
  love.graphics.clear(CHRxPNG:getColor(1))
  d()
end

function love.quit()
end
