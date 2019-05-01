module ReadComicOnline

	BASE_URL = 'http://readcomiconline.to'
	MEDIUM_TYPE = 'comic'
	MODULE_CODE = 'ReadComicOnline'
	NEED_TO_ALTER = true # set to true when a domain name change has occured
	OLD_DOMAINS = ['http://readcomiconline.com', 'http://readcomiconline.me']

	def self.echo
		puts "Hello, mod #{MODULE_CODE} worked"
	end

	def self.scrape_title_data
		# TODO: Make this function read how many pages there are. Right now, it just blindly does 50 pages.
		current_page = 1
		media_list = []
  		# iterate over pages
	  while current_page <= 20 #TODO: change to 50, also need time out
	    current_url = "#{BASE_URL}/ComicList/LatestUpdate?page=#{current_page}"
			# Use Selenium to get around CloudFlare
			options = Selenium::WebDriver::Chrome::Options.new
			options.add_argument('--headless')
			driver = Selenium::WebDriver.for :chrome, options: options
			driver.manage.timeouts.implicit_wait = 10
			driver.navigate.to current_url
			element = driver.find_element(:id => "headnav")
			#driver.manage.window.resize_to(800, 800)
			#driver.save_screenshot "readcomiconline-page#{current_page}.png"

			parse_page = Nokogiri::HTML(driver.page_source)
	    # grab all the comic book link names
	    parse_page.css('.listing a').map do |link|
	      pre_name = link.attr('href')
	      fixed_name = pre_name.sub('/Comic/', '').sub('/','')
	      # if name contains ?id=, it's a dupe link, so ignore it.
	      if fixed_name !~ /\?id=/
	        # add comic book to array
	        title_url = "#{BASE_URL}/Comic/#{fixed_name}"
			media_data = Hash.new {|h,k| h[k] = [] }
	        media_data[:title] = fixed_name
	        media_data[:source] = BASE_URL
	        media_data[:url] = title_url
	        media_data[:module] = MODULE_CODE
	        media_data[:medium] = MEDIUM_TYPE
	        media_list.push(media_data)
	      end
	    end
	    puts "Page #{current_page} complete."
	    current_page+=1
	  # end while loop
	  end
	  return media_list
	end

	def self.scrape_issue_data(title, id, url)
		media_list = []
		if NEED_TO_ALTER
			working_url = url
			OLD_DOMAINS.each do |u|
				working_url = url.sub(u, BASE_URL)
				url = working_url
			end
			puts "Altered url: #{url}"
		end
		puts "Trying to get issues for: #{title}"
		#page = HTTParty.get(url)
		# Use Selenium to get around CloudFlare
		options = Selenium::WebDriver::Chrome::Options.new
		options.add_argument('--headless')
		driver = Selenium::WebDriver.for :chrome, options: options
		driver.manage.timeouts.implicit_wait = 10
		driver.navigate.to url
		element = driver.find_element(:class => "listing")

		parse_page = Nokogiri::HTML(driver.page_source)
		# grab all issue links
		switch_css = '.listing a'
		parse_page.css(switch_css).map do |link|
    		issue_link = link.attr('href')
    		current_url = BASE_URL + issue_link
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
		if NEED_TO_ALTER
			working_url = url
			OLD_DOMAINS.each do |u|
				working_url = url.sub(u, BASE_URL)
				url = working_url
			end
			puts "Altered url: #{url}"
		end
		i_id = url.match(/(Issue+)(.*\?)/)
      	issue_name = i_id.to_s.sub('Issue-', '').sub('?','')
		puts "Working on images for #{issue_id}"
			#	page = HTTParty.get(url)

		# Use Selenium to get around CloudFlare
				options = Selenium::WebDriver::Chrome::Options.new
				options.add_argument('--headless')
				driver = Selenium::WebDriver.for :chrome, options: options
				driver.manage.timeouts.implicit_wait = 10
				driver.navigate.to url
				element = driver.find_element(:id => "containerRoot")
				page = driver.page_source
					driver.manage.window.resize_to(800, 800)
			driver.save_screenshot "readcomiconline-page-test.png"

      	parse_page = Nokogiri::HTML(page) #TODO: why is this here? Also need to grep on page, but getting error.
				image_data = page.scan /lstImages.push\(".{1,}=/
      	image_data.map do |link|
					image_url = link.sub('lstImages.push("', '').sub('=', '')
					puts image_url
        	image_updated_url = image_url + "?&&#{title}&&&#{issue_name}&&&&"
     		media_data = Hash.new {|h,k| h[k] = [] }
	        media_data[:source] = BASE_URL
	        media_data[:url] = image_updated_url
	        media_data[:module] = MODULE_CODE
	        media_data[:title_id] = title_id
	        media_data[:issue_id] = issue_id
	        media_data[:issue_title] = issue_name
	        media_list.push(media_data)
      	end
		return media_list
	end
end
