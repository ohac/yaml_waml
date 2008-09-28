# -*- coding: utf-8 -*-
require 'benchmark'
require 'yaml'

class String
  def is_binary_data?
    false
  end
end

data = [ "あいうえお漢字" * 10000, "__BBBBBBBBBBBBBBB__", "あいうえお" * 10000 ]

yaml_str = data.to_yaml
Benchmark.bm do |x|
  x.report('original yaml_waml') {
    yaml_str.gsub(/\\x(\w{2})/) {
      [ Regexp.last_match.captures.first.to_i(16)].pack("C")
    }
  }

  x.report('using $1') {
    yaml_str.gsub(/\\x(\w{2})/) {
      [ $1.to_i(16) ].pack("C")
    }
  }

  x.report('using $1 w/ H2') {
    yaml_str.gsub(/\\x(\w{2})/){
      [$1].pack("H2")
    }
  }

  x.report('with memoize') {
    memoize_of = {}
    yaml_str.gsub(/\\x(\w{2})/) {|s|
      memoize_of[s] ||= [ Regexp.last_match.captures.first.to_i(16)].pack("C")
    }
  }

  x.report('with memoize and $1') {
    memoize_of = {}
    yaml_str.gsub(/\\x(\w{2})/) {|s|
      memoize_of[s] ||= [ $1.to_i(16) ].pack("C")
    }
  }

  x.report('with symbol table ') {
    memoize_of = {}
    chars = %w( 0 1 2 3 4 5 6 7 8 9 A B C D E F )
    chars.each do |char1|
      chars.each do |char2|
        val = char1 + char2
        memoize_of["\\x#{val}"] = [ val.to_i(16) ].pack("C")
      end
    end
    yaml_str.gsub(/\\x\w{2}/) {|s|
      memoize_of[s]
    }
  }

  x.report('packing  multi chars') {
    regex = /\\x/
    # 100は結構てきとう。無条件に大きすぎると返って遅くなりそうな気がするので適当なサイズにしておく
    yaml_str.gsub(/(?:\\x(\w{2})){0,100}/) {|s|
      s.split(regex).compact.map {|s| s.to_i(16) }.pack("C*").gsub("\0", '')
    }
  }

  x.report('packing multi chars with H*') {
    yaml_str.gsub(/(?:\\x(\w{2})){0,100}/) {|s|
      [ s.split(/\\x/).join ].pack('H*')
    }
  }

end

# result on my environment( MacBook Pro Intel Core Duo 2.5 GHz, 4GB), result is like that
#                         user     system      total        real
# original yaml_waml     1.700000   0.030000   1.730000 (  2.460140)
# using $1               1.430000   0.020000   1.450000 (  2.030178)
# using $1 w/ H2         1.160000   0.010000   1.170000 (  1.476650)
# with memoize           0.770000   0.010000   0.780000 (  0.972146)
# with memoize and $1    0.780000   0.010000   0.790000 (  0.973506)
# with symbol table      0.770000   0.010000   0.780000 (  1.102112)
# packing  multi chars   0.740000   0.010000   0.750000 (  0.908722)

# result on walf43's environment( MacBook1.1 Intel Core Duo 1.83 GHz, 2GB), result is like that
#                         user     system      total        real
# original yaml_waml            2.670000   0.030000   2.700000 (  2.756841)
# using $1  2.050000            0.010000   2.060000 (  2.079539)
# using $1 w/ H2                1.800000   0.020000   1.820000 (  1.849095)
# with memoize                  1.110000   0.010000   1.120000 (  1.145967)
# with memoize and $1           1.160000   0.020000   1.180000 (  1.199560)
# with symbol table             1.060000   0.010000   1.070000 (  1.093012)
# packing  multi chars          1.050000   0.010000   1.060000 (  1.117803)
# packing multi chars with H*   0.590000   0.010000   0.600000 (  0.628510)
