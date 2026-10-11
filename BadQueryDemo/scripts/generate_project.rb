#!/usr/bin/env ruby
# Generates BadQueryDemo.xcodeproj from the sources in BadQueryDemo/.
# Requires the `xcodeproj` gem:  gem install xcodeproj
#
# Usage:  ruby BadQueryDemo/scripts/generate_project.rb

require 'xcodeproj'
require 'fileutils'

root = File.expand_path('..', __dir__)               # .../BadQueryDemo
proj_path = File.join(root, 'BadQueryDemo.xcodeproj')

FileUtils.rm_rf(proj_path) if File.exist?(proj_path)

project = Xcodeproj::Project.new(proj_path)
target = project.new_target(:application, 'BadQueryDemo', :ios, '17.0')

src_group = project.main_group.new_group('BadQueryDemo', 'BadQueryDemo')

%w[BadQueryDemoApp.swift ContentView.swift ContainerStore.swift].each do |name|
  ref = src_group.new_file(name)
  target.add_file_references([ref])
end

# Navigator references only — not added to any build phase.
src_group.new_file('Info.plist')
src_group.new_file('BadQueryDemo.entitlements')

common = {
  'PRODUCT_BUNDLE_IDENTIFIER'     => 'com.example.demo_data',
  'PRODUCT_NAME'                  => 'BadQueryDemo',
  'INFOPLIST_FILE'                => 'BadQueryDemo/Info.plist',
  'GENERATE_INFOPLIST_FILE'       => 'NO',
  'IPHONEOS_DEPLOYMENT_TARGET'    => '17.0',
  'SWIFT_VERSION'                 => '5.0',
  'TARGETED_DEVICE_FAMILY'        => '1,2',
  'MARKETING_VERSION'             => '1.0',
  'CURRENT_PROJECT_VERSION'       => '1',
  'CODE_SIGN_STYLE'               => 'Automatic',
  'DEVELOPMENT_TEAM'              => '',
  'ENABLE_USER_SCRIPT_SANDBOXING' => 'YES',
  'SWIFT_EMIT_LOC_STRINGS'        => 'YES',
  'LD_RUNPATH_SEARCH_PATHS'       => '$(inherited) @executable_path/Frameworks'
}

target.build_configurations.each do |config|
  common.each { |k, v| config.build_settings[k] = v }
  # No asset catalog in this demo — drop the icon/accent settings the gem
  # adds by default so nothing expects AppIcon/AccentColor to exist.
  config.build_settings.delete('ASSETCATALOG_COMPILER_APPICON_NAME')
  config.build_settings.delete('ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME')
end

project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['ALWAYS_SEARCH_USER_PATHS'] = 'NO'
end

project.save

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(proj_path, 'BadQueryDemo', true)

puts "Generated #{proj_path}"
