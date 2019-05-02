module ComicPunchNet

	BASE_URL = 'https://comicpunch.net'
	MEDIUM_TYPE = 'comic'
	MODULE_CODE = 'ComicPunchNet'

	# example of full url for images:
	# https://comicpunch.net/reader/Batman-2016/Batman-2016-Issue-030/?q=fullchapter

	def self.echo
		puts "Hello, mod #{MODULE_CODE} worked"
	end

	def is_feeder
		return true
	end

	def self.scrape_title_data(limit=20)
		# using this site for feeder, so all titles/issues will be manually entered
		return true
	end

	def self.scrape_issue_data(title, id, url)
			# using this site for feeder, so all titles/issues will be manually entered
			return true
	end

	def self.scrape_image_data(title_id, url, issue_id, title)
		media_list = []
		i_id = url.match(/(Issue+)(.*\?)/)
    issue_name = i_id.to_s.sub('Issue-', '').sub('?','')
		puts "Working on images for #{issue_id}"
		page = HTTParty.get(url.gsub(' ', '%20') + '?q=fullchapter') # this site puts images on pages, but /full url puts them all on 1 page
		parse_page = Nokogiri::HTML(page)
		switch_css = '.picture'
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
