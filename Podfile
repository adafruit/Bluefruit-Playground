source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

target 'BluefruitPlayground' do
    platform :ios, '13.0'
  	pod 'MSWeakTimer', '~> 1.1.0'
    pod 'FlexColorPicker', '~> 1.4.4' # Note: careful when updating because source code has been modified to use HSBColor extension constructor in Xcode15
    pod 'Charts', '~> 3.6.0'          # Note: careful when updating because the source code has been modified to conform to RangeReplaceableCollection
    pod 'ActiveLabel', '~> 1.1.0'

    post_install do |installer|
      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
        end
      end
    end
    
end


