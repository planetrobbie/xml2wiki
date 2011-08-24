#!/usr/bin/ruby -w

# Convert XML file to Wikipedia Cheatsheet easily from XML source file
# using nokogiri SAX parser ;)
#
# Usage : xml2wiki.rb -f <file>
#
# output 3 columns cheatsheet, see source file example below
#  
#<root>
#    <header>Git Cheatsheet</header>
#    <section>Branching and Merging</section>
#    <cmd>
#      <description>list your available branches</description>
#      <details>$ git branch</details>
#    </cmd>
#    <cmd>
#      <description>create a new branch</description>
#      <details>$ git branch (branchname)</details>
#      <comments>you can think of it like a bookmark</comments>
#    </cmd>
#    <footer>[http://gitref.org/ Git Reference]</footer>
#</root>
#
# Full Git cheatsheet available at http://wiki.yet.org/w/Git

require 'rubygems'
require 'getoptlong'
require 'nokogiri'

class MyCheatsheet < Nokogiri::XML::SAX::Document
  def initialize
    @tags = []
    @cheatsheet = ""

    # Wikipedia inspired template, not human readable but who cares ;)
    @@template = Hash.new
    @@template = {
	    "root" => "<!--Heavily inspired from Wikipedia Cheatsheet-->\n<div align=\"center\">\n{|align=\"center\" style=\"width:100%; border:2px #a3b1bf solid; background:#f5faff; text-align:left;\"\n|colspan=\"3\" align=\"center\" style=\"background:#cee0f2; text-align:center;\" |\n",
            "header" => "<h2 style=\"margin:.5em; margin-top:.1em; margin-bottom:.1em; border-bottom:0; font-weight:bold;\">%%</h2>\n|-\n| width=\"30%\" style=\"background:#E6F2FF; padding:0.3em; font-size: 0.9em; text-align:center;\"|Descriptions\n| style=\"background:#E6F2FF; padding:0.3em; font-size: 0.9em; text-align:center;\"|Commands\n| width=\"30%\" style=\"background:#E6F2FF; padding:0.3em; font-size: 0.9em; text-align:center;\"|Comments\n",
	    "section" => "|-\n| colspan=\"3\" style=\"background:#E6F2FF; padding: 0.2em; font-size: 0.9em; text-align:center;\" | '''%%'''",
	    "cmd" => "|-\n|colspan=\"3\" style=\"border-top:1px solid #cee0f2;\"|\n|-",
	    "description" => "\n|%%",
	    "details" => "|<tt>%%</tt>",
	    "comments" => "|''%%''",
	    "footer" => "|-\n| colspan=\"3\" style=\"text-align:center;\"|\n%%\n|}</div>",
	    }
  end
  
  # this event offers an opportunity to store current tag name for later processing
  def start_element(name, attrs = [])
    # keep track of the nesting
    @tags.push(name)

    if @@template[name]
      # add template content depending on tag name
      @cheatsheet << @@template[name]
    else
      # keep as is original HTML tags if tag not defined in our template
      @cheatsheet.sub!(/%%/,"<#{name}>%%") unless name.nil?
    end
  end
 
  # this is where we apply the template, within tag content 
  def characters(text)    
    # apply tag content to template and move pointer at the end
    @cheatsheet.sub!(/%%/,text << "%%")
  end
  
  def end_element(name) 
    if @@template[@tags.last] 
      # pointer no more needed at tag end within a template
      @cheatsheet.sub!(/%%/,"")
      @cheatsheet << "\n"
    else
      #close HTML entity
      @cheatsheet.sub!(/%%/,"</#{@tags.last}>%%")
    end
    @tags.pop
  end 
  
  def end_document
    # convert line breaks to HTML entities
    @cheatsheet.gsub!(/\\n/,"<br />")
      
    puts @cheatsheet
  end
end

def process_file(file)
  if File.exist?(file)
    # Create our Parser
    parser = Nokogiri::XML::SAX::Parser.new(MyCheatsheet.new)

    # provide XML file to Parse
    parser.parse(File.read(file))
  else
    puts "File does not exist"
  end
end

opts = GetoptLong.new(
      [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
      [ '--file', '-f', GetoptLong::REQUIRED_ARGUMENT ]
)

if ARGV.size == 0
	puts "Usage: #{$0} [OPTIONS]"
end

begin
	opts.each do |opt, arg|
		case opt
			when '--help'
				puts "-f [FILE]\t- Read from file\n-h\t\t- Print this help message"
			when '--file'
				process_file(arg)
		end
	end

rescue GetoptLong::InvalidOption => e
	puts e
end
