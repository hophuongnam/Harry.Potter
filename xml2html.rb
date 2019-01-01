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

commentSVG = 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjwhRE9DVFlQRSBzdmcgUFVCTElDICItLy9XM0MvL0RURCBTVkcgMS4xLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL0dyYXBoaWNzL1NWRy8xLjEvRFREL3N2ZzExLmR0ZCI+CjxzdmcgdmVyc2lvbj0iMS4xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiBwcmVzZXJ2ZUFzcGVjdFJhdGlvPSJ4TWlkWU1pZCBtZWV0IiB2aWV3Qm94PSIwIDAgMzAwIDI0OSIgd2lkdGg9IjMwMCIgaGVpZ2h0PSIyNDkiPjxkZWZzPjxwYXRoIGQ9Ik04NS4wMiAzNS44NkM4NS4wMiAzNS44NiA4NS4wMiAzNS44NiA4NS4wMiAzNS44NkMxMTEuNTUgMzUuODYgMTI2LjI4IDM1Ljg2IDEyOS4yMyAzNS44NkMxNzguOTcgMzUuODYgMjA2LjYgMzUuODYgMjEyLjEzIDM1Ljg2QzIxNy41MSAzNS44NiAyMjIuNjYgMzguMDUgMjI2LjQ2IDQxLjk0QzIzMC4yNiA0NS44MyAyMzIuNCA1MS4xMSAyMzIuNCA1Ni42MUMyMzIuNCA2MC4wNyAyMzIuNCA3Ny4zNyAyMzIuNCAxMDguNDlDMjMyLjQgMTA4LjQ5IDIzMi40IDEwOC40OSAyMzIuNCAxMDguNDlDMjMyLjQgMTI3LjE3IDIzMi40IDEzNy41NCAyMzIuNCAxMzkuNjJDMjMyLjQgMTM5LjYyIDIzMi40IDEzOS42MiAyMzIuNCAxMzkuNjJDMjMyLjQgMTUxLjA4IDIyMy4zMiAxNjAuMzcgMjEyLjEzIDE2MC4zN0MyMDYuNiAxNjAuMzcgMTc4Ljk3IDE2MC4zNyAxMjkuMjMgMTYwLjM3QzEyNS4zOCAxNjMuODkgMTA2LjEzIDE4MS40OCA3MS40NyAyMTMuMTRDNzkuNiAxODEuNDggODQuMTIgMTYzLjg5IDg1LjAyIDE2MC4zN0M3OS40OSAxNjAuMzcgNzYuNDIgMTYwLjM3IDc1LjggMTYwLjM3QzY0LjYxIDE2MC4zNyA1NS41NCAxNTEuMDggNTUuNTQgMTM5LjYyQzU1LjU0IDEzOS42MiA1NS41NCAxMzkuNjIgNTUuNTQgMTM5LjYyQzU1LjU0IDEzNy41NCA1NS41NCAxMjcuMTcgNTUuNTQgMTA4LjQ5QzU1LjU0IDEwOC40OSA1NS41NCAxMDguNDkgNTUuNTQgMTA4LjQ5QzU1LjU0IDc3LjM2IDU1LjU0IDYwLjA3IDU1LjU0IDU2LjYxQzU1LjU0IDU2LjYxIDU1LjU0IDU2LjYxIDU1LjU0IDU2LjYxQzU1LjU0IDQ1LjE1IDY0LjYxIDM1Ljg2IDc1LjggMzUuODZDNzYuNDIgMzUuODYgNzkuNDkgMzUuODYgODUuMDIgMzUuODZaIiBpZD0iZXo0SzJVSWxVIj48L3BhdGg+PC9kZWZzPjxnPjxnPjxnPjx1c2UgeGxpbms6aHJlZj0iI2V6NEsyVUlsVSIgb3BhY2l0eT0iMSIgZmlsbD0iIzAwMDAwMCIgZmlsbC1vcGFjaXR5PSIwIj48L3VzZT48Zz48dXNlIHhsaW5rOmhyZWY9IiNlejRLMlVJbFUiIG9wYWNpdHk9IjEiIGZpbGwtb3BhY2l0eT0iMCIgc3Ryb2tlPSIjMjIyMjIyIiBzdHJva2Utd2lkdGg9IjEwIiBzdHJva2Utb3BhY2l0eT0iMSI+PC91c2U+PC9nPjwvZz48L2c+PC9nPjwvc3ZnPg=='

comment = nil
output = ""
doc.xpath("/package/part[@name='/word/document.xml']/xmlData/document/body/p").each do |paragraph|
    # comment = paragraph.at_xpath("./commentRangeEnd")
    enText = ""
    if comment
        commentID = comment['id']
        doc.xpath("/package/part[@name='/word/comments.xml']/xmlData/comments/comment[@id='#{commentID}']/p").each do |commentParagraph|
            enText += "<div>#{commentParagraph.content.gsub("'", "&#39;").gsub('"', "&#34;")}</div>"
        end
    end

    output += "<div class=jp>"

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

    if comment
        output += "<img class=en src=#{commentSVG} data-en='#{enText}'></div>"
    else
        output += "</div>"
    end
end

episode = ARGV[0][2]
chapter = ARGV[0][3..4]
title = "Harry Potter #{episode} Chapter #{chapter}"

o = File.read "template.html"
o.gsub! "CONTENTWILLBEHERE", output
o.gsub! "TITLEWILLBEHERE", title
o.gsub! "SCROLLPOSWILLBEHERE", ARGV[0]

File.open("/Data/hophuongnam.github.io/hp/#{ARGV[0].split('.')[0]}.html", "w") {|f| f.write o}
puts "Done for #{ARGV[0]}."
