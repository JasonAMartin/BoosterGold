####################
# BoosterGold
# version: 0.6
# last update: major re-write from Pstore to Sqlite3
#
#
# This script is designed to liberate comic book images from a website.
# There are two phases: data building and operations.
#
# Data building examples (general flow: comics > issues > images):
#
# $ ruby Skeets.rb updatetitles
#
# $ ruby Skeets.rb updateissues
#
# $ ruby Skeets.rb updateimages
#
# $ ruby Skeets.rb downloadimages
#
# Setup:
#
# 1. Alter path to the DB.
#
# 2. Make sure you have all the required gems ($ gem install <whatever>).
#
# 3. Edit the SETTINGS section as desired.
#
# 4. Run the desired task and profit.
#
####################

require 'pstore'
require 'sqlite3' #
require 'httparty' #
require 'nokogiri' #
require 'json'
require 'csv'
require 'open-uri'
require 'typhoeus' #
require 'fileutils'
require 'celluloid/current'
require "selenium-webdriver"

# Load custom modules
CUSTOM_MODS = []
$LOAD_PATH << '.'
require_relative './Modules/Core'
require_relative './Modules/Tools'
require 'Stats'
mod_array = ['ComicOnlineFree', 'ComicPunchNet']
# mod_array = ['ComicCastle', 'ReadComicOnline', 'ReadComics']
mod_array.each do |mod|
  require_relative './Site_Modules/' + mod
  CUSTOM_MODS.push(mod)
end
# End load custom modules

# SETTINGS

SETTINGS = {
  savedirno: '/run/media/serabyte/HORDE1/',
  savedir: '/run/media/serabyte/HORDE1/',
  comicDirName: 'Comics',
  mangaDirName: 'Manga',
  scrape_pages: 50,
  max_downloads: 10,
  minimum_image_threshold: 6,
  db: SQLite3::Database.new('../BoosterGoldDatabase/BoosterGold.db')
}.freeze

# STARTING NEW MODULE CODE

class ImageWorker
  include Celluloid

  def process_page(item)
    puts item[1]
      # puts "Inside ImageWorker: #{item}"
      title_data = SETTINGS[:db].execute('select module, name from MediaTitles where media_id = ?', [item[1]])
      mod = Kernel.const_get(title_data[0][0].to_s) # TODO: If a module is in DB, but now disabled, this will break!
      this_title = title_data[0][1].to_s
      image_data = mod.scrape_image_data(item[1], item[2], item[0], this_title) # note: Will add title later or remove.
      # puts "Looking up image data for #{title_data[0][1].to_s}"
      puts "#{item[0]} - sending to method at #{Time.now.strftime('%d/%m/%Y - %H:%M:%S')}"
      update_image_data(image_data, item[0])
      # Update issue as checked
      puts "About to update DB for #{item[0]} at #{Time.now.strftime('%d/%m/%Y - %H:%M:%S')}"
      SETTINGS[:db].execute('UPDATE Issues set checked=1 where issue_id=?', [item[0]])
      puts "Finished page for #{item[0]} at #{Time.now.strftime('%d/%m/%Y - %H:%M:%S')}"
  end
end


def get_title_data(args)
  CUSTOM_MODS.each do |m|
    mod = Kernel.const_get(m)
    if not mod.is_feeder
      puts "Updating for module: #{mod}"
      title_data = mod.scrape_title_data(args[1])
      update_title_data(title_data)
    end
  end
  puts "Updating titles complete."
end

def update_title_data(data)
  # takes array of data
  # check if item exists in DB. If not, add it.
  data.each do |item|
    does_exits = SETTINGS[:db].execute('select * from MediaTitles where name=? and module=? and media_type=?', [item[:title], item[:module], item[:medium]])
    if does_exits.empty?
      puts "Adding new item: #{item[:title]} from #{item[:module]}"
      folder_key = Core.createFolderKey(item[:title])
      SETTINGS[:db].execute('INSERT INTO MediaTitles (name, source, title_url, module, media_type, folder_key) values (?,?,?,?,?,?)',
        [item[:title], item[:source], item[:url], item[:module], item[:medium], folder_key])
      # check if folder_key exists in FolderKeys table. If not, add it.
      has_key = SETTINGS[:db].execute('select folder_key from FolderKeys where folder_key=?', [folder_key])
      if has_key.empty?
        SETTINGS[:db].execute('INSERT INTO FolderKeys (folder_key, pretty_name) values (?,?)', [folder_key, item[:title]])
      end
    end
  end
end

def get_issue_data(limit)
  this_day = Time.now.strftime('%d/%m/%Y')
  CUSTOM_MODS.each do |m|
    mod = Kernel.const_get(m)
    if not mod.is_feeder
      puts "Updating for module: #{mod}"
      # look up titles
      data = SETTINGS[:db].execute('select media_id, name, last_checked, title_url from MediaTitles where module=? and (is_disabled<>? and (last_checked<>? or last_checked is null)) LIMIT ?', [m, '1', this_day, limit])
      data.each do |item|
        if this_day != item[2]
          issue_data = mod.scrape_issue_data(item[1], item[0], item[3])
          update_issue_data(issue_data)
        end
        # Update title as checked for today
        SETTINGS[:db].execute('UPDATE MediaTitles set last_checked=? where media_id=?', [this_day, item[0]])
      end
    end
  end
  puts "Updating issue data complete."
end

def update_issue_data(data)
  # check if issue is in DB. If not, add it.
  data.each do |item|
    does_exits = SETTINGS[:db].execute('select * from Issues where media_id=? and issue_url=?', [item[:id], item[:url]])
    if does_exits.empty?
      puts "Adding new issue: #{item[:title]} from #{item[:module]}"
      SETTINGS[:db].execute('INSERT INTO Issues (media_id, issue_url) values (?,?)', [item[:id], item[:url]])
    end
  end
end

def get_image_data(limit)
    # look up issues
    image_pool = ImageWorker.pool(size: 10)
    data = SETTINGS[:db].execute('select issue_id, media_id, issue_url from Issues where checked=0 LIMIT ?', [limit.to_i])
    # got issues, iterate and get image data
    data.each do |item|
      # lookup comic title for title and module info.
      image_pool.future(:process_page, item)
    end
end

def update_image_data(data, id)
  # check if image is in DB. If not, add it.
  puts "#{id} entering method at #{Time.now.strftime('%d/%m/%Y - %H:%M:%S')}"
  data.each do |item|
    # does_exits = SETTINGS[:db].execute('select * from Images where media_id=? and issue_id=? and image_url=?', [item[:title_id], item[:issue_id], item[:url]])
    #if does_exits.empty?
      title = item[:issue_title]
      puts item
      if title.empty?
        title = "SPECIAL-#{item[:issue_id]}"
      end

      # puts "Adding new image for issue id: #{item[:issue_id]} from #{item[:module]}"
      SETTINGS[:db].execute('INSERT INTO Images (issue_id, media_id, image_url, source, module, issue_title, sequence) values (?,?,?,?,?,?,?)',
        [item[:issue_id], item[:title_id], item[:url], item[:source], item[:module], title, item[:sequence]])

      # puts "Attempting to add issue title of #{title}"
      SETTINGS[:db].execute('UPDATE Issues set issue_title=? where issue_title is null and issue_id=?', [title, item[:issue_id]])
    # end
  end
  puts "#{id} has completed method at #{Time.now.strftime('%d/%m/%Y - %H:%M:%S')}"
end

def lookup_media_id(title)
  titles = SETTINGS[:db].execute('select name, media_id from MediaTitles where name LIKE ?', ["%#{title}%"])
  puts "Results for #{title}:"
  titles.each do |title|
    puts "#{title[0]}    || media_id: #{title[1]}"
  end
end

def display_issues(args)
  # Must pass in media_id.
    media_id = args[1].to_s
    titles = SETTINGS[:db].execute('select issue_title, media_id, issue_id from Issues where media_id=?', [media_id])
    if titles.empty?
      puts "Looks like #{media_id} has no issues."
      return
    end
    puts "TITLES FOR: #{media_id}"
    puts "---------------------------"
    titles.each do |title|
      puts "#{title[0]}  || issue id: #{title[2]}"
    end
end

def download_images(image_count, title, issue)
  # TODO: This method needs a good bit of clean up.
  # test 1: 1k, 20 threads. 4ish min.
  # test 2: 1k images, 50 threads. 3 minutes.
  # test 3: 1k images, 20 threads, removed screen messages except start and stop. 2min 52 sec.
  # test 4: 1k images, 50 threads, removed screen messages except start and stop. 5min 20 sec.
  # conclusion: image sizes are all over the board so it's hard to determine timing cause but I suspect 20 threads is optimal.
  tnow = Time.now.strftime('%d/%m/%Y - %H:%M:%S')
  puts "STARTING: #{tnow}"



  if image_count.nil?
    # downloading specific issue
    all_images = SETTINGS[:db].execute("select image_id, issue_id, media_id, image_url, sequence from Images where media_id=? and issue_id=?",
      [title,issue])
  else
    # get em all
    all_images = SETTINGS[:db].execute("select image_id, issue_id, media_id, image_url, sequence from Images where downloaded=0 and issue_title not null LIMIT ?",
      [image_count])
  end


  hydra = Typhoeus::Hydra.new(max_concurrency: SETTINGS[:max_downloads])
  # load up images for hydra
  if !all_images
    # looks like there are no images.
    puts "No images."
    return
  end
  puts "Starting download ..."
  all_images.each do |data|
    puts "IMAGE: #{data}"
    image_id = data[0]
    puts "ii: #{image_id}"
    image = data[3]
        puts "img: #{image}"

    sequence = data[4]
        puts "seq: #{sequence}"

    if image.include?('.jpg')
      adjusted_url = image.match(/(http+)(.*jpg)/)
    elsif image.include?('.jpeg')
      adjusted_url = image.match(/(http+)(.*jpeg)/)
    elsif image.include?('.png')
      adjusted_url = image.match(/(http+)(.*png)/)
    elsif image.include?('.gif')
      adjusted_url = image.match(/(http+)(.*gif)/)
    else
      adjusted_url = image.match(/(http+)(.*\\?)/)
    end

    # alter image &&& and &&&&
    ext_data = image.sub('&&&', '^').sub('&&&&', '')
    name_data = ext_data.match(/(&&+)(.*\^)/) # returns info with title
    issue_data = ext_data.match(/(\^+)(.*)/) # returns issue number
    current_comic = SETTINGS[:db].execute("select media_id, name, media_type, folder_key from MediaTitles where media_id = ?", [data[2]])
    this_comic = current_comic[0][3]
    media_type = current_comic[0][2]
    if this_comic.empty?
      puts "No comic associated with the image. Make sure all Media Titles have a folder key too."
      return
    end

    # get issue title
    i_title = SETTINGS[:db].execute('select issue_title from Issues where issue_id=?', [data[1]])
    if i_title.empty?
      puts "Failed lookup of issue title"
      puts data[1]
      SETTINGS[:db].execute('delete from Images where issue_id = ?', [data[1]])
    else

        media_location = ''
        case media_type
        when 'comic'
        media_location = SETTINGS[:comicDirName]
        when 'manga'
        media_location = SETTINGS[:mangaDirName]
        end

        current_issue = i_title[0][0].to_s
        final_url = adjusted_url.to_s
          if !final_url.empty?
              # check to see if the directory and file for the image is there.
              folder_data = SETTINGS[:db].execute('select folder_key, pretty_name from FolderKeys where folder_key=?', [this_comic])
              title_directory = folder_data[0][1]
              fileLOC = "#{SETTINGS[:savedir]}#{media_location}/#{title_directory}/#{current_issue}"
              current_image = final_url.match(/[\w:]+\.(jpe?g|png|gif)/).to_s
              # sequence is order the page had images, so best indicator of true order
              image_number = sequence.to_s

              current_image = current_image.gsub('.jpg', image_number + '.jpg').gsub('.jpeg', image_number + '.jpeg').gsub('.png', image_number + '.png').gsub('.gif', image_number + '.gif')

              image_name = "#{this_comic}-#{current_issue}-#{current_image}"
              have_image = File.file?("#{fileLOC}/#{image_name}")

              if !have_image
                # The directory and file for the image isn't there, so add to request
                request = Typhoeus::Request.new final_url
                request.on_complete do |response|
                    puts "response received: #{final_url}."
                    current_image = "404"
                    # 2. check if comic + issue folder exists. If not, make it.
                    FileUtils::mkdir_p "#{SETTINGS[:savedir]}#{media_location}/#{title_directory}/#{current_issue}"
                    # 3. get the image and save into the directory.
                    File.write("#{SETTINGS[:savedir]}#{media_location}/#{title_directory}/#{current_issue}/#{image_name}", response.body)
                    # puts "Image: #{image_name} :::: Downloading: #{adjusted_url}"
                    SETTINGS[:db].execute("UPDATE Images set downloaded=1, issue_title=? where image_id = ?", [current_issue, image_id])
                end
                hydra.queue request
              else
                SETTINGS[:db].execute("UPDATE Images set downloaded=1, issue_title=? where image_id = ?", [current_issue, image_id])
              end
          else
              # corrupt or missing image url. For now, I'm just updating as done.
              SETTINGS[:db].execute("UPDATE Images set downloaded=1, issue_title=? where image_id = ?", [current_issue, image_id])
          end #request on complete
        end # has_comic_issue
    end
    hydra.run # fire it up!
   tlater = Time.now.strftime('%d/%m/%Y - %H:%M:%S')
  puts "ENDING: #{tlater}"
end

def create_title_page
  # this is pretty rough. Needs work.
  # this will create a TXT file in your save directory with all the titles and modules they use.
  # example:
  # Kings-Quest || ReadComicOnline
  # Kings-Quest is the title and it's using the ReadComicOnline module.
  titles = SETTINGS[:db].execute('select name, module, media_type, media_id from MediaTitles')
  t_array = []
  titles.each do |title|
    name = title[0]
    mod = title[1]
    media_type = title[2]
    media_id = title[3]
    body = "#{name} || Mod: #{mod} || Media ID: #{media_id}\n"
    if t_array.include?(media_type)
    File.write("#{SETTINGS[:savedir]}#{media_type}-titles.txt", body, mode: 'a')
    else
      old_file = File.exist?("#{SETTINGS[:savedir]}#{media_type}-titles.txt")
      if old_file
        File.delete("#{SETTINGS[:savedir]}#{media_type}-titles.txt")
      end
      t_array.push(media_type)
    end

  end
end

def add_media_title(title, source, title_url, module_name, media_type)
  folder_key = Core.createFolderKey(title)
  SETTINGS[:db].execute('INSERT INTO MediaTitles (name, source, title_url, module, media_type, folder_key, "update") values (?,?,?,?,?,?,?)',
  [title, source, title_url, module_name, media_type, folder_key, 0])
end

def createKeys
   titles = SETTINGS[:db].execute('select name, media_id, folder_key from MediaTitles')
   titles.each do |title|
    this_key = title[2]
    this_title = title[0]
    # does it exist?
    has_key = SETTINGS[:db].execute('select folder_key from FolderKeys where folder_key=?', [this_key])
    if has_key.empty?
      SETTINGS[:db].execute('INSERT INTO FolderKeys (folder_key, pretty_name) values (?,?)', [this_key,this_title])
    end
  end
end

# MAIN
args = ARGV # this gets args from command line in array

# SYSTEM

case args[0]
when 'updatetitles'
  get_title_data(args)
when 'updateissues'
  if args[1].nil?
    get_issue_data(10)
  else
    get_issue_data(args[1])
  end
when 'updateimages'
  if args[1].nil?
    get_image_data(100)
  else
    get_image_data(args[1])
  end
when 'downloadimages'
  #download_images(1, nil, nil)
  download_images(1 + rand(455), nil, nil) # TODO: put this back to 1000 or whatever
when 'downloadissue'
  if args[1].nil? || args[2].nil?
    puts "Need to specify comic title and issue number. Example Skeets.rb 31 3"
  else
    download_images(nil, args[1], args[2])
  end
when 'purge'
  purge_directories
when 'stats'
  Stats.display_stats
when 'displayissues'
  if args[1].nil?
    puts "You need to specify a title to search for."
  else
    display_issues(args)
  end
when 'lookupmediaid'
  lookup_media_id(args[1])
when 'createtitlepage'
  create_title_page
when 'createkeys'
  createKeys
when 'addmediatitle'
  # args[1] = name
  # args[2] = source domain
  # args[3] = url
  # args[4] = module
  # args[5] = type
  add_media_title(args[1], args[2], args[3], args[4], args[5])
when 'scrubfiles'
  Tools.scrub_file_extensions('/home/serabyte/temp/')
else
  puts 'Booster Gold loves you!'
  puts 'Try these commands: updatetitles updateissues updateimages downloadimages downloadissue displayissues lookupmediaid createtitlepage purge stats '
  puts 'Need to add a title manually? Try this:'
  puts 'ruby Skeets.rb addmediatitle The-Killing-Joke-2 http://no2.com http://no2.com/issue/ ComicPunchNet comic'
end
#sleep(875875638268546)
# SETTINGS[:db].close

# TODO
=begin

3. Look for ways to tighten up code with removal of repeated patterns and more methods for smaller code bites.
5. Look into using Typhoeus/Hydra for data building so each process can be threaded for quicker results.
8. PURGE needs to be fixed!
9. found site: http://view-comic.com/, viewcomic.com ?
10. add http://www.comicastle.org/manga-list.html?listType=allABC
=end
