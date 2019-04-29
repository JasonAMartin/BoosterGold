module ReadComics

	BASE_URL = 'http://readcomics.net'
	MEDIUM_TYPE = 'comic'
	MODULE_CODE = 'ReadComics'

	def self.echo
		puts "Hello, mod #{MODULE_CODE} worked"
	end

	def self.scrape_title_data
		media_list = []
	    base = 'http://www.readcomics.net/'
	    list = 'comic-list'
	    page = HTTParty.get(base+list)
	    parse_page = Nokogiri::HTML(page)
	    parse_page.css('.series-col ul li a').map do |title|
	      current_title = title.text
	      current_url = title.attr('href')
	      final_title = current_url.sub('http://www.readcomics.net/comic/', '')
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
		page = HTTParty.get(url)
  		parse_page = Nokogiri::HTML(page)
  		# grab all issue links
  		switch_css = 'a.ch-name'
		parse_page.css(switch_css).map do |link|
    		issue_link = link.attr('href')
    		current_url = issue_link
    		media_data = Hash.new {|h,k| h[k] = [] }
	        media_data[:source] = BASE_URL
	        media_data[:url] = current_url
	        media_data[:module] = MODULE_CODE
	        media_data[:id] = id
	        media_data[:title] = title
	        media_list.push(media_data)
    	end
		return media_list
	end

	def self.scrape_image_data(title_id, url, issue_id, title)
	media_list = []
  	issue_title = 'failed'
	puts "Working on images for #{issue_id}"
		page = HTTParty.get(url)
		parse_page = Nokogiri::HTML(page)
		parse_page.css('#asset_2 select option').map do |pg|

		if !pg.nil?
			full_url = pg.attr('value')
      	end
      	puts ">> #{full_url}"
		# This is only image to the page containing the image.
	      if !full_url.nil?
	  			image_page = HTTParty.get(full_url)
	  			parse_holder = Nokogiri::HTML(image_page)
	  			# puts parse_holder
	  			puts "------------------------"
	  			image = parse_holder.css('#main_img')
	  			puts image
                                puts Time.now.strftime('%d/%m/%Y - %H:%M:%S')
	  			puts "-----------------------"
	  			if !image.empty?
		  			issue_title_data = parse_holder.css('#asset_1 select option').map do |itd|
			          if itd.attr('selected') == 'selected'
			            issue_title = itd.text
			          end
		      		end
		      		puts image
		  			image_url = image.attr('src').to_s
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
