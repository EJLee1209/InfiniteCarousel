Pod::Spec.new do |spec|

  spec.name         = "EJInfiniteCarousel"
  spec.version      = "1.0.2"
  spec.summary      = "A custom UICollectionView-based view that provides bidirectional infinite scrolling functionality."
  spec.homepage     = "https://github.com/EJLee1209/InfiniteCarousel"
  spec.license          = { :type => 'MIT', :file => 'LICENSE.txt' }
  spec.author             = { "EJLee1209" => "dldmswo1209@gmail.com" }
  spec.source       = { :git => "https://github.com/EJLee1209/InfiniteCarousel.git", :tag => spec.version.to_s }
  
  spec.source_files     = 'Sources/InfiniteCarousel/**/*'
  
  spec.ios.deployment_target = "13.0"
  spec.swift_version    = '6.2'
  
end
