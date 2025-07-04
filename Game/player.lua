Player ={}
Player.hitbox = {}

function Player:load()
    require "weapon"
    anim8 = require "libraries/anim8"
    love.graphics.setDefaultFilter("nearest","nearest")

    Weapon:load()

    Player.x = 0
    Player.y = 0
    Player.speed = 100
    Player.rotation = 0
    Player.spriteSheet = love.graphics.newImage("sprites/knight.png")
    Player.grid = anim8.newGrid(54, 91, Player.spriteSheet:getWidth(), Player.spriteSheet:getHeight(),492, 1)
    Player.direction  = "down" -- Default direction
    Player.health = 3

    Player.animations = {}
    Player.animations.down = anim8.newAnimation(Player.grid("1-3", 1), 0.2)
    Player.animations.up = anim8.newAnimation(Player.grid("1-3", 4), 0.2)
    Player.animations.left = anim8.newAnimation(Player.grid("1-3", 2), 0.2)
    Player.animations.right = anim8.newAnimation(Player.grid("1-3", 3), 0.2)

    Player.animation = Player.animations.left

    --Collider
    Player.spriteWidth = 54
    Player.spriteHeight = 91
    Player.hitbox.width = Player.spriteWidth
    Player.hitbox.height = Player.spriteHeight
    Player.pivotOffsetX = Player.spriteWidth / 2
    Player.pivotOffsetY = Player.spriteHeight / 2

    Player.collider = world:newBSGRectangleCollider(Player.x, Player.y, 27, 45, 10)
    Player.collider:setFixedRotation(true)
    
end

function Player:update(dt)
    world:update(dt)
    Player.x = Player.collider:getX()
    Player.y = Player.collider:getY()

    local isMoving = false
    local vx = 0
    local vy = 0
    --Move up and down
    if love.keyboard.isDown("w") then
        vy = Player.speed * -1
        Player.animation = Player.animations.up
        isMoving = true
        Player.direction = "up"
        else if love.keyboard.isDown("s") then
            vy = Player.speed
            Player.animation = Player.animations.down
            isMoving = true
            Player.direction = "down"
        end
    end
    --Move left and right
    if love.keyboard.isDown("a") then
        vx = Player.speed * -1
        Player.animation = Player.animations.left
        isMoving = true
        Player.direction = "left"
        else if love.keyboard.isDown("d") then
            vx = Player.speed
            Player.animation = Player.animations.right
            isMoving = true
            Player.direction = "right"
        end
    end

    Player.collider:setLinearVelocity(vx, vy)

    --Mouse control
    local mx, my = love.mouse.getPosition()
    --Acount for camera offset
    if camera and camera.worldCoords then
        mx, my = camera:worldCoords(mx,my)
    end
    local centerX = Player.x + Player.pivotOffsetX
    local centerY = Player.y + Player.pivotOffsetY
    local angle = math.atan2(my - centerY, mx - centerX)
    Player.rotation = angle
    

    if isMoving == false then
        Player.animation:gotoFrame(2)
    end

    Player.animation:update(dt)

end

function Player:draw()
    Player.animation:draw(
        Player.spriteSheet,
        Player.x, Player.y,
        nil,
        0.5, 0.5, Player.pivotOffsetX, Player.pivotOffsetY
    )
end
