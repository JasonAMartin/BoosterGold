module Core
	# handy notes
	# split urls with: .split('/').last
	def self.echo
		puts "Core is activated."
	end

	def self.trim_string(str)
  		# removes spaces, # working on this: tabs, new lines and returns from string.
  		return str.tr(' ', '')
	end

	def self.get_url(url, referer)
		return HTTParty.get(url,
							headers: {
							"User-Agent" => self.random_user_agent,
							"Referer" => referer
							})
	end

	def self.random_user_agent
		# add more here.
		ua = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
		return ua
	end
end
