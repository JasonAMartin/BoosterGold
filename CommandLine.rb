require 'optparse'

class CommandLine
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    # options = OpenStruct.new
    # options.library = []
    # options.inplace = false
    # options.encoding = "utf8"
    # options.transfer_type = :auto
    # options.verbose = false
    options = {}
    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: Data.rb [options], like -task somethin"

        # args[1] = name
      # args[2] = source domain
      # args[3] = url
      # args[4] = module
      # args[5] = type
      # args[6] = disabled

      opts.on("-command=s", "--command", "updatetitles updateimages updateissues downloadimages addmediatitle addmediaissue lookupmediaid") do |v|
        options[:command] = v
      end

      opts.on("-quantity=s", "--quantity", "quantity") do |v|
        options[:command] = v
      end

      opts.on("-name=s", "--name", "The-Killing-Joke") do |v|
        options[:name] = v
      end

      opts.on("-source=s", "--source", "http://comicsite.com") do |v|
        options[:source] = v
      end

      opts.on("-url=s", "--url", "http://comicsite.com/issue/some-title") do |v|
        options[:url] = v
      end

      opts.on("-module=s", "--module", "ComicPunchNet") do |v|
        options[:module] = v
      end

      options[:type] = 'comic'
      opts.on("-type=s", "--type", "comic") do |v|
        options[:type] = v
      end

      options[:disabled] = 0
      opts.on( '-disabled', '--disabled', 'disabled' ) do
        options[:quick] = 1
      end

      # This displays the help screen, all programs are
      # assumed to have this option.
      opts.on( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit
      end
    end
    opt_parser.parse!(args)
    options
  end  # parse()
end  # class CommandLine
