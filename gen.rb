require 'open3'
require 'oga'
require 'base64'

def system_quietly(*cmd)
    # --> require 'open3'
    exit_status = nil  
    err = nil
    out = nil
    Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thread|
        err = stderr.gets(nil)
        out = stdout.gets(nil)
        [stdin, stdout, stderr].each{|stream| stream.send('close')}
        exit_status = wait_thread.value
    end
    exit_status == 0 ? exit_status = true : exit_status = false
    out ? out.chomp! : out = nil
    return exit_status, out
end  

if ARGV[0].nil?
    p "Need Filename"
    exit
end
chuong = ARGV[0]

japanese = File.read "japanese/#{chuong}.txt"
japanese.gsub! "<", "&lt;"
japanese.gsub! ">", "&gt;"

japanese.gsub! "&lt;parallel&gt;", "<parallel>"
japanese.gsub! "&lt;/parallel&gt;", "</parallel>"

japanese_doc = Oga.parse_xml(japanese)
english_doc = Oga.parse_xml(File.read("english/#{chuong}.txt"))

if japanese_doc.css('parallel').size != english_doc.css('parallel').size
    puts "Parallel texts mismatch. Please check Japanese and English files"
    puts "Japanese #{japanese_doc.css('parallel').size}"
    puts "English #{english_doc.css('parallel').size}"
    exit
end

result = ""
japanese_doc.css('parallel').each_with_index do |paragraph, index|
    text = paragraph.text
    text.gsub! "&lt;", "<"
    text.gsub! "&gt;", ">"
    text.downcase!
    text.gsub! "<br>", "\n"
    text.strip!
    text.gsub! /\n\s*\n/, "\n"
    text.gsub! "\n", "<br>　　"
    trans = english_doc.css('parallel')[index].text.strip.gsub("\n", "<br>")
    trans = Base64.strict_encode64 trans
    text  = "<br>　　#{text}<span class='english' data-english='#{trans}'>&#x02729;</span><br>"    
    result += text
end

result += "<div id='chapter-number' style='display: none;' data-chapter='#{chuong}'></div>"

output = File.read "template.html"
output.gsub! "TITLEWILLBEHERE", "Harry Potter #{chuong[2..-1]}"
output.gsub! "CONTENTWILLBEHERE", result

File.open("/home/BitTorrent Sync/time4vps.html/#{chuong}.html", "w") {|f| f.write output}