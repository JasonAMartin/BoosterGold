module Stats
	def self.display_stats
	  comic_titles = SETTINGS[:db].execute("select media_id from MediaTitles where media_type='comic'")
	  manga_titles = SETTINGS[:db].execute("select media_id from MediaTitles where media_type='manga'")
	  issues = SETTINGS[:db].execute('select * from Issues')
	  puts "~~~~~~~ STATS ~~~~~~~"
	  puts "Comic Titles: #{comic_titles.length}"
	  puts "Manga Titles: #{manga_titles.length}"
	  puts "Issues: #{issues.length}"
	  puts ""
	  puts "*** end of report ***"
	end
end
