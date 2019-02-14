#
# Be sure to run `pod lib lint CarriersSharedAPI.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CarriersSharedAPI'
  s.version          = '0.1.0'
  s.summary          = 'CarriersSharedAPI'

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
  s.swift_version    = '4.2'

  # s.module_name = 'CarriersSharedAPI'
  s.ios.deployment_target = '10.0'

  s.source_files = 'CarriersSharedAPI/Sources/**/*'
  s.public_header_files = 'CarriersSharedAPI/**/*.h'
  # s.resource_bundles = {
  #   'CarriersSharedAPI' => ['CarriersSharedAPI/Assets/*.png']
  # }   

  s.frameworks = 'UIKit'
  s.dependency 'AppAuth', '~> 0.95.0'

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'CarriersSharedAPI/Tests/**/*.swift'
#    test_spec.resources = 'CarriersSharedAPI/Tests/Resources/**/*'
    test_spec.frameworks = 'XCTest'
  end
end
