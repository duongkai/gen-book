#!/usr/bin/env ruby
# support WebTruyen. It will create a big HTML file with TOC. 
# Using kindlegen to convert to mobi
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'cgi'

PAGING="http://webtruyen.com/story/Paging_listbook"

abort("Not enough argument") unless ARGV.length == 1

url = ARGV[0]

def extract_metadata(url)
    page = Nokogiri::HTML(open url)
    content_detail = page.css 'div.contdetail'
    title = content_detail.css('h1.title a.description').text
    author = content_detail.css('span.author').text
    book_type = content_detail.css('span.type').at('a')['title']
    book_id = content_detail.at('input')['value'].to_i
    chapter_pages = page.css('div.input_page span.numbpage').text.split("/")[1].to_i
    return {:book_name => title, :book_author => author, :book_type => book_type, :book_id => book_id, :pages => chapter_pages }
end

def extract_chapter_list(url)
    page = Nokogiri::HTML(open url)
    chapters = Array.new
    page.css('tr td.tdchapter1').each_with_index do |chapter_id, ri| 
        chapters[ri] = {}
        chapters[ri][:name] = chapter_id.text.encode("iso-8859-1").force_encoding("utf-8")
        chapters[ri][:name] << ": "
    end
    # add chapter_name and chapter link
    page.css('tr td a').each_with_index do |chapter, ri|
        chapters[ri][:name] << chapter.text.encode("iso-8859-1").force_encoding("utf-8") 
        chapters[ri][:link] = chapter["href"]
    end
    return chapters
end

def extract_content(url)
    puts "Extracting: #{url}"
    page = Nokogiri::HTML (open url)
    # extract the content
    content = page.at_css('div#detailcontent') 
    # clean up
    content.search('//div').each do |node|
        node.remove
    end
    # return only div block
    return content.to_html.tr("\n", " ")
end

#extract_content (url)
metadata = extract_metadata(url)
puts "Book #{metadata[:book_name]}: #{metadata[:pages]}"
book_chapters = Array.new
(1..metadata[:pages]).each do |page|
    scanning_url = "#{PAGING}/#{metadata[:book_id]}/#{page}"
    puts "Scanning #{scanning_url}"
    book_chapters += extract_chapter_list scanning_url
end
#p book_chapters.length

# create file html
filename = File.basename url
File.open("#{filename}.html", "w") do |fout|
    fout.puts "<html><head><meta http-equiv=\"Content-Type\" content=\"application/xhtml+xml; charset=utf-8\" /></head>"
    fout.puts "<body>"
    fout.puts "<h1>#{metadata[:book_name]}</h1>"
    fout.puts "<h3>Update: #{book_chapters.length}</h3>"
    fout.puts "<h3>#{metadata[:book_author]}</h3>"
    fout.puts "<h3>#{metadata[:book_type]}</h3>"
    # fill out the TOC
    book_chapters.each_with_index do |chapter, ri|
        fout.puts "<a name='toc_#{ri}' href='\##{ri}'>#{chapter[:name]}</a><br>"
    end
    # fill out the content
    book_chapters.each_with_index do |chapter, ri|
        content = extract_content chapter[:link]
        fout.puts "<h2><a name='#{ri}'>#{chapter[:name]}</a></h2>"
        fout.puts "<p>#{content}</p>"
        fout.puts "<a href='\#toc_#{ri}'>Back</a><br>"
    end
end

File.open("#{filename}.html", "a") {|fout| fout.puts "</body>"}
# end
