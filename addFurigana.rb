require 'nkf'
require "furigana"
require 'nokogiri'

# Input "程度が激しかったり、秩序がない様子を表す。「やたらと」も使う。「むやみやたらに」「めったやたらに」という言い方もある。"
# Output: ["程度", "が", "激", "しかったり、", "秩序", "がない", "様子", "を", "表", "す。「やたらと」も", "使", "う。 「むやみやたらに」「めったやたらに」という", "言", "い", "方", "もある。"]
def divideKanjiPhrase(str)
    ctype = "nothing"
    output = ""
    group = []
    str.each_char do |c|
        if /\p{Han}/.match(c)
            case ctype
            when "nothing"
                output = c
            when "kanji"
                output += c
            else
                group << output
                output = c
            end

            ctype = "kanji"
        else
            case ctype
            when "nothing"
                output = c
            when "kana"
                output += c
            else
                group << output
                output = c
            end

            ctype = "kana"
        end
    end

    group << output
    group
end

# Input "言い方", "いいかた"
# Output [["言", "い"], ["方", "かた"]]
def kanjiFuri(kanji, furi)
    o = []
    h = furi
    k = divideKanjiPhrase(kanji)
    k.each_index { |x|
        if /\p{Han}/.match k[x]
            o[x] = h[0 .. k[x].length - 1]
            h = h[k[x].length .. -1]
        else
            head, sep, tail = h.partition k[x]
            if head != ""
                o[x - 1] += head
            end
            o[x] = sep
            h = tail
        end
    }
    o[o.length - 1] += h

    output = []
    memo = []
    k.each_index { |x|
        if /\p{Han}/.match k[x]
            memo << k[x]
            memo << o[x]
            output << memo
            memo = []
        end
    }
    output
end

def furigantz(s)
    memo = []
    output = []
    Furigana::Mecab.tokenize(s).each do |n|
        if /\p{Han}/.match n[:surface_form]
            yomi = n[:reading]
            if /\p{Hiragana}/.match n[:surface_form]
                kanjiFuri(n[:surface_form], NKF.nkf('-h1 -w', yomi)).each { |x|
                    output << x
                }
            else
                memo << n[:surface_form]
                memo << NKF.nkf('-h1 -w', yomi)
                output << memo
                memo = []
            end
        end
    end
    output
end

def readFuri (str)
    # Return empty hash if no kanji
    # Return hash of markup string
    strToMatch = str    
    token = furigantz(strToMatch)
    newStrA = []

    return token if token.empty?

    token.each do |t|
        oldPart = t[0]
        newPart = %Q{
            <w:r w:rsidRPr="000A5638">
              <w:ruby>
                <w:rubyPr>
                  <w:rubyAlign w:val="distributeSpace"/>
                  <w:hps w:val="10"/>
                  <w:hpsRaise w:val="22"/>
                  <w:hpsBaseText w:val="18"/>
                  <w:lid w:val="ja-JP"/>
                </w:rubyPr>
                <w:rt>
                  <w:r w:rsidR="00E24EC8" w:rsidRPr="000A5638">
                    <w:rPr>
                      <w:rFonts w:ascii="Yu Mincho" w:hAnsi="Yu Mincho" w:hint="eastAsia"/>
                      <w:sz w:val="10"/>
                    </w:rPr>
                    <w:t>#{t[1]}</w:t>
                  </w:r>
                </w:rt>
                <w:rubyBase>
                  <w:r w:rsidR="00E24EC8" w:rsidRPr="000A5638">
                    <w:rPr>
                      <w:rFonts w:hint="eastAsia"/>
                    </w:rPr>
                    <w:t>#{t[0]}</w:t>
                  </w:r>
                </w:rubyBase>
              </w:ruby>
            </w:r>
        }

        head, m, tail =  strToMatch.partition oldPart
        unless head.empty?
            head = %Q{
                <w:r w:rsidRPr="000A5638">
                  <w:rPr>
                    <w:rFonts w:hint="eastAsia"/>
                  </w:rPr>
                  <w:t>#{head}</w:t>
                </w:r>
            }
            newStrA.push head
        end
        newStrA.push newPart
        strToMatch = tail
    end

    unless strToMatch.empty?
        strToMatch = %Q{
            <w:r w:rsidRPr="000A5638">
                <w:rPr>
                    <w:rFonts w:hint="eastAsia"/>
                </w:rPr>
                <w:t>#{strToMatch}</w:t>
            </w:r>
        }
        newStrA.push strToMatch
    end
    return newStrA
end

namespace = {'w' => "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
file = File.open ARGV[0]
doc = Nokogiri::XML file; nil

doc.xpath("//w:bookmarkStart", namespace).remove; nil
doc.xpath("//w:bookmarkEnd", namespace).remove; nil

xmlData = doc.xpath("/pkg:package[1]/pkg:part[3]/pkg:xmlData[1]"); nil
body = xmlData.xpath("./w:document[1]/w:body[1]", namespace); nil

wp = body.xpath("./w:p", namespace); nil
wp.each do |p|
    content = ""
    elementToRemoved = []
    p.xpath("./w:r", namespace).each do |r|
        content += r.content
        elementToRemoved.push r
    end
    newElements = readFuri content
    newElements.each do |e|
        elementToRemoved.first.previous = e
    end

    unless newElements.empty?
        elementToRemoved.each {|s| s.remove}; nil
    end
end

File.open(ARGV[0], "w") {|f| f.write doc}