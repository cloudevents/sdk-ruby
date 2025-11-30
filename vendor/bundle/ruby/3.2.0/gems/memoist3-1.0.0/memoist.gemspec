lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'memoist/version'

AUTHORS = [
  ['Joshua Peek',               'josh@joshpeek.com'],
  ['Tarmo Tänav',               'tarmo@itech.ee'],
  ['Jeremy Kemper',             'jeremy@bitsweat.net'],
  ['Eugene Pimenov',            'libc@mac.com'],
  ['Xavier Noria',              'fxn@hashref.com'],
  ['Niels Ganser',              'niels@herimedia.co'],
  ['Carl Lerche & Yehuda Katz', 'wycats@gmail.com'],
  ['jeem',                      'jeem@hughesorama.com'],
  ['Jay Pignata',               'john.pignata@gmail.com'],
  ['Damien Mathieu',            '42@dmathieu.com'],
  ['José Valim',                'jose.valim@gmail.com'],
  ['Matthew Rudy Jacobs',       'matthewrudyjacobs@gmail.com'],
  ['Jan Sterba',                'info@jansterba.com']
].freeze

Gem::Specification.new do |spec|
  spec.name          = 'memoist3'
  spec.version       = Memoist::VERSION
  spec.authors       = AUTHORS.map { |name, _email| name }
  spec.email         = AUTHORS.map { |_name, email| email }
  spec.summary       = 'memoize methods invocation'
  spec.homepage      = 'https://github.com/honzasterba/memoist'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.2'

  spec.add_development_dependency 'benchmark-ips'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest', '~> 5.10'
  spec.add_development_dependency 'rake'
end
