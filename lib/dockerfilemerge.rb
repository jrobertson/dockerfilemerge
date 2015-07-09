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

    lp = LineParser.new patterns, ignore_blank_lines: false
    a = lp.parse s

    lines = []

    a.each do |x|
      
      case x.first
      when :comment
        lines << x[2].first
        lines << '' if x[2].length > 1

      when :include

        if x[1][:path].length > 0 then
          
          path = x[1][:path]
          
          buffer, type = RXFHelper.read(path)
          rows = buffer.lines.map(&:chomp)
          lines << "\n\n# copied from " + path if type == :url
          rows.grep(/^# Pull /).each {|x| rows.delete x}
          lines.concat rows
          
        else
          
          x[3].each do |source| 
            path = source[1][:path]
            buffer, type = RXFHelper.read(path)
            rows = buffer.lines.map(&:chomp)
            lines << "\n\n# copied from " + path if type == :url
            rows.grep(/^# Pull /).each {|x| rows.delete x}
            lines.concat rows
            
          end
        end

        lines << '' if x[2].length > 1

      when :maintainer

        maintainers = lines.grep(/MAINTAINER/)
        i = lines.index maintainers.shift
        lines[i] = x[2].first
        maintainers.each {|x| lines.delete x}
        
      when :run
        i = lines.index lines.grep(/RUN/).last
        lines.insert(i+1, x[2].first)
        lines.insert(i+2, '') if x[2].length > 1
      end
      
    end
    
    lines.grep(/^FROM /)[1..-1].each {|x| lines.delete x}
    lines.grep(/^CMD/)[0..-2].each {|x| lines.delete x}

    @to_s = lines.join("\n")
  end
end