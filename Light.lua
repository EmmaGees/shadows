local Shadows = ...
local Light = {}

Light.__index = Light
Light.x, Light.y, Light.z = 0, 0, 1
Light.Angle, Light.Arc = 0, 360
Light.Radius = 0
Light.SizeRadius = 10

Light.R, Light.G, Light.B, Light.A = 255, 255, 255, 255

local setCanvas = love.graphics.setCanvas
local clear = love.graphics.clear
local origin = love.graphics.origin
local translate = love.graphics.translate
local setBlendMode = love.graphics.setBlendMode
local setColor = love.graphics.setColor
local setShader = love.graphics.setShader
local arc = love.graphics.arc
local draw = love.graphics.draw
local halfPi = math.pi * 0.5

function Shadows.CreateLight(World, Radius)
	
	local Light = setmetatable({}, Light)
	local Width, Height = World.Canvas:getDimensions()
	
	Light.Radius = Radius
	Light.Canvas = love.graphics.newCanvas( Width, Height )
	Light.ShadowCanvas = love.graphics.newCanvas( Width, Height )
	Light.Shadows = {}
	
	World:AddLight(Light)
	
	return Light
	
end

function Shadows.CreateStar(World, Radius)
	
	local Light = setmetatable({}, Light)
	local Width, Height = World.Canvas:getDimensions()
	
	Light.Star = true
	Light.Radius = Radius
	Light.Canvas = love.graphics.newCanvas( Width, Height )
	Light.ShadowCanvas = love.graphics.newCanvas( Width, Height )
	Light.Shadows = {}
	
	World:AddStar(Light)
	
	return Light
	
end

function Light:GenerateShadows()
	
	for _, Body in pairs(self.World.Bodies) do
		
		if self.Moved or Body.Moved or not self.Shadows[ Body.ID ] then
		
			local Shapes = {}
			
			if Body.Body then
				
				for _, Fixture in pairs(Body.Body:getFixtureList()) do
					
					local Shape = Fixture:getShape()
					
					if Shape.GenerateShadows then
						
						local Radius = self.Radius + Shape:GetRadius(Body)
						local x, y = Shape:GetPosition(Body)
						local dx, dy = x - self.x, y - self.y
						
						if dx * dx + dy * dy < Radius * Radius then
							
							Shape:GenerateShadows(Shapes, Body, 0, 0, self)
							
						end
						
					end
					
				end
				
			else
				
				for _, Shape in pairs(Body.Shapes) do
					
					local Radius = self.Radius + Shape:GetRadius()
					local x, y = Shape:GetPosition()
					local dx, dy = x - self.x, y - self.y
					
					if dx * dx + dy * dy < Radius * Radius then
						
						Shape:GenerateShadows(Shapes, Body, 0, 0, self)
						
					end
					
				end
				
			end
			
			self.Shadows[ Body.ID ] = Shapes
			
		end
		
	end
	
	return Shapes
end

function Light:Update()
	
	if self.Changed or self.World.Changed then
		
		setCanvas(self.ShadowCanvas)
		clear(255, 255, 255, 255)
		
		translate(-self.World.x, -self.World.y)
		
		setBlendMode("subtract", "alphamultiply")
		setColor(255, 255, 255, 255)
		
		self:GenerateShadows()
		self.Moved = nil
		
		for _, Shapes in pairs(self.Shadows) do
			
			for _, Shadow in pairs(Shapes) do
				
				love.graphics[Shadow.type]("fill", unpack(Shadow))
				
			end
			
		end
		
		setColor(255, 255, 255, 255)
		setBlendMode("add")
		
		for Index, Body in pairs(self.World.Bodies) do
			
			Body:Draw()
			
		end
		
		setCanvas(self.Canvas)
		clear()
		origin()
		translate(self.x - self.World.x - self.Radius, self.y - self.World.y - self.Radius)
		
		if self.Image then
			
			setBlendMode("lighten", "premultiplied")
			setColor(self.R, self.G, self.B, self.A)
			draw(self.Image, self.Radius, self.Radius)
			
		else
			
			Shadows.LightShader:send("Radius", self.Radius)
			Shadows.LightShader:send("Center", {self.x - self.World.x, self.y - self.World.y, self.z})
			
			local Arc = math.rad(self.Arc / 2)
			local Angle = math.rad(self.Angle) - halfPi
			
			setShader(Shadows.LightShader)
			setBlendMode("alpha", "premultiplied")
			
			setColor(self.R, self.G, self.B, self.A)
			arc("fill", self.Radius, self.Radius, self.Radius, Angle - Arc, Angle + Arc)
			
			setShader()
			
		end
		
		origin()
		setBlendMode("multiply", "alphamultiply")
		draw(self.ShadowCanvas, 0, 0)
		
		setBlendMode("alpha", "alphamultiply")
		origin()
		setCanvas()
		setShader()
		
		self.Changed = nil
		self.World.UpdateCanvas = true
		
	end
	
end

function Light:SetAngle(Angle)
	
	if type(Angle) == "number" and Angle ~= self.Angle then
		
		self.Angle = Angle
		self.Changed = true
		
	end
	
	return self
	
end

function Light:GetAngle()
	
	return self.Angle
	
end

function Light:SetPosition(x, y, z)
	
	if x ~= self.x then
		
		self.x = x
		self.Changed = true
		self.Moved = true
		
	end
	
	if y ~= self.y then
		
		self.y = y
		self.Changed = true
		self.Moved = true
		
	end
	
	if z and z ~= self.z then
		
		self.z = z
		self.Changed = true
		self.Moved = true
		
	end
	
	return self
	
end

function Light:GetPosition()
	
	return self.x, self.y, self.z
	
end

function Light:SetColor(R, G, B, A)
	
	if R ~= self.R then
		
		self.R = R
		self.Changed = true
		
	end
	
	if G ~= self.G then
		
		self.G = G
		self.Changed = true
		
	end
	
	if B ~= self.B then
		
		self.B = B
		self.Changed = true
		
	end
	
	if A ~= self.A then
		
		self.A = A
		self.Changed = true
		
	end
	
	return self
	
end

function Light:GetColor()
	
	return self.R, self.G, self.B, self.A
	
end

function Light:SetImage(Image)
	
	if Image ~= self.Image then
		
		local Width, Height = Image:getDimensions()
		
		self.Image = Image
		self.Radius = math.sqrt( Width * Width + Height * Height ) * 0.5
		self.Changed = true
		
	end
	
end

function Light:GetImage()
	
	return self.Image
	
end

function Light:SetRadius(Radius)
	
	if Radius ~= self.Radius then
		
		self.Radius = Radius
		self.Changed = true
		
	end
	
end

function Light:GetRadius()
	
	return self.Radius
	
end

function Light:Remove()
	
	if self.Star then
		
		self.World.Stars[self.ID] = nil
		
	else
		
		self.World.Lights[self.ID] = nil
		
	end
	
	self.World.Changed = true
	
end