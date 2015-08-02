Gem::Specification.new do |s|
  s.name = 'dockerfilemerge'
  s.version = '0.4.1'
  s.summary = 'Merge 2 or more Dockerfiles into 1 Dockerfile'
  s.authors = ['James Robertson']
  s.files = Dir['lib/dockerfilemerge.rb']
  s.add_runtime_dependency('lineparser', '~> 0.1', '>=0.1.15')
  s.add_runtime_dependency('rxfhelper', '~> 0.2', '>=0.2.3')
  s.signing_key = '../privatekeys/dockerfilemerge.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/dockerfilemerge'
end
