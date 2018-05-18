
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tenant_check/version"

Gem::Specification.new do |spec|
  spec.name          = "tenant_check"
  spec.version       = TenantCheck::VERSION
  spec.authors       = ["Shunichi Ikegami"]
  spec.email         = ["sike.tm@gmail.com"]

  spec.summary       = %q{detect queries without tenant.}
  spec.description   = %q{detect queries without tenant.}
  spec.homepage      = "https://github.com/shunichi/tenant_check"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activerecord', '>= 5.1.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
end
