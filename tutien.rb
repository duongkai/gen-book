require "httpclient"
require "hpricot"
require "fileutils"
require "eeepub"

URL="http://tunghoanh.com/thuong-thien-neaaaab.html"
CHAPTER_URL="http://tunghoanh.com/chapter/"
KINDLEGEN_CMD="/usr/local/src/kindlegen/kindlegen"

def get_toc()
    # Get the content
    hclient = HTTPClient.new
    page_content = hclient.get_content(URL, :follow_redirect => true).force_encoding("UTF-8")
    
    # Get the chapters and its link
    doc = Hpricot(page_content)
    chapter_list = (doc/"div.chapter")
    toc = Array.new
    chapter_list.each do |chapter|
        chapter_name = chapter.at("a").inner_html
        chapter_link = chapter.at("a")["href"]
        toc << {:name => chapter_name, :link => chapter_link}
    end
    return toc
end

begin
    Dir.mkdir("tmp")
rescue
    puts "Re-creating the new directory"
    FileUtils.rm_rf "tmp"
    Dir.mkdir "tmp"
end

def wgetChapterContent()  
    toc = get_toc()
    http_client = HTTPClient.new
    toc.each do |chapter|
        puts "wget #{chapter[:link]}"
        # get the content
        chapter_id = getChapterID chapter[:link]
        real_link = CHAPTER_URL + chapter_id
        puts "Get the real link: #{real_link}"
        #puts real_link
        site_content = http_client.get_content(real_link, :follow_redirect => true).force_encoding("UTF-8")
        # save it to file
        fhandle = File.open "tmp/" + chapter_id[0..-14] + '.html', 'w'
        fhandle.write "<html><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />#{site_content}</body></html>"
        fhandle.close()
    end
end

def getChapterID(url)
    return url[34..-1]
end

wgetChapterContent
