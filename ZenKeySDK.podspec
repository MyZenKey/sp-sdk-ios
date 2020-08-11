#
# Be sure to run `pod lib lint ZenKeySDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZenKeySDK'
  s.version          = '1.1.1'
  s.summary          = 'ZenKeySDK'
  s.description      = <<-DESC
  The ZenKey SDK enables service providers to authenticate users with their mobile device or web browser.
                       DESC

  s.homepage          = 'https://github.com/MyZenKey/sp-sdk-ios'
  s.documentation_url = 'http://developer.myzenkey.com/'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license           = { :type => 'custom', :file => 'LICENSE' }
  s.author            = { 'ZenKey' => 'techsupport@myzenkey.com' }
  s.source            = { :git => 'https://github.com/MyZenKey/sp-sdk-ios.git', :tag => s.version.to_s }
  s.swift_version     = '5'

  # s.module_name = 'ZenKeySDK'
  s.ios.deployment_target = '10.0'

  s.ios.source_files = ['ZenKeySDK/Sources/Core/**/*', 'ZenKeySDK/Sources/iOS/**/*']
  s.public_header_files = 'ZenKeySDK/**/*.h'
  s.resources = ['ZenKeySDK/Resources/*.xcassets', 'ZenKeySDK/Resources/*.strings']

  s.ios.frameworks = 'UIKit', 'SafariServices'
  s.weak_framework = 'CryptoKit'

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'ZenKeySDK/Tests/**/*.swift'
    # test_spec.resources = 'ZenKeySDK/Tests/Resources/**/*'
    test_spec.frameworks = 'XCTest'
  end
end
