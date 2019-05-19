module Stats
	def self.display_stats
	  comic_titles = SETTINGS[:db].execute("select media_id from MediaTitles where media_type='comic'")
		manga_titles = SETTINGS[:db].execute("select media_id from MediaTitles where media_type='manga'")
		pending_issues = SETTINGS[:db].execute('select issue_id, media_id, issue_url from Issues where checked=0')
		pending_images = SETTINGS[:db].execute("select image_id, issue_title, downloaded from Images where downloaded=0 and issue_title not null")
		total_images = SETTINGS[:db].execute("select image_id, issue_title, downloaded from Images where downloaded=1 and issue_title not null")
		broken_images = SETTINGS[:db].execute("select response from Images where response=400")

	  issues = SETTINGS[:db].execute('select * from Issues')
	  puts "~~~~~~~ STATS ~~~~~~~"
	  puts "Comic Titles: #{comic_titles.length}"
	  puts "Manga Titles: #{manga_titles.length}"
		puts "Issues: #{issues.length}"
		puts "Pending Issues: #{pending_issues.length}"
		puts "Pending Images: #{pending_images.length}"
		puts "Total Images Downloaded: #{total_images.length}"
		puts "Broken Images: #{broken_images.length}"
	  puts ""
	  puts "*** end of report ***"
	end

	def self.display_disabled_issues
			disabled_issues = SETTINGS[:db].execute("select issue_url, is_disabled, replacement_found from Issues where is_disabled=1 and (replacement_found is null or replacement_found = 0)")
			puts "DISABLED: #{disabled_issues.length}"
			disabled_issues.each do |issue|
				puts issue[0]
			end
			puts "DISABLED: #{disabled_issues.length}"
	end
end
