#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_mermaid_native.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_mermaid_native'
  s.version          = '0.1.0'
  s.summary          = 'Native Mermaid diagram rendering for Flutter via Rust.'
  s.description      = <<-DESC
Render Mermaid diagrams in Flutter using a native Rust engine. No WebView.
                       DESC
  s.homepage         = 'https://github.com/pieces-app/flutter_mermaid'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pieces for Developers' => 'https://github.com/pieces-app' }
  s.module_name      = 'flutter_mermaid_native'

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'

  s.script_phase = {
    :name => 'Build Rust library',
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../rust flutter_mermaid_native',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    :output_files => ["${PODS_CONFIGURATION_BUILD_DIR}/flutter_mermaid_native/libflutter_mermaid_native.a"],
  }
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load ${PODS_CONFIGURATION_BUILD_DIR}/flutter_mermaid_native/libflutter_mermaid_native.a',
  }
end
