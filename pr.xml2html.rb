require 'nokogiri'

if ARGV[0].nil?
    puts "Usage: command Filename.xml"
    exit
end

file = File.open ARGV[0]
doc = Nokogiri::XML file; nil
doc.remove_namespaces!; nil
doc.xpath("//bookmarkStart").remove; nil
doc.xpath("//bookmarkEnd").remove; nil

# We only care about 'commentRangeStart' element.
# But sometime this element is direct child of body.
# Make this element direct child of 'p'
doc.xpath("/package/part[@name='/word/document.xml']/xmlData/document/body/commentRangeStart").each do |c|
    c.next.add_child c.dup
    c.remove
end

output = ""
doc.xpath("/package/part[@name='/word/document.xml']/xmlData/document/body/p").each do |paragraph|
    comment = paragraph.at_xpath("./commentRangeStart")
    if comment
        commentID = comment['id']
        enText = ""
        doc.xpath("/package/part[@name='/word/comments.xml']/xmlData/comments/comment[@id='#{commentID}']/p").each do |commentParagraph|
            enText += "<p>#{commentParagraph.content.gsub("'", "&#39;").gsub('"', "&#34;")}</p>"
        end
        output += "<div class=jp data-en='#{enText}'>"
    else
        output += "<div class=jp>"
    end

    if paragraph.content != ""
        paragraph.xpath("./r").each do |i|
            unless i.xpath("./ruby").empty?
                begin
                    ruby = i.at_xpath("./ruby/rubyBase").text
                    furi = i.at_xpath("./ruby/rt").text
                    output += "<ruby>#{ruby}<rt>#{furi}</rt></ruby>"
                rescue
                    puts i
                end
            else
                output += i.content
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

o = File.read "pr.template.html"
o.gsub! "CONTENTWILLBEHERE", output
o.gsub! "TITLEWILLBEHERE", title
o.gsub! "SCROLLPOSWILLBEHERE", ARGV[0]

File.open("/Data/time4vps.html/hp/#{ARGV[0].split('.')[0]}.pr.html", "w") {|f| f.write o}