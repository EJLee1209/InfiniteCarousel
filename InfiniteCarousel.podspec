Pod::Spec.new do |spec|

  spec.name         = "InfiniteCarousel"
  spec.version      = "1.0.1"
  spec.summary      = "A custom UICollectionView-based view that provides bidirectional infinite scrolling functionality."
  spec.description  = <<-DESC
  A UI component for implementing an infinitely looping carousel using UICollectionView.
                   DESC
                   
  spec.homepage     = "https://github.com/EJLee1209/InfiniteCarousel"
  spec.license          = { :type => 'MIT', :file => 'LICENSE' }
  spec.author             = { "EJLee1209" => "dldmswo1209@gmail.com" }
  spec.source       = { :git => "https://github.com/EJLee1209/InfiniteCarousel", :tag => spec.version.to_s }
  
  spec.source_files     = 'Sources/InfiniteCarousel/*.swift'
  
  spec.ios.deployment_target = "13.0"
  spec.swift_version    = '6.2'
  spec.frameworks       = 'UIKit'
  
end
