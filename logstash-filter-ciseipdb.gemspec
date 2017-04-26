Gem::Specification.new do |s|

  s.name            = 'logstash-filter-ciseipdb'
  s.version         = '0.12.0'
  s.licenses        = ['Apache-2.0']
  s.summary         = "Lookup and inject IP database information into events"
  s.description     = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program"
  s.authors         = ["Sohonet"]
  s.email           = 'support@sohonet.com'
  s.homepage        = "https://github.com/sohonetlabs/logstash-filter-ciseipdb"
  s.require_paths = ["lib"]

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 1.0"
  s.add_runtime_dependency "gdbm", ">= 0"
  s.add_runtime_dependency "redis", ">= 0"

  s.add_development_dependency 'logstash-devutils'
end

