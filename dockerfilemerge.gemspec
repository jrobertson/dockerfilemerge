Gem::Specification.new do |s|
  s.name = 'dockerfilemerge'
  s.version = '0.5.0'
  s.summary = 'Merge 2 or more Dockerfiles into 1 Dockerfile, or split Dockerfiles apart from an XML file'
  s.authors = ['James Robertson']
  s.files = Dir['lib/dockerfilemerge.rb']
  s.add_runtime_dependency('lineparser', '~> 0.1', '>=0.1.19')
  s.add_runtime_dependency('rxfhelper', '~> 0.9', '>=0.9.4')
  s.signing_key = '../privatekeys/dockerfilemerge.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/dockerfilemerge'
end
