require("texture_load")
gConst = 8
missiles = {}
planets = {}
planet_positions = {}
pressed = {x=0, y=0}

function findGravity(affected, affectee)
	local x1, y1 = affected:getPosition()
	local x2, y2 = affectee:getPosition()
	local dx = x1-x2
	local dy = y1-y2
	local r2 = dx*dx + dy*dy
	local m1 = affected:getMass()
	local m2 = affectee:getMass()
	local force = -gConst*m1*m2/r2
	return force*dx/r2, force*dy/r2
end

--function newPlanet(posX, posY, )

function packPlanetPositions()
	planet_positions = {}
	for i,planet in pairs(planets) do
		local posX, posY= planet:getPosition()
		table.insert(planet_positions, {posX, love.graphics.getHeight() - posY})
	end
end

function love.load()
	-- New world, no gravity.
	world = love.physics.newWorld()
	world:setGravity(0, 0)
	-- Load in textures.
	loadTextures()
	-- Create some planets!
	for i=1,8 do
		for j=1,6 do
			if love.math.noise(i+8, j+60) > 0.8 then
				local posX = 100*i-50
				local posY = 100*j-50
				local body = love.physics.newBody(world, posX, posY, 'dynamic')
				local shape = love.physics.newCircleShape(30)
				local density = 20000
				local fixture = love.physics.newFixture(body, shape, density)
				table.insert(planets, body)
			end
		end
	end
	packPlanetPositions()
	local numPlanets = #planet_positions
	fragment = [[
		#define M_PI 3.1415926535897932384626433832795
		extern vec3 channels;
		extern vec2 neutral;
		extern vec2 planets[]] .. numPlanets .. [[];
		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
		{
			vec2 dir;
			dir.x = 0;
			dir.y = 0;
			for(int i = 0; i < ]].. numPlanets ..[[; i++) {
				vec2 dist = (planets[i]-screen_coords);
				dir += dist/(dist.x*dist.x+dist.y*dist.y);
			}
			dir = (dir * 30);
			vec2 neutral = vec2(pow(1-abs(dir.x), 5), pow(1-abs(dir.y), 5))*neutral;
			float red = (neutral.x + neutral.y)/2;
			dir = (dir + 1)/2;
			return vec4(vec3(red, dir.x, dir.y)*channels, 1.0);
		}
	]]
	shader = love.graphics.newShader(fragment)
end

function newMissile(x, y, vx, vy)
	print("FIRING!")
	local body = love.physics.newBody(world, x, y, 'dynamic')
	local shape = love.physics.newCircleShape(10)
	local density = 1
	local fixture = love.physics.newFixture(body, shape, density)
	body:applyLinearImpulse(vx, vy)
	table.insert(missiles, body)
end

function love.mousepressed(x, y, button)
	-- print("Mouse X: " .. x .. " Mouse Y:" .. y)
	pressed.x = x
	pressed.y = y
end

function love.mousereleased(x, y, button)
	-- print("Mouse X: " .. x .. " Mouse Y:" .. y)
	local vx = x - pressed.x
	local vy = y - pressed.y
	newMissile(pressed.x, pressed.y, vx, vy)
end

function applyGravity()
	for i,missile in pairs(missiles) do
		for j,planet in pairs(planets) do
			local fx, fy = findGravity(missile, planet)
			missile:applyLinearImpulse(fx, fy)
			planet:applyLinearImpulse(-fx, -fy)
		end
	end
end

function love.update(dt)
	world:update(dt)
	applyGravity()
	packPlanetPositions()
end

function love.draw()
	local channels = {0, 0, 0}
	local neutral = {1, 1}
	if love.keyboard.isDown("a") then channels[1] = 1 end
	if love.keyboard.isDown("o") then channels[2] = 1 end
	if love.keyboard.isDown("e") then channels[3] = 1 end
	if love.keyboard.isDown("'") then neutral[1] = 0 end
	if love.keyboard.isDown(",") then neutral[2] = 0 end
	shader:send("channels", channels)
	shader:send("neutral", neutral)
	shader:send("planets", unpack(planet_positions))
	love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setShader()

	for i,planet in pairs(planets) do
		local x, y = planet:getPosition()
		love.graphics.draw(planetImage, x-30, y-30, 0, 0.1, 0.1, 0, 0, 0, 0)
	end
	for i,missile in pairs(missiles) do
		local x, y = missile:getPosition()
		love.graphics.circle("fill", x, y, 10, 36)
	end
	if love.mouse.isDown("l") then
		local mx, my = love.mouse.getPosition()
		love.graphics.line(pressed.x, pressed.y, mx, my)
	end
end
