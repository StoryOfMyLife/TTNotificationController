#
#  Be sure to run `pod spec lint TTNotificationController.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "TTNotificationController"
  s.version      = "0.0.1"
  s.summary      = "TTNotificationController makes observing notifications easier, taking care of removing notifications in dealloc is no longer necessary."

  s.homepage     = "https://github.com/StoryOfMyLife/TTNotificationController"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "liuty" => "6tingy@gmail.com" }

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/StoryOfMyLife/TTNotificationController.git", :tag => "0.0.1" }


  s.requires_arc = true

end
