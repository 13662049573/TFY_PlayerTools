
Pod::Spec.new do |spec|

  spec.name         = "TFY_PlayerToolsKit"

  spec.version      = "2.0.0"

  spec.summary      = "视频播放器主要使用工具封装"

  spec.description  = <<-DESC
  视频播放器主要使用工具封装
                   DESC

  spec.homepage     = "https://github.com/13662049573/TFY_PlayerTools"
  
  spec.license      = "MIT"
  
  spec.author             = { "tfyzxc13662049573" => "420144542@qq.com" }
 
  spec.platform     = :ios, "10.0"

  spec.source       = { :git => "https://github.com/13662049573/TFY_PlayerTools.git", :tag => spec.version }

  spec.source_files  = "TFY_PlayerTools/TFY_PlayerToolsKit/TFY_PlayerToolsKitHeader.h"

  spec.subspec 'TFY_PlayerTool' do |s|
    s.source_files  = "TFY_PlayerTools/TFY_PlayerToolsKit/TFY_PlayerTool/**/*.{h,m}"
  end

  spec.ios.frameworks = 'Foundation', 'UIKit'

  spec.xcconfig      = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include" }
  
  spec.requires_arc = true

end
