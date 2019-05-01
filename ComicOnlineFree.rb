module ComicOnlineFree

	BASE_URL = 'https://comiconlinefree.com'
	MEDIUM_TYPE = 'comic'
	MODULE_CODE = 'ComicOnlineFree'

	def self.echo
		puts "Hello, mod #{MODULE_CODE} worked"
	end

	def self.scrape_title_data(limit=20)
		# TODO: Make this function read how many pages there are. Right now, it just blindly does 50 pages.
		current_page = 1
		media_list = []
  		# iterate over pages
	  while current_page <= limit #TODO: change to 50, also need time out
	    current_url = "#{BASE_URL}/comic-updates/#{current_page}"
			page = HTTParty.get(current_url)
			parse_page = Nokogiri::HTML(page)
	    # grab all the comic book link names
	    parse_page.css('.hlb-name').map do |link|
			title_url = link.attr('href')
			title = link.text
			media_data = Hash.new {|h,k| h[k] = [] }
	        media_data[:title] = title_url
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

end
