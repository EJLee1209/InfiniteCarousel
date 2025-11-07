// 
// CustomCollectionView.swift
// InfiniteCarousel
//
// Created by EJLee1209 on 11/6/25
// Copyright © 2025 EJLee1209. All rights reserved.
//
        
import UIKit

/// A custom class that inherits from `UICollectionView` and adds an
/// external callback feature for the moment `layoutSubviews()` is called.
final class CustomCollectionView: UICollectionView {
    
    /// A closure to be executed after `layoutSubviews()` is called.
    /// This allows specific logic (e.g., setting the initial scroll position)
    /// to be performed once the view's layout is complete.
    var onLayoutSubviews: (() -> Void)?
    
    /// Overrides the method called when the subviews' layouts are rearranged.
    override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutSubviews?()
    }
}
