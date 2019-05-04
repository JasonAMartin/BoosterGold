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
    new_folder_key = createFolderKey(folder_key)
    if (new_folder_key != folder_key)
      key_check = SETTINGS[:db].execute('select folder_key from MediaTitles where folder_key=?', [new_folder_key])
      if not key_check
        puts "Updating: #{folder_key} to #{new_folder_key}"
        SETTINGS[:db].execute('UPDATE MediaTitles set folder_key=? where name=?', [new_folder_key, pretty_name])
      else
        new_folder_key2 = new_folder_key + rand(9999).to_s
        puts "Updating: #{folder_key} to #{new_folder_key2}"
        SETTINGS[:db].execute('UPDATE MediaTitles set folder_key=? where name=?', [new_folder_key2, pretty_name])
      end
    end
  end
end

clean_folder_keys