#
# Be sure to run `pod lib lint sscore.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name         = 'FBDLKit'
  s.version      = "0.0.1"
  s.summary      = "FBDLKit ios framework"
  s.homepage     = "https://gitee.com/Local"
  s.license      = { type: 'MIT', file: 'LICENSE' }
  s.author       = { "liusibin" => "liusibin@live.cn" }
  s.source       = { :git => 'https://github.com/sitale/FBDLKit.git', :tag => "#{s.version}" }
  # s.resource              = "LemonDeer/**/*.{png,bundle,xib,pdf,json,xcassets,mp3,json,otf,js,html,jpg}"
  s.source_files          = "LemonDeer/**/*.{m,h,swift}"
  s.public_header_files   = 'LemonDeer**/*.h'
  s.pod_target_xcconfig   = {
                              'SWIFT_VERSION' => '5.0',
                              'DEFINES_MODULE ' => 'YES',
                              'SWIFT_COMPILATION_MODE' => 'wholemodule'
                            }
  s.ios.deployment_target = '15.0'
  s.requires_arc = true
  # s.static_framework = true
  # s.swift_version = '5.0'
  # s.libraries              = 'z'
  s.framework  = "UIKit"
  
  s.pod_target_xcconfig = { 'APPLICATION_EXTENSION_API_ONLY' => 'NO' }
end
