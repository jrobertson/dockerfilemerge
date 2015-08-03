#!/usr/bin/env ruby

# file: dockerfilemerge.rb

require 'lineparser'
require 'rxfhelper'

class DockerfileMerge

  attr_reader :to_s

  def initialize(raw_s)

    s, type = RXFHelper.read(raw_s)
    
    patterns = [
      [:root, /FROM\s+(?<from>.*)/, :from],
      [:root, /INCLUDE\s*(?<path>.*)?/, :include],
        [:include, /(?<path>.*)/, :dockerfile],
      [:root, /MAINTAINER (?<name>.*)/, :maintainer],
      [:root, /RUN (?<command>.*)/, :run],
      [:root, /-\/[^\/]+\/(?:\[[^\]]+\])?/, :del],
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
      
      line = r.first
      
      case label
      when :from
        
        lines << line
        lines << '' if r.length > 1        
        
      when :comment
        
        lines << line
        lines << '' if r.length > 1

      when :include

        h[:path].length > 0 ? merge_file(lines, h[:path]) :
                  c.each {|source| merge_file lines, source[1][:path] }
        lines << '' if r.length > 1

      when :maintainer

        maintainers = lines.grep(/MAINTAINER/)
        i = lines.index maintainers.shift
        lines[i] = line
        
        maintainers.each {|x| lines.delete x}
        
      when :run

        # find the last run command and add the present run command after it
        
        i = lines.index lines.grep(/RUN/).last
        i+=1 while lines[i][/\\\s*$/]
        lines.insert(i+1, line)
        lines.insert(i+2, '  ' + r[1..-1].join("\n  ").rstrip) if r.length > 1

      when :del

        exp, filter = line.match(/-\/([^\/]+)\/(\[[^\]]+\])?/).captures

        name = if filter then

          case filter[1..-2]
          when'0..-2'
            :singlify_last
          when '1..-1'
            :singlify_first
          else
            puts 'unrecognised selector'
          end
        else
          :delete_all
        end        
        
        method(name).call(lines, exp) if name.is_a? Symbol
        
      end      
      
    end
    
    singlify_first lines, /^\s*FROM /
    singlify_last lines, /^\s*CMD /
    s = lines.join("\n")

    rm_sources = /rm -rf \/var\/lib\/apt\/lists\/\*/
    rm_sources_count = s.scan(rm_sources).length
    
    if rm_sources_count > 1 then
      (rm_sources_count - 1).times { remove_command(rm_sources,s) }
    end
    
    @to_s = s
  end
  
  private
  
  def delete_all(lines, regex)
    lines.reject! {|x| x[regex]}
  end
    
  def merge_file(lines, path)

    raw_buffer, type = RXFHelper.read(path)
    buffer = raw_buffer[/^\bINCLUDE\b/] ? \
          DockerfileMerge.new(raw_buffer).to_s : raw_buffer
    
    rows = buffer.lines.map(&:chomp)
    lines << "\n\n# copied from " + path if type == :url
    rows.grep(/^# Pull /).each {|x| rows.delete x}

    lines.concat rows
  end
  
  def remove_command(regex, s)    
    s.sub!(/(?:\\?\s*&&\s+)#{regex}\s*$|\
           (?:RUN\s+|\s*&&\s+||&&\s*\\\s*)?#{regex}(?:\s+\\)? */,'')
  end
  
  # removes any matching lines after the 1st matching line
  #
  def singlify_first(lines, raw_regex)
    
    regex = raw_regex.is_a?(Regexp) ? raw_regex : Regexp.new(raw_regex)
    i = 0
    lines.reject! {|x| found = x[regex]; i += 1 if found;  i > 1 and found }
  end
  
  # removes any matching lines before the last matching line
  #
  def singlify_last(lines, raw_regex)
    
    regex = raw_regex.is_a?(Regexp) ? raw_regex : Regexp.new(raw_regex)
    lines.grep(regex)[0..-2].each {|x| lines.delete x}
  end  
end