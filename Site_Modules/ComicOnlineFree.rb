module ComicOnlineFree

	BASE_URL = 'https://comiconlinefree.com'
	MEDIUM_TYPE = 'comic'
	MODULE_CODE = 'ComicOnlineFree'

	def self.echo
		puts "Hello, mod #{MODULE_CODE} worked"
	end

	def self.is_feeder
		return false
	end

	def self.scrape_title_data(limit=20)
		# TODO: Make this function read how many pages there are. Right now, it just blindly does 50 pages.
		current_page = 1
		media_list = []
  		# iterate over pages
	  while current_page <= limit.to_i #TODO: change to 50, also need time out
	    current_url = "#{BASE_URL}/comic-updates/#{current_page}"
			page = HTTParty.get(current_url)
			parse_page = Nokogiri::HTML(page)
	    # grab all the comic book link names
	    parse_page.css('.hlb-name').map do |link|
			title_url = link.attr('href')
			title = link.text
			media_data = Hash.new {|h,k| h[k] = [] }
	        media_data[:title] = title
	        media_data[:source] = BASE_URL
	        media_data[:url] = title_url
	        media_data[:module] = MODULE_CODE
	        media_data[:medium] = MEDIUM_TYPE
	        media_list.push(media_data)
	    end
	    puts "Page #{current_page} complete."
	    current_page+=1
	  # end while loop
	  end
	  return media_list
	end

	def self.scrape_issue_data(title, id, url)
		media_list = []
		puts "Trying to get issues for: #{title}"
		page = HTTParty.get(url)
		parse_page = Nokogiri::HTML(page)
		# grab all issue links
		switch_css = '.ch-name'
		parse_page.css(switch_css).map do |link|
    		issue_link = link.attr('href')
				current_url = issue_link
				link_title = link.text
    		media_data = Hash.new {|h,k| h[k] = [] }
	        media_data[:source] = BASE_URL
	        media_data[:url] = current_url
	        media_data[:module] = MODULE_CODE
	        media_data[:id] = id
	        media_data[:title] = link_title
	        media_list.push(media_data)
		end
		return media_list
	end


	def self.scrape_image_data(title_id, url, issue_id, title)
		media_list = []
		i_id = url.match(/(Issue+)(.*\?)/)
    issue_name = i_id.to_s.sub('Issue-', '').sub('?','')
		puts "Working on images for #{issue_id}"
		page = HTTParty.get(url.gsub(' ', '%20') + '/full') # this site puts images on pages, but /full url puts them all on 1 page
		parse_page = Nokogiri::HTML(page)
		switch_css = '.chapter_img'
		parse_page.css(switch_css).each_with_index.map do |link, index|
			image_url = link.attr('src')
			puts image_url
      image_updated_url = image_url + "?&&#{title}&&&#{issue_name}&&&&"
			media_data = Hash.new {|h,k| h[k] = [] }
				media_data[:source] = BASE_URL
				media_data[:url] = image_updated_url
				media_data[:module] = MODULE_CODE
				media_data[:title_id] = title_id
				media_data[:issue_id] = issue_id
				media_data[:issue_title] = issue_name
				media_data[:sequence] = index
				media_list.push(media_data)
    end
		return media_list
	end
end
