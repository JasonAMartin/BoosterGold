module ComicCastle

	BASE_URL = 'http://www.comicastle.org'
	MEDIUM_TYPE = 'comic'
	MODULE_CODE = 'ComicCastle'

	def self.echo
		puts "Hello, mod #{MODULE_CODE} worked"
	end

	def self.scrape_title_data
		media_list = []
	    base = "#{BASE_URL}/manga-list.html?listType=allABC"
	    page = HTTParty.get(base)
	    parse_page = Nokogiri::HTML(page)
	    parse_page.css('.manga-1 a').map do |title|
	      current_title = title.text
	      current_url = title.attr('href')
			media_data = Hash.new {|h,k| h[k] = [] }
	        media_data[:title] = current_title
	        media_data[:source] = BASE_URL
	        media_data[:url] = current_url
	        media_data[:module] = MODULE_CODE
	        media_data[:medium] = MEDIUM_TYPE
	        media_list.push(media_data)
	    end
	  return media_list
	end

	def self.scrape_issue_data(title, id, url)
		media_list = []
		puts "Trying to get issues for: #{title}"
		full_url = "#{BASE_URL}/#{url}"
		page = HTTParty.get(full_url)
  		parse_page = Nokogiri::HTML(page)
  		# grab all issue links
  		switch_css = 'table.table-hover a'
		parse_page.css(switch_css).map do |link|
			is_link = link.css('b')
			if !is_link.empty?
	    		issue_link = link.attr('href')
				puts "Found link: #{issue_link}"
	    		current_url = issue_link
	    		media_data = Hash.new {|h,k| h[k] = [] }
		        media_data[:source] = BASE_URL
		        media_data[:url] = current_url
		        media_data[:module] = MODULE_CODE
		        media_data[:id] = id
		        media_data[:title] = title
		        media_list.push(media_data)
	    	end
    	end
		return media_list
	end

	def self.scrape_image_data(title_id, url, issue_id, title)
	media_list = []
  	issue_title = 'failed'
	puts "Working on images for #{issue_id}"
		page = HTTParty.get("#{BASE_URL}/#{url}")
		parse_page = Nokogiri::HTML(page)
		parse_page.css('.chapter-content select option').map do |pg|

		if !pg.nil?
			full_url = pg.attr('value')
      	end
      	puts ">> #{full_url}"
		# This is only image to the page containing the image.
	      if !full_url.nil?
	  			image_page = HTTParty.get("#{BASE_URL}/#{full_url}")
	  			parse_holder = Nokogiri::HTML(image_page)
	  			# puts parse_holder
	  			image = parse_holder.css('.chapter-img')
	  			if !image.empty?
		  			issue_title_data = parse_holder.css('.chapter-content select option').map do |itd|
			          if itd.attr('selected') == 'selected'
			            issue_title = itd.text
			          end
		      		end
		  			image_url = image.attr('src').to_s
		  			puts "logging: #{image_url} for issue: #{issue_title}"
		  			media_data = Hash.new {|h,k| h[k] = [] }
		  	        media_data[:source] = BASE_URL
		  	        media_data[:url] = image_url
		  	        media_data[:module] = MODULE_CODE
		  	        media_data[:title_id] = title_id
		  	        media_data[:issue_id] = issue_id
		  	        media_data[:issue_title] = issue_title
		  	        media_list.push(media_data)
		  	    end #image/empty
	      end
		end
	return media_list
	end
end
