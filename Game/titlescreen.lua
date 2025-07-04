TitleScreen = {}

function TitleScreen:load()
    background = love.graphics.newImage("sprites/background.png")
    title = love.graphics.newImage("sprites/title.png")
    start = love.graphics.newImage("sprites/start.png")

    started = false

end

function TitleScreen:update(dt)
    if love.keyboard.isDown("space") then
        started = true
    end

end

function TitleScreen:draw()
    love.graphics.draw(background, 0, 0, nil, 5, 5)
    love.graphics.draw(title, 300, 0)
    love.graphics.draw(start, 600, 300)
end

