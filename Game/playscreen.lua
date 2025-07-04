Playscreen = {}

playerHitCooldown = 0
playerHitDelay = 0.5

local function aabbOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and
           bx < ax + aw and
           ay < by + bh and
           by < ay + ah
end


function Playscreen:load()
    camera = require "libraries/camera"
    cam = camera()
    cam:zoom(2.5)

    sti = require "libraries/sti"
    gameMap = sti("maps/finalMap.lua")

    world = wf.newWorld(0,0)

    world:addCollisionClass('player')
    world:addCollisionClass('weapon')
    world:addCollisionClass('enemy')
    world:addCollisionClass('wall')


    walls = {}
    if gameMap.layers["walls"] then
        for i, obj in pairs(gameMap.layers["walls"].objects) do
           local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            wall:setType('static')
            wall:setCollisionClass('wall')
            table.insert(walls, wall) 
        end
    end

    require "player"
    require "weapon"
    require "enemy"

    enemies = {}
    if gameMap.layers["enemies"] then
        for i, obj in pairs(gameMap.layers["enemies"].objects)do
            local enemy = Enemy:new(obj.x, obj.y)
            table.insert(enemies, enemy)
        end
    end

    Player:load()

    winText = love.graphics.newImage("sprites/win text.png")

    enemyDeathSound = love.audio.newSource("sounds/goblin death.mp3", "static")
    song = love.audio.newSource("sounds/song.mp3", "stream")
    song:setLooping(true)
    song:play()

end

function Playscreen:update(dt)
    world:update(dt)

    Player:update(dt)
    Weapon:update(dt)

    

    -- Only kill one enemy per frame using AABB overlap
    local killed = false
    for _, enemy in ipairs(enemies) do
        if not killed and Weapon.collider and enemy.collider and enemy.alive then
            local wx, wy = Weapon.collider:getPosition()
            local ww, wh = 16, 16 -- Weapon collider size
            local ex, ey = enemy.collider:getPosition()
            local ew, eh = 32, 50 -- Enemy collider size (adjust to your actual size)
            -- Center to top-left
            wx = wx - ww / 2
            wy = wy - wh / 2
            ex = ex - ew / 2
            ey = ey - eh / 2

            if aabbOverlap(wx, wy, ww, wh, ex, ey, ew, eh) then
                print("Weapon hit enemy!")
                enemy.alive = false
                if enemy.collider then
                    enemy.collider:destroy()
                    enemy.collider = nil
                end
                killed = true
                enemyDeathSound:play()
                break -- Stop after killing one enemy
            end
        end
    end

    -- Remove dead enemies from the table
    for i = #enemies, 1, -1 do
        if not enemies[i].alive then
            table.remove(enemies, i)
        end
    end

    -- Update all enemies
    for _, enemy in ipairs(enemies) do
        enemy:update(dt)
    end

    -- Set camera to player
    cam:lookAt(Player.x, Player.y)

    -- Enemy AI: set chasing if player is seen
    for _, enemy in ipairs(enemies) do
        if enemy:canSeePlayer(Player) then
            enemy.chasing = true
            enemy.chaseTimer = enemy.chaseTime
        end
    end

    if playerHitCooldown > 0 then
        playerHitCooldown = playerHitCooldown - dt
    end

    -- Player/enemy collision check
    for _, enemy in ipairs(enemies) do
        if Player.collider and enemy.collider and enemy.alive and playerHitCooldown <= 0 then
            local px, py = Player.collider:getPosition()
            local pw, ph = 32, 48 -- Player collider size (adjust to your actual size)
            local ex, ey = enemy.collider:getPosition()
            local ew, eh = 32, 50 -- Enemy collider size

            -- Center to top-left
            px = px - pw / 2
            py = py - ph / 2
            ex = ex - ew / 2
            ey = ey - eh / 2

            if aabbOverlap(px, py, pw, ph, ex, ey, ew, eh) then
                Player.health = Player.health - 1
                playerHitCooldown = playerHitDelay
                print("Player hit! Health:", Player.health)
                break -- Only take one hit per frame
            end
        end
    end

     if Player.health <= 0 then
        print("Player died! Returning to title screen.")
        gameState = "title"
        TitleScreen:load()
        song:stop()
        return
    end
end

function Playscreen:draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["ground"])
        gameMap:drawLayer(gameMap.layers["decoration"])
        Player:draw()
        Weapon:draw()
        for _, enemy in ipairs(enemies) do
            enemy:draw()
            enemy:drawViewCone()
        end
    cam:detach()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Enemies left: " .. tostring(#enemies), 10, 10)
    love.graphics.print("Health: " .. Player.health, 10, 30)

    if #enemies == 0 then
        love.graphics.draw(winText, love.graphics.getWidth() / 2 - winText:getWidth() / 2, love.graphics.getHeight() / 2 - winText:getHeight() / 2)
    end
end

