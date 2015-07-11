#!/usr/bin/env ruby

# file: dockerfilemerge.rb

require 'lineparser'
require 'rxfhelper'

class DockerfileMerge

  attr_reader :to_s

  def initialize(raw_s)

    s, type = RXFHelper.read(raw_s)
    
    patterns = [
      [:root, /INCLUDE\s*(?<path>.*)?/, :include],
        [:include, /(?<path>.*)/, :dockerfile],
      [:root, /MAINTAINER (?<name>.*)/, :maintainer],
      [:root, /RUN (?<command>.*)/, :run],
      [:all, /#/, :comment]
    ]

    s.sub!(/\A# Dockermergefile/,'# Dockerfile')
    a = LineParser.new(patterns, ignore_blank_lines: false).parse s

    lines = []
  
    if type == :url then
      lines << '# Generated ' + Time.now.strftime("%a %d-%b-%Y %-I:%M%P")
      lines << '# source: ' + raw_s
    end


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
        i+=1 while lines[i][/\\\s*$/]
        lines.insert(i+1, r.first)        
        lines.insert(i+2, '  ' + r[1..-1].join("\n  ").rstrip) if r.length > 1

      end
      
    end
    
    singlify lines, /^\s*FROM /
    lines.grep(/^\s*CMD /)[0..-2].each {|x| lines.delete x}

    @to_s = lines.join("\n")
  end
  
  private
  
  def merge_file(lines, path)
    
    raw_buffer, type = RXFHelper.read(path)
    buffer = raw_buffer[/^\bINCLUDE\b/] ? \
          DockerfileMerge.new(raw_buffer).to_s : raw_buffer
    
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