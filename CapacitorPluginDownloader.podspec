require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'CapacitorPluginDownloader'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = 'https://github.com/thanhhoa214/capacitor-plugin-downloader'
  s.author = 'Osei Fortune'
  s.source = { :git => '', :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/Plugin/*.{swift,h,m,c,cc,mm,cpp}' ,'ios/Plugin/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target  = '11.0'
  s.dependency 'Capacitor'
  s.dependency 'Alamofire'
end
