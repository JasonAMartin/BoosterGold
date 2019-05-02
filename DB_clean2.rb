####################
# Used as a base for cleaning up DB.
####################

require 'sqlite3' #

# SETTINGS

SETTINGS = {
  savedirno: '/home/serabyte/Minerva/',
  savedir: '/home/serabyte/Minerva/',
  comicDirName: 'Comics2',
  mangaDirName: 'Manga',
  scrape_pages: 50,
  max_downloads: 10,
  minimum_image_threshold: 6,
  db: SQLite3::Database.new('../BoosterGoldDatabase/BoosterGold.db')
}.freeze

def createFolderKey(title)
  new_title = title.gsub(' ','').gsub('-','').gsub('(', '').gsub(')','').gsub(':','').gsub(';','').gsub('@','').gsub('"','').gsub('https://comiconlinefree.com','').gsub('comiconlinefree.com','').gsub('/','-').gsub('https','').gsub('http','').downcase
  return new_title
end

def clean_folder_keys
   keys = SETTINGS[:db].execute('select folder_key, name from MediaTitles')
   keys.each do |key|
    folder_key = key[0]
    pretty_name = key[1]
    name_check = SETTINGS[:db].execute('select folder_key, pretty_name from FolderKeys where pretty_name=?', [pretty_name])
    if name_check[0] and (name_check[0][0] != folder_key)
      # mismatch so update
      puts "changed key for: #{pretty_name}. #{name_check[0][0]} :: #{folder_key}"
      SETTINGS[:db].execute('UPDATE FolderKeys set folder_key=? where pretty_name=?', [folder_key, pretty_name])
    end
  end
end

clean_folder_keys