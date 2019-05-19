require 'ruby-filemagic'
require 'mime/types'

module Tools
	def self.echo
		puts "Tools is activated."
  end

  def self.scrub_file_extensions(location)
    # Go into the media area and find all files without extensions
    #extensions = ['.jpg', '.jpeg', '.gif', '.pdf', '.tiff', '.png']
    Dir.chdir(location)
    files = Dir.glob("**/*")
    files.each do |file|
      puts "#{location}#{file}"
      #self.get_mime_type(location + file)
      #rename_file(file, location) if file.downcase.match /\.(jpe?g|png|tiff|pdf|gif)/
    end
  end

  def self.rename_file(file, location)
    puts "cool: #{location}#{file}"
  end

  def self.file_exists(file)
    return File.exist? file
  end

  def self.get_mime_type(file='')
    return if (file.empty?)
    return if (self.file_exists == false)
    # auto detect file's file-type
    current_file_extension = File.extname(file)
    fm = FileMagic.new(FileMagic::MAGIC_MIME)
    mime_type = fm.file(file)
    file_extension = MIME::Types[mime_type][0].extensions[0]
    File.rename(file, file + '.' + file_extension) if (file_extension != current_file_extension)
  end
end
