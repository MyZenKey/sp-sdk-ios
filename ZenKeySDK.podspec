#
# Be sure to run `pod lib lint ZenKeySDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZenKeySDK'
  s.version          = '0.0.1'
  s.summary          = 'ZenKeySDK'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Raizlabs/XCI-ProviderSDK-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'custom', :file => 'LICENSE' }
  s.author           = { 'Adam Tierney' => 'atierney@rightpoint.com' }
  s.source           = { :git => 'https://github.com/Raizlabs/XCI-ProviderSDK-iOS.git', :tag => s.version.to_s }
  s.swift_version    = '5'

  # s.module_name = 'ZenKeySDK'
  s.ios.deployment_target = '10.0'

  s.ios.source_files = ['ZenKeySDK/Sources/Core/**/*', 'ZenKeySDK/Sources/iOS/**/*']
  s.public_header_files = 'ZenKeySDK/**/*.h'
  s.resources = ['ZenKeySDK/Resources/*.xcassets', 'ZenKeySDK/Resources/*.lproj/*.strings']

  s.ios.frameworks = 'UIKit', 'SafariServices'

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'ZenKeySDK/Tests/**/*.swift'
    # test_spec.resources = 'ZenKeySDK/Tests/Resources/**/*'
    test_spec.frameworks = 'XCTest'
  end
end
