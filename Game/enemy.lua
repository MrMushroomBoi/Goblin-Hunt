Enemy = {}
Enemy.hitbox = {}

function Enemy:new(x, y)
    anim8 = require "libraries/anim8"

    local e = {}
    setmetatable(e, {__index = self})

    e.x = x or 0
    e.y = y or 0
    e.vx = 0
    e.vy = 0
    e.sprite = love.graphics.newImage("sprites/goblin.png")
    e.width = e.sprite:getWidth()
    e.height = e.sprite:getHeight()
    e.alive = true
    e.grid = anim8.newGrid(65, 65, e.sprite:getWidth(), e.sprite:getHeight())

    e.animations = {}
    e.animations.down = anim8.newAnimation(e.grid("1-7", 1), 0.2)
    e.animations.up = anim8.newAnimation(e.grid("1-7", 3), 0.2)
    e.animations.left = anim8.newAnimation(e.grid("1-7", 4), 0.2)
    e.animations.right = anim8.newAnimation(e.grid("1-7", 2), 0.2)

    e.speed = 75
    e.chasing = false
    e.chaseTime = 10
    e.chaseTimer = 0
    e.state = "roaming"
    e.roamTarget = {x = 0, y = 0}
    e.roamTimer = 0
    e.facingAngle = 0

    e.spriteWidth = 65
    e.spriteHeight = 65
    e.hitbox = {width = e.spriteWidth, height = e.spriteHeight}
    e.pivotOffsetX = e.spriteWidth / 2
    e.pivotOffsetY = e.spriteHeight / 2

    e.collider = world:newBSGRectangleCollider(e.x, e.y, 32, 50, 10)
    e.collider:setFixedRotation(true)
    e.collider:setCollisionClass('enemy')
    e.collider.parent = e -- for callbacks

    return e
end

function Enemy:update(dt)
    if not self.alive then return end

    self.x = self.collider:getX()
    self.y = self.collider:getY()

    -- State switching
    if self.chasing then
        self.state = "chasing"
    else
        self.state = "roaming"
    end

    if self.state == "chasing" then
        self:chasePlayer(dt)
    elseif self.state == "roaming" then
        self:roam(dt)
    end

    if self.animation then
        self.animation:update(dt)
    end
end



function Enemy:draw()
    if not self.alive then return end
    self.animation:draw(self.sprite, self.x, self.y, nil, 1, 1, self.pivotOffsetX, self.pivotOffsetY)
end

function Enemy:canSeePlayer(player)
    local ex, ey = self.x, self.y
    local px, py = player.x + player.pivotOffsetX, player.y + player.pivotOffsetY

    local dx, dy = px - ex, py - ey
    local distance = math.sqrt(dx*dx + dy*dy)
    local range = 100 -- view distance
    if distance > range then return false end

    local selfAngle = 0 -- set this to the direction the self is facing (in radians)
    local angleToPlayer = math.atan2(dy, dx)
    local fov = math.rad(120) --degree cone
    local selfAngle = self.facingAngle 

    local diff = math.abs((angleToPlayer - selfAngle + math.pi) % (2*math.pi) - math.pi)
    return diff < fov/2
end

function Enemy:drawViewCone()
    if not self.alive then return end
    local segments = 32
    local range = 100
    local fov = math.rad(120)
    local angle = self.facingAngle -- use the updated angle

    local points = {self.x, self.y}
    for i = 0, segments do
        local a = angle - fov/2 + fov * (i/segments)
        table.insert(points, self.x + math.cos(a) * range)
        table.insert(points, self.y + math.sin(a) * range)
    end
    love.graphics.setColor(1, 1, 0, 0.2)
    love.graphics.polygon("fill", points)
    love.graphics.setColor(1, 1, 1, 1)
end

function Enemy:chasePlayer(dt)
    -- Timer for chasing duration
    if self.chasing then
        self.chaseTimer = self.chaseTimer - dt
        if self.chaseTimer <= 0 then
            self.chasing = false
            self.chaseTimer = 0
        end
    end

       if self.chasing then
        local px = Player.x + Player.pivotOffsetX
        local py = Player.y + Player.pivotOffsetY
        local dx = px - self.x
        local dy = py - self.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 1 then
            local vx = (dx / dist) * self.speed
            local vy = (dy / dist) * self.speed
            self.collider:setLinearVelocity(vx, vy)
            -- Update facing angle
            self.facingAngle = math.atan2(dy, dx)
            self:updateAnimationByAngle()
        else
            self.collider:setLinearVelocity(0, 0)
        end
    else
        self.collider:setLinearVelocity(0, 0)
    end
end

function Enemy:pickNewRoamTarget()
    --Pick a random point within a certain range
    local roamRadius = 400
    local angle = math.random() * 2 * math.pi
    local dist = math.random(50, roamRadius)
    self.roamTarget.x = self.x + math.cos(angle) * dist
    self.roamTarget.y = self.y + math.sin(angle) * dist
    self.roamTimer = math.random(5, 10)
end

function Enemy:roam(dt)
    if not self.roamTarget or self.roamTimer <= 0 then
        self:pickNewRoamTarget()
    end

    -- If collided with wall, pick a new roam target
    if self.collider:enter('wall') then
        self:pickNewRoamTarget()
        return -- skip movement this frame to avoid getting stuck
    end

    local dx = self.roamTarget.x - self.x
    local dy = self.roamTarget.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > 5 then
        local vx = (dx / dist) * (self.speed * 0.5)
        local vy = (dy / dist) * (self.speed * 0.5)
        self.collider:setLinearVelocity(vx, vy)
        self.facingAngle = math.atan2(dy, dx)
        self:updateAnimationByAngle()
    else
        self.collider:setLinearVelocity(0, 0)
        self:pickNewRoamTarget()
    end
    self.roamTimer = self.roamTimer - dt
end

function Enemy:updateAnimationByAngle()
    local angle = self.facingAngle % (2 * math.pi)
    -- Right: -45 to 45 degrees
    if angle > math.rad(315) or angle <= math.rad(45) then
        self.animation = self.animations.right
    -- Down: 45 to 135 degrees
    elseif angle > math.rad(45) and angle <= math.rad(135) then
        self.animation = self.animations.down
    -- Left: 135 to 225 degrees
    elseif angle > math.rad(135) and angle <= math.rad(225) then
        self.animation = self.animations.left
    -- Up: 225 to 315 degrees
    else
        self.animation = self.animations.up
    end
end

function Enemy:kill()
    self.alive = false
    if self.collider then
        self.collider:destroy()
        self.collider = nil
    end
end