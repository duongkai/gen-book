# Reference: http://cottagedata.com/t_ebooks/part3.php
# TOC Making

require "nokogiri"
require "fileutils"
require "eeepub"

KINDLEGEN_CMD="/usr/local/src/kindlegen/kindlegen"
BOOK_NAME = "Thuong_Tien"

def getChapterContent(chapter_file)
    #doc = open(chapter_file) { |f| Hpricot(f) }
    fhandle = File.open chapter_file
    doc = Nokogiri::HTML fhandle
    doc.xpath("//body").remove
end

#puts getChapterContent "tmp/quyen-14-chuong-34.html"

def regenChapterWithIDTag(chapter_file)
    content = getChapterContent chapter_file
    chapterID = File.basename(chapter_file)[0..-6]
    heading = "<h3 id=\"chapter\">#{chapterID}</h3><br/>"
    fhandle = File.open "tmp/" + chapterID + ".html", 'w'
    fhandle.write "<html><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />"
    fhandle.write "<body>#{heading}#{content}</body></html>"
    fhandle.close
end

def genInlineTOC(listOfFile)
    fhandle = File.open "tmp/toc.html", "w"
    fhandle.write "<html><head>Table of Contents</head><body><h1 id=\"chap_toc\">TOC</h1>"
    listOfFile.each do |file|
        f = File.basename(file)
        file_id = f[0..-6]
        fhandle.write "<a href=\"#{f}\#chapter\">#{file_id}</a><br/>"
    end
    fhandle.write "</body></html>"
    fhandle.close
end

def driver
    file_list = Array.new
    book_toc = Array.new
    Dir.foreach "tmp" do |file|
        puts file
        if file != '.' and file != '..'
            regenChapterWithIDTag File.join("tmp", file)
            file_list << "tmp/" + file
            book_toc << {:label => 'Chuong_' + file[0..-6], :content => file}
        end
    end
    genInlineTOC file_list
    file_list = ["tmp/toc.html"] + file_list
    book_toc << {:label => "TOC", :content => "toc.html"}

    myPubBook = EeePub.make do 
        title BOOK_NAME
        creator 'kai'
        publisher 'kai@publisher'
        date Time.now()
        uid '0001'
        identifier 'http://kai.me/book/foo', :scheme => 'URL', :id => '0001'
        files file_list
        nav book_toc 
    end

    if myPubBook.nil?
        puts "Nil class"
    else
    puts "Creating book"
    myPubBook.save (BOOK_NAME + '.epub')
    # it generates mobi book within same dir with epub file by using kindlegen
    #exec KINDLEGEN_CMD << "-c1 #{BOOK_NAME}.epub -o #{BOOK_NAME}.mobi 2> /dev/null"
    exec KINDLEGEN_CMD + " -c1 #{BOOK_NAME}.epub -o #{BOOK_NAME}.mobi"
end

end

def gen_book
    exec KINDLEGEN_CMD + " -c1 #{BOOK_NAME}.epub -o #{BOOK_NAME}.mobi"
end
#driver
#gen_book
