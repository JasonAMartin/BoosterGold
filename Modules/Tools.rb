require 'ruby-filemagic'
require 'mime/types'

module Tools
	def self.echo
		puts "Tools is activated."
  end

  def self.is_valid_file(file_type)
    extensions = ['image/jpg', 'image/jpeg', 'image/gif', '/pdf', 'image/tiff', 'image/png']
    valid = false
    extensions.each do |extension|
      if file_type.include? extension
        valid = true
      end
    end
    return valid
  end

  def self.scrub_file_extensions(location)
    # get all files
    Dir.chdir(location)
    files = Dir.glob("**/*")
    files.each do |file|
      fm = FileMagic.new(FileMagic::MAGIC_MIME)
      mime_type = fm.file(file)
      if (self.is_valid_file(mime_type))
        full_file = location + file
        current_file_extension = File.extname(full_file)
        file_extension = MIME::Types[mime_type][0].extensions[0]
        File.rename(full_file, full_file + '.' + file_extension) if (file_extension != current_file_extension)
      end
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
