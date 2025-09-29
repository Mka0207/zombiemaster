local ENT = {}

ENT.Type = "point"
ENT.TriggerOutput = TriggerOutputOverride

function ENT:Initialize()
    if self.m_bHitMax == nil then
        self.m_bHitMax = false
    end
    
    if self.m_bHitMin == nil then
        self.m_bHitMin = false
    end
    
    if self.m_flMin == nil then
        self.m_flMin = 0
    end
    
    if self.m_flMax == nil then
        self.m_flMax = 0
    end
    
    if self.m_bDisabled == nil then
        self.m_bDisabled = false
    end
    
    self.m_OutValue = 0
    
	if self.m_flMin > self.m_flMax then
		local flTemp = self.m_flMax
		self.m_flMax = self.m_flMin
		self.m_flMin = self.flTemp
	end
    
	if self.m_flMin ~= 0 or self.m_flMax ~= 0 then
		local flStartValue = math.Clamp(self.m_OutValue, self.m_flMin, self.m_flMax)
		self.m_OutValue = flStartValue
	end
end

function ENT:InputSetHitMax(inputdata)
	self.m_flMax = tonumber(inputdata.value) or 1
	if self.m_flMax < self.m_flMin then
		self.m_flMin = self.m_flMax
    end
    
	self:UpdateOutValue(inputdata.pActivator, self.m_OutValue)
end

function ENT:InputSetHitMin(inputdata)
	self.m_flMin = tonumber(inputdata.value) or 1
	if self.m_flMax < self.m_flMin then
		self.m_flMax = self.m_flMin;
	end
    
	self:UpdateOutValue(inputdata.pActivator, self.m_OutValue)
end
	
function ENT:InputAdd(inputdata)
	if self.m_bDisabled then
		return
	end

	local fNewValue = self.m_OutValue + (tonumber(inputdata.value) or 1)
	self:UpdateOutValue(inputdata.pActivator, fNewValue)
end

function ENT:InputDivide(inputdata)
	if self.m_bDisabled then
		return
    end

    local fNum = tonumber(inputdata.value) or 1
	if fNum ~= 0 then
		local fNewValue = self.m_OutValue / fNum
		self:UpdateOutValue(inputdata.pActivator, fNewValue)
	else
		self:UpdateOutValue(inputdata.pActivator, self.m_OutValue)
	end
end

function ENT:InputMultiply(inputdata)
	if self.m_bDisabled then
		return
	end

	local fNewValue = self.m_OutValue * (tonumber(inputdata.value) or 1)
	self:UpdateOutValue(inputdata.pActivator, fNewValue)
end

function ENT:InputSetValue(inputdata)
	if self.m_bDisabled then
		return
	end

	self:UpdateOutValue(inputdata.pActivator, tonumber(inputdata.value) or 1)
end

function ENT:InputSetValueNoFire(inputdata)
	if self.m_bDisabled then
		return
    end

	local flNewValue = tonumber(inputdata.value) or 1
	if self.m_flMin ~= 0 or self.m_flMax ~= 0 then
		flNewValue = math.Clamp(flNewValue, self.m_flMin, self.m_flMax)
	end

	self.m_OutValue = flNewValue
end

function ENT:InputSubtract(inputdata)
	if self.m_bDisabled then
		return
    end

	local fNewValue = self.m_OutValue - (tonumber(inputdata.value) or 1)
	self:UpdateOutValue(inputdata.pActivator, fNewValue)
end

function ENT:InputGetValue(inputdata)
    self:Input("OnGetValue", inputdata.pActivator, inputdata.pCaller, self.m_OutValue)
end

function ENT:InputEnable(inputdata)
	self.m_bDisabled = false
end

function ENT:InputDisable(inputdata)
	self.m_bDisabled = true
end

function ENT:UpdateOutValue(pActivator, fNewValue)
	if self.m_flMin ~= 0 or self.m_flMax ~= 0 then
		if fNewValue >= self.m_flMax then
			if not self.m_bHitMax then
				self.m_bHitMax = true
                self:Input("OnHitMax", pActivator, self)
			end
		else
			self.m_bHitMax = false
		end

		if fNewValue <= self.m_flMin then
			if not m_bHitMin then
				self.m_bHitMin = true
                self:Input("OnHitMin", pActivator, self)
			end
		else
			self.m_bHitMin = false
		end

		fNewValue = math.Clamp(fNewValue, self.m_flMin, self.m_flMax)
	end

	self.m_OutValue = fNewValue
end

function ENT:KeyValue(key, value)
    key = string.lower(key)
    if key == "startvalue" then
        self.m_OutValue = tonumber(value) or 0
    elseif key == "min" then
        self.m_flMin = tonumber(value) or 0
    elseif key == "max" then
        self.m_flMax = tonumber(value) or 0
    elseif key == "startdisabled" then
        self.m_bDisabled = tobool(value)
    elseif string.Left(key, 2) == "on" then
        self:StoreOutput(key, value)
    end
end

function ENT:AcceptInput(name, caller, activator, arg)
    name = string.lower(name)
    
    local inputdata = {
        input = name,
        pActivator = activator,
        pCaller = caller,
        value = arg
    }

    if name == "add" then
        self:InputAdd(inputdata)
    elseif name == "divide" then
        self:InputDivide(inputdata)
    elseif name == "multiply" then
        self:InputMultiply(inputdata)
    elseif name == "setvalue" then
        self:InputSetValue(inputdata)
    elseif name == "setvaluenofire" then
        self:InputSetValueNoFire(inputdata)
    elseif name == "subtract" then
        self:InputSubtract(inputdata)
    elseif name == "sethitmax" then
        self:InputSetHitMax(inputdata)
    elseif name == "sethitmin" then
        self:InputSetHitMin(inputdata)
    elseif name == "enable" then
        self:InputEnable(inputdata)
    elseif name == "disable" then
        self:InputDisable(inputdata)
    elseif name == "getvalue" then
        self:InputGetValue(inputdata)
    elseif string.Left(name, 2) == "on" then
        self:TriggerOutput(name, activator, arg)
    end
end

scripted_ents.Register( ENT, "math_counter" )