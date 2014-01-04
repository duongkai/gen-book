require 'httpclient'
require 'nokogiri'
#require 'eeepub'
#require 'gmail'

#KINDLEGEN_CMD = "/usr/local/src/kindlegen/kindlegen"

PREFIX = 'http://vnthuquan.net/truyen/'
URL = 'http://vnthuquan.net/truyen/truyen.aspx?tid=2qtqv3m3237n1nmn2nnn31n343tq83a3q3m3237nvn&AspxAutoDetectCookieSupport=1'
BOOK_NAME = '1984'
AUTHOR = 'Geogre Orwell'
PUBLISHER = 'vnthuquan.net'
FILE_NAME = 'Geogre Orwell'

DELIMITER = '--!!tach_noi_dung!!--'

client = HTTPClient.new
resp = client.get(URL, :follow_redirect => true)
content = resp.http_body.content

def clean_space(content)
    %{
    <html>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <body>#{content.split.join(" ")}</body>
    </html>
    }
end

# extract chapter_links
doc = Nokogiri::HTML(content)
res = Array.new
a = doc.css('div')
a.each do |d|
     unless d["onclick"].nil? then
        res << {:chap_name => d.text, :chap_link => d["onclick"].split("'")[1]}
     end
end

# create temp dir
begin
    Dir.mkdir "tmp"
rescue SystemCallError
    system ("rm -rf tmp")
    Dir.mkdir "tmp"
end

# get and get
chap_files = Array.new
res.each do |link|
    puts "Getting: #{link[:chap_name]} - #{PREFIX + link[:chap_link]}"
    chap_content = client.get(PREFIX + link[:chap_link], :following_redirect => true).http_body.content
    #puts chap_content.split(DELIMITER)[1]
    chap_files << "tmp/#{link[:chap_name]}.html"
    File.open "tmp/#{link[:chap_name]}.html", 'w' do |f|
        f.puts clean_space(chap_content.split(DELIMITER)[1..2].join)
    end
end

=begin
#puts chap_files
book = EeePub.make do
    title BOOK_NAME
    creator AUTHOR
    publisher PUBLISHER
    date Time.now()
    uid '0001'
    identifier 'http://kai.me/book/foo', :scheme => 'URL', :id => '0001'
    files chap_files
end

if book.nil? then
    puts "Wat the fuck"
else
    puts "Creating book"
    book.save FILE_NAME + ".epub"
    system KINDLEGEN_CMD + " -c1 #{FILE_NAME}.epub -o #{FILE_NAME}.mobi"
end

# Sending email
EMAIL = 'chimbaobao@gmail.com'
PWD = 'Echo87123'
KINDLE_EMAIL = 'chimbaobao_53@kindle.com' # The kindle email associcates with my Nexus 7 kindle
Gmail.new(EMAIL, PWD) do |gmail|
    gmail.deliver do
        to KINDLE_EMAIL
        subject "#{BOOK_NAME} - #{AUTHOR}"
        add_file "#{FILE_NAME}.mobi"
    end
end
=end
