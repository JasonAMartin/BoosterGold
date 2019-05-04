module MangaPanda

	BASE_URL = 'http://mangapanda.com'
	MEDIUM_TYPE = 'manga'
	MODULE_CODE = 'MangaPanda'
	
	def self.echo
		puts "Hello, mod #{MODULE_CODE} worked"
	end

	def self.scrape_title_data
		media_list = []
		url = "http://www.mangapanda.com/alphabetical"
  		site = "http://www.mangapanda.com"
  		page = HTTParty.get(url)
  		parse_page = Nokogiri::HTML(page)
  		parse_page.css('ul.series_alpha li a').map do |link|
    		media_data = Hash.new {|h,k| h[k] = [] }
	        media_data[:title] = link.text
	        media_data[:source] = BASE_URL
	        media_data[:url] = link.attr('href')
	        media_data[:module] = MODULE_CODE
	        media_data[:medium] = MEDIUM_TYPE
	        media_list.push(media_data)
  		end
  		return media_list
	end

	def self.scrape_issue_data(title, id, url)
		media_list = []
		puts "Trying to get issues for: #{title}"
		if url.include?('http')
			page = HTTParty.get(url)
		else
			page = HTTParty.get(BASE_URL + url)
		end
  		parse_page = Nokogiri::HTML(page)
  		parse_page.css('#listing a').map do |issue|
    		title = issue.text
    		media_url = issue.attr('href')
    		full_url = BASE_URL + media_url
    		media_data = Hash.new {|h,k| h[k] = [] }
	        media_data[:source] = BASE_URL
	        media_data[:url] = full_url
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
  		parse_page.css('#pageMenu option').map do | image |
    		full_url = BASE_URL + image.attr('value')
    		# This is only image to the page containing the image. 
    		image_page = HTTParty.get(full_url)
    		parse_holder = Nokogiri::HTML(image_page)
    		image = parse_holder.css('#imgholder img')
    		issue_title_data = parse_holder.css('#selectmanga select option').map do |itd|
	          if itd.attr('selected') == 'selected'
	            issue_title = itd.text
	          end
      		end
    		image_url = image.attr('src').to_s
    		media_data = Hash.new {|h,k| h[k] = [] }
	        media_data[:source] = BASE_URL
	        media_data[:url] = image_url
	        media_data[:module] = MODULE_CODE
	        media_data[:title_id] = title_id
	        media_data[:issue_id] = issue_id
	        media_data[:issue_title] = issue_title
	        media_list.push(media_data)
  		end
		return media_list
	end
end
