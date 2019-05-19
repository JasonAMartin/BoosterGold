module Stats
	def self.display_stats
	  comic_titles = SETTINGS[:db].execute("select media_id from MediaTitles where media_type='comic'")
		manga_titles = SETTINGS[:db].execute("select media_id from MediaTitles where media_type='manga'")
		pending_issues = SETTINGS[:db].execute('select issue_id, media_id, issue_url from Issues where checked=0')
		pending_images = SETTINGS[:db].execute("select image_id, issue_title, downloaded from Images where downloaded=0 and issue_title not null")
		total_images = SETTINGS[:db].execute("select image_id, issue_title, downloaded from Images where downloaded=1 and issue_title not null")

	  issues = SETTINGS[:db].execute('select * from Issues')
	  puts "~~~~~~~ STATS ~~~~~~~"
	  puts "Comic Titles: #{comic_titles.length}"
	  puts "Manga Titles: #{manga_titles.length}"
		puts "Issues: #{issues.length}"
		puts "Pending Issues: #{pending_issues.length}"
		puts "Pending Images: #{pending_images.length}"
		puts "Total Images Downloaded: #{total_images.length}"
	  puts ""
	  puts "*** end of report ***"
	end
end
