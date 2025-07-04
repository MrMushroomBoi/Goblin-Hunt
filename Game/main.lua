gameState = "title"

function love.load()
    require "playscreen"
    require "titlescreen"
    wf = require "libraries/windfield"

    TitleScreen:load()
end

function love.update(dt)
   if gameState == "title" then
        TitleScreen:update(dt)
   elseif gameState == "play" then
        Playscreen:update(dt)
   end

end

function love.draw()
   if gameState == "title" then
        TitleScreen:draw()
   elseif gameState == "play" then
        Playscreen:draw()
   end
  
end

function love.keypressed(key)
    if gameState == "title" and key == "space" then
        gameState = "play"
        Playscreen:load()
    end
end
