require 'nokogiri'

file = File.open ARGV[0]
doc = Nokogiri::XML file; nil
doc.remove_namespaces!; nil
doc.xpath("//bookmarkStart").remove; nil
doc.xpath("//bookmarkEnd").remove; nil

output = ""
doc.xpath("/package/part/xmlData/document/body/p").each do |b|
    output += "<div class=mt>"

    if b.content != ""
        b.xpath("./r").each do |i|
            unless i.xpath("./ruby").empty?
                begin
                    ruby = i.at_xpath("./ruby/rubyBase").text
                    furi = i.at_xpath("./ruby/rt").text
                    output += "<ruby><span class=rb>#{ruby}</span><span class=rt>#{furi}</span></ruby>"
                rescue
                    puts i
                end
            else
                # output += i.content.gsub(/\s+/, "")
                # output += i.content
                output += "<ruby><span class=rb>#{i.content}</span><span class=rt>&nbsp;</span></ruby>"
            end
        end
    else
        output += "<br>"
    end

    output += "</div>"
end

episode = ARGV[0][2]
chapter = ARGV[0][3..4]
title = "Harry Potter #{episode} Chapter #{chapter}"

o = File.read "test.template.html"
o.gsub! "CONTENTWILLBEHERE", output
o.gsub! "TITLEWILLBEHERE", title
o.gsub! "SCROLLPOSWILLBEHERE", ARGV[0]

File.open("../../time4vps.html/#{ARGV[0].split('.')[0]}.html", "w") {|f| f.write o}