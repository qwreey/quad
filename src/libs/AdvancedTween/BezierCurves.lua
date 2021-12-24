local module = {}

function Lerp(Alpha,Point1,Point2)
	return Point1 + ( (Point2 - Point1) * Alpha )
end

function module.Bezier(Alpha,...)
	local New = {}
	local Len = #{...}

	for i = 1,Len do
		if i ~= 1 then
			New[#New+1] = Lerp(Alpha,select(...,i-1),select(...,i))
		end
	end

	if Len <= 2 then
		return New[1]
	end
	return module.Bezier(Alpha,unpack(New))
end

return module