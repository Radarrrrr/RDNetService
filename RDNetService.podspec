Pod::Spec.new do |s|

  s.name         = "RDNetService"
  s.version      = "1.0.0"
  s.summary      = "An easy, simple, convenient tool for http request, dependent on AFNetworking"
  s.homepage     = "https://github.com/Radarrrrr/RDNetService"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Radar" => "imryd@163.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/Radarrrrr/RDNetService.git", :tag => "1.0.0" }
  s.source_files  = "RDNetService/*"
  s.dependency "AFNetworking"

end