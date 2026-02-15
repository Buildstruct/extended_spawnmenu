
AddCSLuaFile()

if ( SERVER ) then return end

language.Add( "spawnmenu.category.addonslegacy", "Addons - Legacy" )
language.Add( "spawnmenu.category.downloads", "Downloads" )

local function AddRecursive( pnl, folder )
	local files, folders = file.Find( folder .. "*", "MOD" )

	for k, v in pairs( files or {} ) do
		if ( !string.EndsWith( v, ".mdl" ) ) then continue end

		local cp = spawnmenu.GetContentType( "model" )
		if ( cp ) then
			local mdl = folder .. v
			mdl = string.sub( mdl, string.find( mdl, "models/" ), string.len( mdl ) )
			mdl = string.gsub( mdl, "models/models/", "models/" )
			cp( pnl, { model = mdl } )
		end
	end

	for k, v in pairs( folders or {} ) do AddRecursive( pnl, folder .. v .. "/" ) end
end

local function CountRecursive( folder )
	local files, folders = file.Find( folder .. "*", "MOD" )
	local val = 0

	for k, v in pairs( files or {} ) do if ( string.EndsWith( v, ".mdl" ) ) then val = val + 1 end end
	for k, v in pairs( folders or {} ) do val = val + CountRecursive( folder .. v .. "/" ) end
	return val
end

hook.Add( "PopulateContent", "LegacyAddonProps", function( pnlContent, tree, node )

	if ( !IsValid( node ) or !IsValid( pnlContent ) ) then
		print( "!!! Extended Spawnmenu: FAILED TO INITALIZE PopulateContent HOOK FOR LEGACY ADDONS!!!" )
		print( "!!! Extended Spawnmenu: FAILED TO INITALIZE PopulateContent HOOK FOR LEGACY ADDONS!!!" )
		print( "!!! Extended Spawnmenu: FAILED TO INITALIZE PopulateContent HOOK FOR LEGACY ADDONS!!!" )
		return
	end

	local ViewPanel = vgui.Create( "ContentContainer", pnlContent )
	ViewPanel:SetVisible( false )

	local addons = {}

	local _files, folders = file.Find( "addons/*", "MOD" )
	for _, f in pairs( folders ) do

		if ( !file.IsDir( "addons/" .. f .. "/models/", "MOD" ) ) then continue end

		local count = CountRecursive( "addons/" .. f .. "/models/", "MOD" )
		if ( count == 0 ) then continue end

		table.insert( addons, {
			name = f,
			count = count,
			path = "addons/" .. f .. "/models/"
		} )

	end

	local LegacyAddons = node:AddNode( "#spawnmenu.category.addonslegacy", "icon16/folder_database.png" )
	for _, f in SortedPairsByMemberValue( addons, "name" ) do

		local models = LegacyAddons:AddNode( f.name .. " (" .. f.count .. ")", "icon16/bricks.png" )
		models.DoClick = function()
			ViewPanel:Clear( true )
			AddRecursive( ViewPanel, f.path )
			pnlContent:SwitchPanel( ViewPanel )
		end

	end

	--[[ -------------------------- DOWNLOADS -------------------------- ]]

	local fi, fo = file.Find( "download/models", "MOD" )
	if ( !fi && !fo ) then return end

	local Downloads = node:AddFolder( "#spawnmenu.category.downloads", "download/models", "MOD", false, false, "*.*" )
	Downloads:SetIcon( "icon16/folder_database.png" )

	Downloads.OnNodeSelected = function( self, selectedNode )
		ViewPanel:Clear( true )

		local path = selectedNode:GetFolder()

		if ( !string.EndsWith( path, "/" ) && string.len( path ) > 1 ) then path = path .. "/" end
		local path_mdl = string.sub( path, string.find( path, "/models/" ) + 1 )

		for k, v in pairs( file.Find( path .. "/*.mdl", selectedNode:GetPathID() ) ) do

			local cp = spawnmenu.GetContentType( "model" )
			if ( cp ) then
				cp( ViewPanel, { model = path_mdl .. "/" .. v } )
			end

		end

		pnlContent:SwitchPanel( ViewPanel )
	end

end )

--[[ ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ ]]

-- I spent too much time on this than I care to admit
hook.Add( "PopulatePropMenu", "rb655_LoadLegacySpawnlists", function()

	local sid = 0 --table.Count( spawnmenu.GetPropTable() )

	--local added = false

	for id, spawnlist in pairs( file.Find( "settings/spawnlist/*.txt", "MOD" ) ) do
		local content = file.Read( "settings/spawnlist/" .. spawnlist, "MOD" )
		if ( !content ) then continue end

		--[[local is = string.find( content, "TableToKeyValues" )
		if ( is != nil ) then continue end

		for id, t in pairs( spawnmenu.GetPropTable() ) do -- This somehow freezes the game when opening Q menu => FUCK THIS SHIT
			if ( t.name == "Legacy Spawnlists" ) then
				added = true
				sid = t.id
			end
		end

		if ( !added ) then
			spawnmenu.AddPropCategory( "rb655_legacy_spawnlists", "Legacy Spawnlists", {}, "icon16/folder.png", sid, 0 )
			added = true
		end]]

		content = util.KeyValuesToTable( content )

		if ( !content.entries or content.contents ) then continue end

		local contents = {}

		for eid, entry in pairs( content.entries ) do
			if ( type( entry ) == "table" ) then entry = entry.model end
			table.insert( contents, { type = "model", model = entry } )
		end

		if ( !content.information ) then content.information = { name = spawnlist } end

		spawnmenu.AddPropCategory( "settings/spawnlist/" .. spawnlist, content.information.name, contents, "icon16/page.png", sid + id, sid )

	end

end )
