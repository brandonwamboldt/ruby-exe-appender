Gem::Specification.new do |s|
  s.name = 'exe_appender'
  s.version = '1.0.0'
  s.summary = "Windows portable executable appender"
  s.description = <<-EOF
Ruby library to append arbitrary data to the end of a Windows Portable Executable without corrupting digital signatures.
EOF

  s.authors << 'Brandon Wamboldt'
  s.email = 'brandon.wamboldt@gmail.com'
  s.homepage = 'http://github.com/brandonwamboldt/ruby-exe-appender'
  s.license = 'MIT'

  s.files = Dir['{lib}/**/*'] + ['README.md', 'LICENSE.md', 'exe_appender.gemspec']
end
