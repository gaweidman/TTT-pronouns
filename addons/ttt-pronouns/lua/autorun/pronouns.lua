AddCSLuaFile()
-- made with <3 by QIncarnate
if SERVER then
	include("/gamemodes/terrortown/gamemode/cl_voice.lua")
end
AddCSLuaFile("/gamemodes/terrortown/gamemode/cl_voice.lua")
AddCSLuaFile("/gamemodes/terrortown/gamemode/vgui/sb_row.lua")
pronounsFrame = pronounsFrame or nil

print("LOADING PRONONUNS LIBRARY")

if CLIENT then
	net.Receive("PronounAlert", function(len)
		local response = net.ReadString()
		if response == "SUCCESS" then
			pronounsFrame:Remove()
		else
			Derma_Message(response, "Alert", "OK")
		end
	end)

	net.Receive("AskPronouns", function(len)
		pronounsFrame = vgui.Create("DFrame")
		pronounsFrame:SetSize(450, 200)
		pronounsFrame:SetTitle(" ")
		pronounsFrame:ShowCloseButton(false)
		pronounsFrame:MakePopup()
		pronounsFrame:Center()

		local lblTop = pronounsFrame:Add("DLabel")
		lblTop:Dock(TOP)
		lblTop:SetText("What are your pronouns?")

		local dropdown = pronounsFrame:Add("DComboBox")
		dropdown:SetSortItems(false)	
		dropdown:Dock(TOP)
		dropdown:SetValue("Select One")
		dropdown:AddChoice("He/Him")
		dropdown:AddChoice("She/Her")
		dropdown:AddChoice("It/Its")
		dropdown:AddChoice("They/Them")
		dropdown:AddChoice("Other (Please Specify)")
		dropdown:AddChoice("I don't really do the whole \"pronouns\" thing.")

		local lblOther = pronounsFrame:Add("DLabel")
		lblOther:Dock(TOP)
		lblOther:SetText("If not found in the dropdown, type in your pronouns below.")
		
		local entry = pronounsFrame:Add("DTextEntry")
		entry:Dock(TOP)
		
		entry:DockMargin(0, 0, 0, 5)

		local submitBtn = pronounsFrame:Add("DButton")
		submitBtn:Dock(TOP)
		submitBtn:DockMargin(175, 0, 175, 0)
		submitBtn:SetText("Submit")
		submitBtn.DoClick = function(this)
			net.Start("SetPronouns")
				local selection = dropdown:GetSelected()
				print("selection", selection)
				if selection == "Other (Please Specify)" then
					net.WriteString(entry:GetText() or "")
				else
					net.WriteString(selection)
				end
			net.SendToServer()
		end
		
		pronounsFrame:SetTall(lblTop:GetTall() + dropdown:GetTall() + lblOther:GetTall() + entry:GetTall() + submitBtn:GetTall() + 10*2 + 5*4)
	end)
else
	util.AddNetworkString("SetPronouns")
	util.AddNetworkString("PronounAlert")
	util.AddNetworkString("AskPronouns")

	net.Receive("SetPronouns", function(len, ply)
		local response = net.ReadString()
		net.Start("PronounAlert")
			if response == "I don't really do the whole \"pronouns\" thing." then
				net.WriteString("Everybody has pronouns, whether they're aware of it or not. We respectfully recommend you educate yourself.")
			elseif response == "Select One" then
				net.WriteString("You have not selected or written in your pronouns!")
			elseif #response > 30 then
				net.WriteString("Your response was too long. If you are receiving this message in error, contact server staff.")
			elseif !string.match(response, "%a+/%a+[%a/]+") then
				net.WriteString("Pronouns must be in either x/x or x/x/x format.")
			else
				net.WriteString("SUCCESS")

				ply:SetNW2String("pronouns", response)
				if file.Exists("pronouns.txt", "DATA") then
					local pronounTbl = util.JSONToTable(file.Read("pronouns.txt"))
					pronounTbl[ply:AccountID()] = response
					file.Write("pronouns.txt", util.TableToJSON(pronounTbl))
				else
					local pronounTbl = {}
					pronounTbl[ply:AccountID()] = response
					file.Write("pronouns.txt", util.TableToJSON(pronounTbl))
				end
			end
		net.Send(ply)
	end)

	hook.Add("PlayerInitialSpawn", "SetPronouns", function(ply, transition)
		timer.Simple(1, function()
			if !file.Exists("projectrevival/ttt", "DATA") then
				file.CreateDir("projectrevival/ttt")
			end

			local pronounTbl = util.JSONToTable(file.Read("pronouns.txt", "DATA"))
			local pronouns = pronounTbl[ply:AccountID()]
			if pronouns then
				ply:SetNW2String("pronouns", pronouns)
			else 
				net.Start("AskPronouns")
				net.Send(ply)
			end
		end)
		
	end)

	hook.Add("PlayerSay", "PronounsCommand", function(speaker, text, teamChat)
		if text == "!pronouns" then
			if !file.Exists("projectrevival/ttt", "DATA") then
				file.CreateDir("projectrevival/ttt")
			end

			local pronounTbl = util.JSONToTable(file.Read("pronouns.txt", "DATA"))
			local pronouns = pronounTbl[speaker:SteamID64()]
			net.Start("AskPronouns")
			net.Send(speaker)
			return false
		end
	end)
end

