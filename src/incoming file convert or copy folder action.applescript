property extension_list : {"flac", "mp3", "m4a", "mkv", "mov", "mp4"}
property convert_extension_list : {"flac"}
property destination_path : "/Users/mshick/Dropbox/Incoming"

on adding folder items to theFolder after receiving these_items
	
	-- This should make the folder action wait until large files have finished copying to the folder
	set fSizes to {0}
	repeat
		tell application "System Events" to set end of fSizes to size of theFolder
		if (item -1 of fSizes) = (item -2 of fSizes) then exit repeat
		delay 1
	end repeat
	
	repeat with i from 1 to number of items in these_items
		set this_item to item i of these_items
		set the item_info to the info for this_item
		if folder of the item_info is true then
			process_folder(this_item)
		else
			if (alias of the item_info is false and the name extension of the item_info is in the extension_list) then
				process_item(this_item)
			end if
		end if
	end repeat
	
end adding folder items to

on process_folder(this_folder)
	set these_items to list folder this_folder without invisibles
	
	repeat with i from 1 to the count of these_items
		set this_item to alias ((this_folder as Unicode text) & (item i of these_items))
		set the item_info to info for this_item
		if folder of the item_info is true then
			process_folder(this_item)
		else
			if (alias of the item_info is false and the name extension of the item_info is in the extension_list) then
				process_item(this_item)
			end if
		end if
	end repeat
end process_folder

on process_item(this_item)
	try
		set the item_info to info for this_item
		if (the name extension of the item_info is in the convert_extension_list) then
			do shell script "/usr/local/bin/xld -f alac -o " & quoted form of POSIX path of destination_path & space & quoted form of POSIX path of this_item
		else
			tell application "Finder"
				copy file quoted form of POSIX path of this_item to folder quoted form of POSIX path of destination_path
			end tell
		end if
	on error error_message number error_number
		if the error_number is not -128 then
			tell application "Finder"
				activate
				display dialog error_message buttons {"Cancel"} default button 1 giving up after 120
			end tell
		end if
	end try
end process_item