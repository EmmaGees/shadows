local Shadows = ...
local Circle = {}

Circle.__index = Circle

function Shadows.CreateCircle(Body, x, y, Radius)
	local Circle = setmetatable({}, Circle)
	
	Circle.Body = Body
	Circle.Radius = Radius
	Circle.Heading = math.atan2(y, x)
	Circle.Distance = math.sqrt(x^2 + y^2)
	
	Body:AddShape(Circle)
	
	return Circle
end

function Circle:Remove()
	self.Body.Shapes[self.ID] = nil
end

function Circle:SetRadius(Radius)
	if self.Radius ~= Radius then
		self.Radius = Radius
		self.Body.World.Changed = true
	end
end

function Circle:GetRadius()
	return self.Radius
end

function Circle:Draw()
	local Heading = self.Heading + math.rad(self.Body.Angle)
	return love.graphics.circle("fill", self.Body.x + math.cos(Heading) * self.Distance, self.Body.y + math.sin(Heading) * self.Distance, self.Radius)
end

function Circle:SetPosition(x, y)
	if self.x ~= x then
		self.x = x
		self.Body.World.Changed = true
	end
	if self.y ~= y then
		self.y = y
		self.Body.World.Changed = true
	end
end

function Circle:GetPosition()
	if self.Distance ~= 0 then
		local Heading = self.Heading + math.rad(self.Body.Angle)
		return self.Body.x + math.cos(Heading) * self.Distance, self.Body.y + math.sin(Heading) * self.Distance
	end
	return self.Body.x, self.Body.y
end

function Circle:GenerateShadows(Shapes, Body, Light)
	local x, y = self:GetPosition()
	local Radius = self:GetRadius()

	local Distance = math.sqrt((x - Light.x)^2 + (y - Light.y)^2)
	if Distance > Radius then
		local Heading = math.atan2(Light.x - x, y - Light.y) + math.pi/2
		local Offset = math.atan(Radius / Distance)
		local BorderDistance = Distance * math.cos(Offset)
		
		local Length = Light.Radius
		if Body.z < Light.z then
			Length = Body.z / math.atan2(Light.z, BorderDistance)
		end
		
		local Polygon = {type = "polygon"}
		table.insert(Polygon, Light.x + math.cos(Heading + Offset) * BorderDistance)
		table.insert(Polygon, Light.y + math.sin(Heading + Offset) * BorderDistance)
		table.insert(Polygon, Light.x + math.cos(Heading - Offset) * BorderDistance)
		table.insert(Polygon, Light.y + math.sin(Heading - Offset) * BorderDistance)
		
		if Light.z <= Body.z then
			local PenumbraAngle = math.atan(Light.SizeRadius / Light.Radius)
			local Penumbra = {type = "arc", Soft = true}
			Penumbra[1] = Polygon[1]
			Penumbra[2] = Polygon[2]
			Penumbra[3] = Length
			Penumbra[4] = Heading + Offset + PenumbraAngle
			Penumbra[5] = Heading + Offset
			table.insert(Shapes, Penumbra)
			
			local Penumbra = {type = "arc", Soft = true}
			Penumbra[1] = Polygon[3]
			Penumbra[2] = Polygon[4]
			Penumbra[3] = Length
			Penumbra[4] = Heading - Offset - PenumbraAngle
			if Penumbra[4] > math.pi then
				Penumbra[4] = Penumbra[4] - math.pi * 2
			end
			Penumbra[5] = Penumbra[4] + PenumbraAngle
			table.insert(Shapes, Penumbra)
		end

		table.insert(Polygon, Polygon[3] + math.cos(Heading - Offset) * Length)
		table.insert(Polygon, Polygon[4] + math.sin(Heading - Offset) * Length)
		table.insert(Polygon, Polygon[1] + math.cos(Heading + Offset) * Length)
		table.insert(Polygon, Polygon[2] + math.sin(Heading + Offset) * Length)
		table.insert(Shapes, Polygon)
		
		if Light.z > Body.z then
			local Circle = {type = "circle"}
			Circle[1] = Light.x + math.cos(Heading) * (Length + Distance)
			Circle[2] = Light.y + math.sin(Heading) * (Length + Distance)
			Circle[3] = math.sqrt((Polygon[5] - Circle[1])^2 + (Polygon[6] - Circle[2])^2)
			
			table.insert(Shapes, Circle)
		end
	end
end