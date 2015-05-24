property red : 2 -- error
property yellow : 3 -- processing
property green : 6 -- processed

property audio_extension_list : {"flac", "mp3", "m4a"}
property audio_convert_list : {"flac"}
property audio_destination_folder : "/Volumes/Storage/Music/iTunes/iTunes Media/Automatically Add to iTunes"
property video_extension_list : {"mkv"}
property video_convert_list : {"mkv"}
property video_destination_folder : "/Volumes/Storage/Movies/Films"
property tmp_folder : "/Users/mshick/.folder-actions/tmp"
property processing_timeout : 60 * 60 -- 1 hour
property processing_window : 100 * 24 * 60 * 60 -- 48 hours
property log_file : "/Users/mshick/.folder-actions/folder-actions.log"

on adding folder items to this_folder after receiving added_items
	global queued_items
	set queued_items to {}
	
	global temp_files
	set temp_files to {}
	
	with timeout of (processing_timeout) seconds
		try
			set file_sizes to {0}
			repeat
				tell application "System Events" to set end of file_sizes to size of this_folder
				if (item -1 of file_sizes) = (item -2 of file_sizes) then exit repeat
				delay 1
			end repeat
			
			tell application "Finder"
				-- for the items added
				repeat with item_ in added_items
					if label index of item_ is red then
						exit repeat
					else if kind of item_ is "Folder" then
						my handle_folder(item_)
					else
						my handle_item(item_)
					end if
				end repeat
			end tell
		on error error_message number error_number
			handle_error(error_message, error_number, added_items)
		end try
		
		-- process any queued files
		-- queued()
		
		-- invoke cleanup to remove any temp files
		cleanup()
	end timeout
end adding folder items to

on handle_folder(folder_)
	tell application "Finder" to set items_ to every file in folder_ as alias list
	try
		tell application "Finder"
			repeat with item_ in items_
				if kind of item_ is "Folder" then
					my handle_folder(item_)
				else
					my handle_item(item_)
				end if
			end repeat
		end tell
	on error error_message number error_number
		handle_error(error_message, error_number, items_)
	end try
end handle_folder

on handle_item(item_)
	
	try
		tell application "Finder"
			
			if label index of item_ is red then
				set _process to false
			else if label index of item_ is yellow then
				set _process to false
			else if label index of item_ is green then
				set _process to false
			else
				set _process to true
			end if
			
			if _process then
				set label index of item_ to yellow
				my process_item(item_)
			end if
			
		end tell
	on error error_message number error_number
		set items_ to {}
		set end of items_ to item_
		handle_error(error_message, error_number, items_)
	end try
	
	
end handle_item

on handle_error(error_message, error_number, items_)
	if the error_number is not -128 then
		my WriteLog(error_message)
	end if
	tell application "Finder"
		repeat with item_ in items_
			set label index of item_ to red
		end repeat
	end tell
end handle_error

on process_item(item_)
	
	set item_info to info for item_
	set current_date to (current date) - processing_window
	set item_date to creation date of item_info
	
	if (item_date > current_date) then
		if (alias of the item_info is false and the name extension of the item_info is in the audio_extension_list) then
			process_audio_item(item_)
		else if (alias of the item_info is false and the name extension of the item_info is in the video_extension_list) then
			process_video_item(item_)
		end if
	end if
	
	tell application "Finder"
		set label index of item_ to green
	end tell
	
end process_item

on process_audio_item(this_item)
	global queued_items
	global temp_files
	
	set the item_info to info for this_item
	set destination_folder to audio_destination_folder
	
	try
		if (the name extension of the item_info is in the audio_convert_list) then
			my WriteLog("Converting: " & the name of the item_info)
			set temp_file to tmp_folder & "/" & replace_chars(the name of the item_info, the name extension of item_info, "m4a")
			set command to "/usr/local/bin/ffmpeg -i " & quoted form of POSIX path of this_item & " -map 0:0 -acodec alac -movflags +faststart " & quoted form of temp_file
			
			do shell script command
			set command to "/bin/mv " & quoted form of temp_file & space & quoted form of destination_folder
			do shell script command
			-- set end of temp_files to temp_file
			-- set queue_item to {filepath:temp_file, destination:destination_folder}
			-- set end of queued_items to queue_item
		else
			my WriteLog("Copying: " & the name of the item_info)
			set copy_file to POSIX path of this_item
			set command to "/bin/cp " & quoted form of copy_file & space & quoted form of destination_folder
			do shell script command
		end if
		
		-- background the process so we can close out ASAP
		-- do shell script "nohup " & command & " 2> " & quoted form of log_file & " > /dev/null &"
		
	on error error_message number error_number
		handle_error(error_message, error_number)
	end try
	
end process_audio_item

on process_video_item(this_item)
	global queued_items
	global temp_files
	
	set the item_info to info for this_item
	set destination_folder to video_destination_folder
	
	try
		if (the name extension of the item_info is in the video_convert_list) then
			my WriteLog("Converting: " & the name of the item_info)
			set destination_file to destination_folder & "/" & replace_chars(the name of the item_info, the name extension of item_info, "m4v")
			set command to "/usr/local/bin/mkvtomp4 --no-summary --tmp=" & quoted form of tmp_folder & " --mp4box=/usr/local/bin/mp4box --mkvinfo=/usr/local/bin/mkvinfo --mkvextract=/usr/local/bin/mkvextract --ffmpeg=/usr/local/bin/ffmpeg --overwrite --use-audio-passthrough --audio-codec=libfaac --subtitles-track=MAIN --output=" & quoted form of destination_file & " -- " & quoted form of POSIX path of this_item
		else
			my WriteLog("Copying: " & the name of the item_info)
			set command to "/bin/cp " & quoted form of POSIX path of this_item & space & quoted form of destination_folder
		end if
		
		do shell script command & " >> " & quoted form of log_file & " 2>&1"
		-- background the process so we can close out ASAP
		-- do shell script "nohup " & command & " 2> " & quoted form of log_file & " > /dev/null &"
		
	on error error_message number error_number
		handle_error(error_message, error_number)
	end try
	
end process_video_item

on replace_chars(this_text, search_string, replacement_string)
	
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
	
end replace_chars

on WriteLog(the_text)
	set log_date to (current date) as Çclass isotÈ as string
	set log_text to "[" & log_date & "]" & space & the_text
	my write_to_file(log_text, log_file)
end WriteLog

on write_to_file(this_data, target_file)
	try
		do shell script "echo " & quoted form of this_data & " >> " & quoted form of target_file
	on error
		-- do nothing
	end try
end write_to_file

on queued()
	global queued_items
	repeat with i from 1 to the count of queued_items
		set queued_item to item i of queued_items
		do shell script "/bin/cp " & quoted form of filepath of queued_item & space & quoted form of destination of queued_item
	end repeat
end queued

on cleanup()
	global temp_files
	repeat with i from 1 to the count of temp_files
		set temp_file to item i of temp_files
		do shell script "rm -f " & quoted form of temp_file
	end repeat
end cleanup
