desc "Run tests"
task :test do
  Dir.glob('./test/**/test_*.rb').each { |file| require file }
end

task :default => :test
