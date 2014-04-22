#!/usr/bin/env ruby

require 'multi_json'

data_dir = File.expand_path(ARGV[1] || '.')

min_lon, max_lon, min_lat, max_lat = [122.0, 146.0, 24.0, 46.0]

Dir.glob(File.join(data_dir, '**/*.json')).each do |fname|
  puts "Pre-processing #{fname}"
  filter = /"lng":1(2[2-9]|3[0-9]|4[0-6])\.00,"lat":(2[4-9]|3[0-9]|4[0-6])\.[0-9]{2},"value":-?\d+\.\d+/

  step = 4096
  File.open(File.join(File.dirname(fname), "tokyo_#{File.basename(fname)}"), 'w') do |fout|
    File.open(fname, 'r') do |fin|
      data_start = nil
      while(str = fin.read(step))
        data_start = str.index('[')
        if data_start
          fout.write(str[0..data_start])
          rest = str[data_start..-1]
          while idx = (rest =~ filter)
            fout.write("{#{$&}},")
            rest = rest[(idx + $&.length - 1)..-1]
          end
          break
        else
          fout.write(str)
        end
      end
      first = true
      while(str = fin.read(step))
        append = []
        while idx = (str =~ filter)
          append.push("{#{$&}}")
          str = str[(idx + $&.length - 1)..-1]
        end
        unless append.empty?
          fout.write(',') unless first
          fout.write(append.join(','))
          first = false
        end
      end
    end
    fout.write(']}')
  end
end

