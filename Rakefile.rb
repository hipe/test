# require 'spec' thanks webrat
require 'spec/rake/spectask'
require 'rcov/rcovtask'
require 'ruby-debug'

# desc "Run API and Core specs -- lose this. we are using bacon now"
# Spec::Rake::SpecTask.new do |t|
#   t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
#   t.spec_files = FileList['spec/public/*_spec.rb'] + FileList['spec/private/**/*_spec.rb']
# end
#


desc 'Removes trailing whitespace'
task :whitespace do
  sh %{find . -name '*.rb' -exec sed -i '' 's/ *$//g' {} \\;}
end

Rcov::RcovTask.new do |t|
  t.test_files = FileList['spec/spec_*.rb']
  t.verbose = true     # uncomment to see the executed command
  t.rcov_opts = ['--exclude', 'spec,/Library/Ruby/Gems/1.8/gems']
end


# thanks manveru
desc 'Run all bacon specs with pretty output'
task :bacon do
  require 'open3'
  require 'scanf'
  require 'matrix'

  PROJECT_SPECS = FileList[
    'spec/spec_*.rb'
  ]

  specs = PROJECT_SPECS

  some_failed = false
  specs_size = specs.size
  len = specs.map{|s| s.size }.sort.last
  total_tests = total_assertions = total_failures = total_errors = 0
  totals = Vector[0, 0, 0, 0]

  red, yellow, green = "\e[31m%s\e[0m", "\e[33m%s\e[0m", "\e[32m%s\e[0m"
  left_format = "%4d/%d: %-#{len + 11}s"
  spec_format = "%d specifications (%d requirements), %d failures, %d errors"

  load_path = File.expand_path('./lib', __FILE__)

  specs.each_with_index do |spec, idx|
    print(left_format % [idx + 1, specs_size, spec])

    # Open3.popen3(RUBY, '-I', load_path, spec) do |sin, sout, serr|
    Open3.popen3('bacon','-I', load_path, spec) do |sin, sout, serr|
      out = sout.read.strip
      err = serr.read.strip

      # this is conventional
      if out =~ /^Bacon::Error: (needed .*)/
        puts(yellow % ("%6s %s" % ['', $1]))
      elsif out =~ /^Spec (precondition: "[^"]*" failed)/
        puts(yellow % ("%6s %s" % ['', $1]))
      elsif out =~ /^Spec require: "require" failed: "(no such file to load -- [^"]*)"/
        puts(yellow % ("%6s %s" % ['', $1]))
      else
        total = nil
        out.each_line do |line|
          scanned = line.scanf(spec_format)
          #puts line
          next unless scanned.size == 4
          total = Vector[*scanned]
          break
        end
        if total
          totals += total
          tests, assertions, failures, errors = total_array = total.to_a

          if tests > 0 && failures + errors == 0
            puts((green % "%6d passed") % tests)
          else
            some_failed = true
            puts(red % "       failed")
            puts out unless out.empty?
            puts err unless err.empty?
          end
        else
          some_failed = true
          puts(red % "       failed")
          puts out unless out.empty?
          puts err unless err.empty?
        end
      end
    end
  end

  total_color = some_failed ? red : green
  puts(total_color % (spec_format % totals.to_a))
  exit 1 if some_failed
end
