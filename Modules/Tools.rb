module Tools
	def self.echo
		puts "Tools is activated."
  end

  def self.scrub_file_extensions(location)
    # Go into the media area and find all files without extensions
    extensions = ['.jpg', '.jpeg', '.gif', '.pdf', '.tiff', '.png']
    Dir.chdir(location)
    files = Dir.glob("**/*")
    files.each do |file|
      rename_file(file, location) if file.downcase.match /\.(jpe?g|png|tiff|pdf|gif)/
    end

  end

  def self.rename_file(file, location)
    puts "cool: #{location}#{file}"
  end
end
