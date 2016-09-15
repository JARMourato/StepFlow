Pod::Spec.new do |s|
  s.name             = 'StepFlow'
  s.version          = '2.0.0'
  s.license          = 'MIT'
  s.summary          = 'StepFlow is way to create a stream of macro steps to be executed.'
  s.homepage         = 'https://github.com/JARMourato/StepFlow'
  s.authors          = { 'João Mourato' => 'joao.armourato@gmail.com' }
  
  s.source       = { :git => 'https://github.com/JARMourato/StepFlow.git', :tag => s.version.to_s }

  s.requires_arc = true

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  
  s.source_files = 'Sources/StepFlow/*.swift'
  s.module_name = 'StepFlow'
end
