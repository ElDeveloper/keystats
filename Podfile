# file taken from guides.cocoapods.org
#
# source 'https://github.com/CocoaPods/Specs.git'

platform :macos, '10.9'
inhibit_all_warnings!

target 'Keystats' do
  pod 'CorePlot', '~> 2.2.0'
  pod 'FMDB', '~> 2.7'

  # inherits the main app's deps
  target 'KeystatsTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts target.name
  end
end
