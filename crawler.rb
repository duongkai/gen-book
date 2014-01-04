require 'httpclient'
require 'nokogiri'
require 'gmail'

KINDLEGEN_CMD = "/usr/local/src/kindlegen/kindlegen"

PREFIX = "http://tunghoanh.com/chapter"
URL = "http://tunghoanh.com/hong-sac-si-do-Iiaaaab.html"
BOOK_NAME = "Hong Sac Si Do"
AUTHOR = "Hong Mong Thu"
PUBLISHER = "Tung hoanh"
FILE_NAME = "Hong Sac Si Do"

def extract_chapters
    client = HTTPClient.new
    resp = client.get(URL, :follow_redirect => true)
    content = resp.http_body.content
    doc = Nokogiri::HTML(content)
    res = Array.new
    srch = doc.css('a[rel="nofollow"]')
    srch.each do |el|
        res << _extract(el["href"]) unless el["href"].nil?
        puts res[-1]
    end
    return res
end

def _extract(chapter_link)
    name = chapter_link.split("/")[-1]
    link = PREFIX + "/#{chapter_link.split("/")[-2]}" + "/#{name}"
    {:name => name, :link => link}
end

def get_and_get(chapters)
    begin 
        Dir.mkdir "tmp"
    rescue
        puts "Re-creating the new TEMP directory"
        FileUtils.rm_rf "tmp"
        Dir.mkdir "tmp"
    end

    client = HTTPClient.new
    chapters.each do |chapter|
        puts "Getting #{chapter[:name]} - #{chapter[:link]}"
        content = client.get(chapter[:link], :follow_redirect => true).http_body.content
        fhandler = File.open("tmp/#{chapter[:name]}", "w")
        fhandler.write "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" /></head>#{content}</body></html>"
        fhandler.close
    end
end

get_and_get (extract_chapters)

