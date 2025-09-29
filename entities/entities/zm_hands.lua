AddCSLuaFile()

/*ENT.Base = "gmod_hands"

function ENT:Initialize()
    local enty = self
    hook.Add("OnViewModelChanged", tostring(enty), function( vm, old, new )
        if not IsValid(enty) then return end

        if ( vm:GetOwner() ~= enty:GetOwner() ) then return end

        enty:SetOwner( vm:GetOwner() )
        enty:AttachToViewmodel( vm )
    end)

	self:SetNotSolid(true)
	self:DrawShadow(false)
	self:SetTransmitWithParent(true)
end*/

ENT.Type			= "anim"
ENT.RenderGroup		= RENDERGROUP_OTHER

local viewmodel_bones = {
	["ValveBiped.Bip01_L_Elbow"] = true,
	["ValveBiped.Bip01_L_UpperArm"] = true,
	["ValveBiped.Bip01_L_Forearm"] = true,
	["ValveBiped.Bip01_L_Hand"] = true,
	["ValveBiped.Bip01_L_Finger4"] = true,
	["ValveBiped.Bip01_L_Finger41"] = true,
	["ValveBiped.Bip01_L_Finger42"] = true,
	["ValveBiped.Bip01_L_Finger3"] = true,
	["ValveBiped.Bip01_L_Finger31"] = true,
	["ValveBiped.Bip01_L_Finger32"] = true,
	["ValveBiped.Bip01_L_Finger2"] = true,
	["ValveBiped.Bip01_L_Finger21"] = true,
	["ValveBiped.Bip01_L_Finger22"] = true,
	["ValveBiped.Bip01_L_Finger1"] = true,
	["ValveBiped.Bip01_L_Finger11"] = true,
	["ValveBiped.Bip01_L_Finger12"] = true,
	["ValveBiped.Bip01_L_Finger0"] = true,
	["ValveBiped.Bip01_L_Finger01"] = true,
	["ValveBiped.Bip01_L_Finger02"] = true,
	["ValveBiped.Bip01_R_Elbow"] = true,
	["ValveBiped.Bip01_R_UpperArm"] = true,
	["ValveBiped.Bip01_R_Forearm"] = true,
	["ValveBiped.Bip01_R_Hand"] = true,
	["ValveBiped.Bip01_R_Finger4"] = true,
	["ValveBiped.Bip01_R_Finger41"] = true,
	["ValveBiped.Bip01_R_Finger42"] = true,
	["ValveBiped.Bip01_R_Finger3"] = true,
	["ValveBiped.Bip01_R_Finger31"] = true,
	["ValveBiped.Bip01_R_Finger32"] = true,
	["ValveBiped.Bip01_R_Finger2"] = true,
	["ValveBiped.Bip01_R_Finger21"] = true,
	["ValveBiped.Bip01_R_Finger22"] = true,
	["ValveBiped.Bip01_R_Finger1"] = true,
	["ValveBiped.Bip01_R_Finger11"] = true,
	["ValveBiped.Bip01_R_Finger12"] = true,
	["ValveBiped.Bip01_R_Finger0"] = true,
	["ValveBiped.Bip01_R_Finger01"] = true,
	["ValveBiped.Bip01_R_Finger02"] = true,
	["ValveBiped.Bip01_L_Ulna"] = true,
	["ValveBiped.Bip01_R_Ulna"] = true,
	["ValveBiped.Bip01_R_Wrist"] = true,
	["ValveBiped.Bip01_L_Wrist"] = true,
	["ValveBiped.Bip01_L_Bicep"] = true,
	["ValveBiped.Bip01_R_Bicep"] = true,
}

local body_bones = {
	["ValveBiped.Bip01_Pelvis"] = true,
	["ValveBiped.Bip01_Spine"] = true,
	["ValveBiped.Bip01_Spine1"] = true,

	["ValveBiped.Bip01_R_Thigh"] = true,
	["ValveBiped.Bip01_R_Calf"] = true,
	["ValveBiped.Bip01_R_Foot"] = true,
	["ValveBiped.Bip01_R_Toe0"] = true,

	["ValveBiped.Bip01_L_Thigh"] = true,
	["ValveBiped.Bip01_L_Calf"] = true,
	["ValveBiped.Bip01_L_Foot"] = true,
	["ValveBiped.Bip01_L_Toe0"] = true,
}

local vector_zero = Vector( 0, 0, 0 )
local vec_up = Vector( 0, 0, 1 )

local M_Player = FindMetaTable("Player")
local M_Entity = FindMetaTable("Entity")
local M_VMatrix = FindMetaTable("VMatrix")

local VM_SetTranslation = M_VMatrix.SetTranslation
local VM_GetTranslation = M_VMatrix.GetTranslation
local VM_GetAngles = M_VMatrix.GetAngles
local VM_SetAngles = M_VMatrix.SetAngles
local VM_SetScale = M_VMatrix.SetScale

local E_GetBonePosition = M_Entity.GetBonePosition
local E_GetBoneMatrix = M_Entity.GetBoneMatrix
local E_SetBoneMatrix = M_Entity.SetBoneMatrix
local E_OnGround = M_Entity.OnGround
local E_EyeAngles = M_Entity.EyeAngles
local P_Crouching = M_Player.Crouching
local P_SyncAngles = M_Player.SyncAngles


local function BetterBonemerge( ent, bonecount )
	local vm = ent:GetParent()
	local pl = ent:GetOwner()

	if vm and vm:IsValid() and pl and pl:IsValid() then

		local eyeangles = E_EyeAngles( pl )

		if not ent.HideToBone then
			ent.HideToBone = ent:LookupBone( "ValveBiped.Bip01_Spine" )
		end

		local hide_to_bone = ent.HideToBone

		if not ent.ArmBones then
			ent.ArmBones = {}

			local arm_l = ent:LookupBone( "ValveBiped.Bip01_L_Hand" )
			if arm_l then
				for k, v in pairs( ent:GetChildBones( arm_l ) ) do
					local child_name = ent:GetBoneName( v )
					if child_name then
						ent.ArmBones[child_name] = true
					end
				end
			end

			local arm_r = ent:LookupBone( "ValveBiped.Bip01_R_Hand" )
			if arm_r then
				for k, v in pairs( ent:GetChildBones( arm_r ) ) do
					local child_name = ent:GetBoneName( v )
					if child_name then
						ent.ArmBones[child_name] = true
					end
				end
			end
		end

		if not ent.CachedBones then

			ent.CachedBones = {}

			for i=0, bonecount do

				if not ent.BoneTable then
					ent.BoneTable = {}
				end

				if not ent.BoneTable[i] then
					ent.BoneTable[i] = {}
				end

				local name
				local bonetable = ent.BoneTable

				if bonetable[ i ] and bonetable[ i ].bone_name then
					name = bonetable[ i ].bone_name
				else
					name = ent:GetBoneName( i )
					bonetable[ i ].bone_name = name
				end

				if not name then continue end

				local bone = i
				local bone_pl

				if bonetable[ i ] and bonetable[ i ].pl_bone then
					bone_pl = bonetable[ i ].pl_bone
				else
					bone_pl = pl:LookupBone( name )
					bonetable[ i ].pl_bone = bone_pl
				end

				if viewmodel_bones[name] then continue end
				if ent.ArmBones[name] then continue end

				ent.CachedBones[ #ent.CachedBones + 1 ] = i

			end

		end

		local cached = ent.CachedBones

		for k=1, #cached do

			local i = cached[ k ]

			local name
			local bonetable = ent.BoneTable

			if bonetable[ i ] and bonetable[ i ].bone_name then
				name = bonetable[ i ].bone_name
			else
				name = ent:GetBoneName( i )
				bonetable[ i ].bone_name = name
			end

			local bone = i
            local bone_pl

			if bonetable[ i ] and bonetable[ i ].pl_bone then
				bone_pl = bonetable[ i ].pl_bone
			else
				bone_pl = pl:LookupBone( name )
				bonetable[ i ].pl_bone = bone_pl
			end

			if bone then
				local m = E_GetBoneMatrix( ent, bone )

				if bone_pl then
					local pos, ang = E_GetBonePosition( pl, bone_pl ) --bone matrix doesnt seem to work when I try to get player bones in first person

					if m then
						if pos and ang then
							local translation = pos - P_SyncAngles( pl ):Forward() * 24
							local offset

							if P_Crouching( pl ) and !E_OnGround( pl ) then
								offset = vec_up * -22
							end

							if GAMEMODE.bCustomViewModelButNoLegs or eyeangles.p < 30 then
                                offset = eyeangles:Forward() * -75
                            end

							if offset then
								translation = translation + offset
							end

							VM_SetTranslation( m, translation )
							VM_SetAngles( m, ang )
						end

						if not body_bones[name] and hide_to_bone then
							local m_to = E_GetBoneMatrix( ent, hide_to_bone )
							if m_to then
								VM_SetScale( m, vector_zero )
								VM_SetTranslation( m, VM_GetTranslation( m_to ) )
							end
						end

						E_SetBoneMatrix( ent, bone, m )
					end

				end
			end
		end
	end
end


function ENT:Initialize()
	local enty = self
	hook.Add("OnViewModelChanged", tostring(enty), function( vm, old, new )
		if not IsValid(enty) then return end

		if ( vm:GetOwner() ~= enty:GetOwner() ) then return end

		enty:SetOwner( vm:GetOwner() )
		enty:AttachToViewmodel( vm )
	end)

	self:SetNotSolid( true )
	self:DrawShadow( false )
	self:SetTransmitWithParent( true ) -- Transmit only when the viewmodel does!
end

function ENT:DoSetup( ply )
	-- Set these hands to the player
	ply:SetHands( self )
	self:SetOwner( ply )

	if ply:GetInfo("zm_cl_custom_hands") == "1" then
		self:SetModel( ply:GetModel() )
		self:SetSkin( ply:GetSkin() )
		for k = 0, ply:GetNumBodyGroups() - 1 do
			self:SetBodygroup( k, ply:GetBodygroup( k ) or 0 )
		end
	else
		local info = player_manager.TranslatePlayerHands( player_manager.TranslateToPlayerModelName( ply:GetModel() ) )
		if ( info ) then
			self:SetModel( info.model )
			self:SetSkin( info.skin )
			self:SetBodyGroups( info.body )
		end
	end

    -- Attach them to the viewmodel
	local vm = ply:GetViewModel( 0 )
	self:AttachToViewmodel( vm )

	vm:DeleteOnRemove( self )
	ply:DeleteOnRemove( self )

	if ply:GetInfo("zm_cl_custom_hands") == "1" then
		self:SetPos( ply:GetPos() - vector_up * 64 )
		self:SetAngles( ply:GetAngles() )
	end
end

local defaultcolor = Vector( 62.0/255.0, 88.0/255.0, 106.0/255.0 )
function ENT:GetPlayerColor()
	local owner = self:GetOwner()
	if owner and owner:IsValid() and owner.GetPlayerColor then
		return owner:GetPlayerColor()
	end

	return defaultcolor
end

function ENT:AttachToViewmodel( vm )
	self:AddEffects( EF_BONEMERGE )
	self:SetParent( vm )
	self:SetMoveType( MOVETYPE_NONE )

	if self:GetOwner():GetInfo("zm_cl_custom_hands") ~= "1" then
		self:SetPos( Vector( 0, 0, 0 ) )
		self:SetAngles( Angle( 0, 0, 0 ) )
	end
end

function ENT:OnRemove()
	hook.Remove("OnViewModelChanged", tostring(self))
end

function ENT:SetSkinReplacmentIndex(Index)
    self.bSkinReplacmentIndex = Index
    if SERVER then
        self:SetNW2Int("bSkinReplacmentIndex", Index)
    end
end

function ENT:SetSkinReplacmentMat(Mat)
    self.bSkinReplacmentMat = Mat
    if SERVER then
        self:SetNW2Int("bSkinReplacmentMat", Mat)
    end
end

function ENT:Draw()
	if not self.AppliedBonemerge and GAMEMODE.bCustomViewModelHands then
		-- just in case
		local owner_valid = self:GetOwner() and self:GetOwner():IsValid() and IsValid( self:GetOwner():GetViewModel( 0 ) )
		if owner_valid then
			local vm = self:GetOwner():GetViewModel( 0 )
			self:SetParent( vm )

			self:SetLOD( 0 )
			self:AddCallback( "BuildBonePositions", BetterBonemerge )
			self.AppliedBonemerge = true
		end
	end

	if self.AppliedBonemerge and #self:GetCallbacks( "BuildBonePositions" ) <= 0 then
		self.AppliedBonemerge = false
	end

	local wep = MySelf:GetActiveWeapon()
	if wep:IsValid() and wep.DrawHands and wep:DrawHands(self) then return end

	render.SetColorModulation(1, 1, 1)
	self:DrawModel()
end
