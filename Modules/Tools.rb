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

  def self.fix_broken_images(location)
    bash_command = `find #{location} -type f -size -10k`
    broken_images = bash_command.split(/\n/)
    broken_images.each do |image|
      self.find_image(File.basename(image), image)
    end
  end

  def self.find_image(image_name, filesystem_image)
      puts "PROCESSNG: #{filesystem_image}"
      image_data = image_name.split(/[-|.]/).select { |item| (!item.match? /(jpg|png|pdf|tiff|jpeg|gif|SPECIAL)/i )}
      puts "--- #{image_data}"
      broken_image = SETTINGS[:db].execute('select image_id, image_url, issue_id from Images where issue_id = ? and image_url LIKE ?', [image_data[1], "%#{image_data[2]}%"])
      if broken_image.length == 1
        # get issue data
        puts "Image found: #{broken_image[0][2]}"
        issue_data = SETTINGS[:db].execute('select issue_id, issue_url from Issues where issue_id = ?', [broken_image[0][2]])

        if issue_data.length == 1
          # Image and Issue found, so delete image from filesystem, change downloaded to 2 in Images and change is_disabled to 1 in Issues.
          # Report issue
          SETTINGS[:db].execute('UPDATE Images set downloaded = 2 where image_id = ?', [broken_image[0][0]])
          SETTINGS[:db].execute('UPDATE Issues set is_disabled = 1, date_disabled = ? where issue_id = ?', [Date.today.to_s, broken_image[0][2]])
          puts "File found. Deleting: #{broken_image}"
          File.exist?(filesystem_image) ? File.delete(filesystem_image) : ''
        else
          puts "Issue Not Found - #{broken_image[0][2]}"
        end
        # broken image found
#              puts "#{image_data} -- #{broken_image[0][0]}"
      else
        SETTINGS[:db].execute('INSERT INTO BadImages (past_location, folder_key, issue_id, date_added) values (?,?,?,?)',
            [filesystem_image, image_data[0], image_data[1], Date.today.to_s])
        File.exist?(filesystem_image) ? File.delete(filesystem_image) : ''
      end
  end
end
