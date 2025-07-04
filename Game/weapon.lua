Weapon = {}
Weapon.hitbox = {}

function Weapon:load()
    Weapon.sprite = love.graphics.newImage("sprites/sword.png")
    Weapon.spriteWidth = 32
    Weapon.spriteHeight = 32
    Weapon.pivotOffsetX = Weapon.spriteWidth / 2
    Weapon.pivotOffsetY = Weapon.spriteHeight / 2

    -- Create collider and joint after Player.collider exists!
    Weapon.collider = nil
    Weapon.joint = nil
end

function Weapon:spawnCollider()
    if Weapon.collider then return end
    local px, py = Player.collider:getPosition()
    local angle = 0
    local swingDistance = 40
    local offsetX = math.cos(angle) * swingDistance
    local offsetY = math.sin(angle) * swingDistance

    Weapon.collider = world:newRectangleCollider(px + offsetX, py + offsetY, 16, 16)
    Weapon.collider:setFixedRotation(true)
    Weapon.collider:setCollisionClass('weapon')

  
end

function Weapon:update(dt)
    if not Weapon.collider then
        Weapon:spawnCollider()
    end

    local px, py = Player.collider:getPosition()
    local mx, my = love.mouse.getPosition()
    if cam and cam.worldCoords then
        mx, my = cam:worldCoords(mx, my)
    end
    local angle = math.atan2(my - py, mx - px)
    local swingDistance = 40
    local targetX = px + math.cos(angle) * swingDistance
    local targetY = py + math.sin(angle) * swingDistance

    -- Calculate velocity needed to reach target
    local wx, wy = Weapon.collider:getPosition()
    local speed = 1000 -- Increase for snappier movement
    local vx = (targetX - wx) * 10
    local vy = (targetY - wy) * 10
    Weapon.collider:setLinearVelocity(vx, vy)

    Weapon.angle = angle

    -- For drawing
    Weapon.x = wx
    Weapon.y = wy
    Weapon.rotation = Weapon.angle or 0
end

function Weapon:draw()
    love.graphics.draw(
        Weapon.sprite,
        Weapon.x, Weapon.y,
        Weapon.rotation,
        1, 1,
        Weapon.pivotOffsetX, Weapon.pivotOffsetY
    )
end