#!/usr/bin/env ruby

# file: dockerfilemerge.rb

require 'lineparser'
require 'rxfhelper'

class DockerfileMerge

  attr_reader :to_s

  def initialize(s)

    patterns = [
      [:root, /INCLUDE\s*(?<path>.*)?/, :include],
        [:include, /(?<path>.*)/, :dockerfile],
      [:root, /MAINTAINER (?<name>.*)/, :maintainer],
      [:root, /RUN (?<command>.*)/, :run],
      [:all, /#/, :comment]
    ]

    a = LineParser.new(patterns, ignore_blank_lines: false).parse s

    lines = []

    a.each do |label, h, r, c| # h=hash, r=remaining, c=children
      
      case label
      when :comment
        
        lines << r.first
        lines << '' if r.length > 1

      when :include

        h[:path].length > 0 ? merge_file(lines, h[:path]) :
                  c.each {|source| merge_file lines, source[1][:path] }
        lines << '' if r.length > 1

      when :maintainer

        maintainers = lines.grep(/MAINTAINER/)
        i = lines.index maintainers.shift
        lines[i] = r.first
        
        maintainers.each {|x| lines.delete x}
        
      when :run
        
        i = lines.index lines.grep(/RUN/).last
        lines.insert(i+1, r.first)
        
        if r.length > 1 then
          lines.insert(i+2, '  ' + r[1..-1].join("\n  ").rstrip)
        end
      end
      
    end
    
    singlify lines, /^FROM /
    singlify lines, /^CMD /

    @to_s = lines.join("\n")
  end
  
  private
  
  def merge_file(lines, path)
    
    buffer, type = RXFHelper.read(path)
    rows = buffer.lines.map(&:chomp)
    lines << "\n\n# copied from " + path if type == :url
    rows.grep(/^# Pull /).each {|x| rows.delete x}

    lines.concat rows
  end  
  
  def singlify(lines, regex)
    i = 0
    lines.reject! {|x| found = x[regex]; i += 1 if found;  i > 1 and found }
  end
end