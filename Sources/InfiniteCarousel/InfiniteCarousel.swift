//
// InfiniteCarousel.swift
// InfiniteCarousel
//
// Created by EJLee1209 on 11/6/25
// Copyright © 2025 EJLee1209. All rights reserved.
//

import UIKit

/// `InfiniteCarouselDelegate` defines the interface for injecting cells to be displayed
/// in the carousel or for handling events that occur within `InfiniteCarousel`.
///
/// All delegate method calls are guaranteed to happen on the **main thread**.
@MainActor
protocol InfiniteCarouselDelegate: AnyObject {
    // MARK: - Required
    
    /// Requests the delegate to return the cell corresponding to the specified index.
    ///
    /// - Parameters:
    ///   - infiniteCarousel: The `InfiniteCarousel` instance requesting the cell
    ///   - index: The index corresponding to the cell in the original data array
    /// - Returns: A configured `UICollectionViewCell` instance
    func infiniteCarousel(_ infiniteCarousel: InfiniteCarousel, cellForItemAt index: Int) -> UICollectionViewCell
    
    // MARK: - Optional
    
    /// Notifies the delegate when an item in the carousel is selected.
    ///
    /// - Parameters:
    ///   - infiniteCarousel: The `InfiniteCarousel` instance where the item was selected
    ///   - index: The index of the selected item
    func infiniteCarousel(_ infiniteCarousel: InfiniteCarousel, didSelectItemAt index: Int)
    
    /// Notifies the delegate when the carousel stops scrolling and moves to a new page.
    ///
    /// - Parameters:
    ///   - infiniteCarousel: The `InfiniteCarousel` instance whose index has changed
    ///   - index: The index of the currently displayed item
    func infiniteCarousel(_ infiniteCarousel: InfiniteCarousel, didChangeIndex index: Int)
}

/// Provides default implementations for the optional methods of `InfiniteCarouselDelegate`.
extension InfiniteCarouselDelegate {
    func infiniteCarousel(_ infiniteCarousel: InfiniteCarousel, didSelectItemAt index: Int) {}
    func infiniteCarousel(_ infiniteCarousel: InfiniteCarousel, didChangeIndex index: Int) {}
}

/// A custom UICollectionView-based view that provides bidirectional infinite scrolling functionality.
final class InfiniteCarousel: UIView {
    //*******************************************************
    // MARK: - UI
    //*******************************************************
    /// The `UICollectionView` instance used to render the carousel.
    private var collectionView: CustomCollectionView
    
    //*******************************************************
    // MARK: - Property
    //*******************************************************
    // The delegate to handle carousel events and cell configuration
    weak var delegate: InfiniteCarouselDelegate?
    /// The **original data array** exposed to the outside
    private var dataArray: [Any] = .init()
    /// The **extended data array** with elements added to the front and back for infinite scrolling
    private var dataArrayForInfinite: [Any] = .init()
    /// Flag to check if the initial scroll position has been set
    private var isInitScroll = false
    
    //*******************************************************
    // MARK: - init
    //*******************************************************
    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = CustomCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        self.collectionView = collectionView
        
        super.init(frame: frame)
        
        initLayout()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Register layoutSubviews callback inside the collection view
        collectionView.onLayoutSubviews = { [weak self] in
            guard let self else { return }
            guard !isInitScroll else { return }
            
            // Scroll to the initial position (index 1) when collection view layout is complete
            scrollTo(index: 1)
            self.isInitScroll = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //*******************************************************
    // MARK: - Method
    //*******************************************************
    /// Initializes subview layout and sets constraints.
    private func initLayout() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: rightAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    /// Converts a **virtual index** for infinite scrolling to the **actual index** of the original data array.
    ///
    /// - Parameter fakeIndex: The index of `dataArrayForInfinite`
    /// - Returns: A valid index of `dataArray`, returns `nil` if there is one or zero data items.
    private func toRealIndex(from fakeIndex: Int) -> Int? {
        guard dataArray.count > 1 else {
            return nil
        }
        
        let relativeIndex: Int
        // Left extended index
        if fakeIndex == 0 {
            // The real index is the last index of the original data
            relativeIndex = dataArray.count - 1
        } else {
            relativeIndex = fakeIndex - 1
        }
        return relativeIndex % dataArray.count
    }
    
    /// Scrolls the collection view to the specified index.
    ///
    /// - Parameters:
    ///   - index: The index of `dataArrayForInfinite` to scroll to
    ///   - animated: Whether to use an animation effect (default: `false`)
    private func scrollTo(index: Int, animated: Bool = false) {
        guard dataArrayForInfinite.count > index else { return }
        
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
    
    /// Registers a cell type with the collection view.
    ///
    /// - Parameters:
    ///   - cellType: The type of `UICollectionViewCell` to register
    ///   - forCellWithReuseIdentifier: The reuse identifier string
    func register(cellType: UICollectionViewCell.Type, forCellWithReuseIdentifier: String) {
        collectionView.register(cellType, forCellWithReuseIdentifier: String(describing: cellType))
    }
    
    /// Dequeues a reusable cell corresponding to the specified index.
    ///
    /// - Parameters:
    ///   - identifier: The reuse identifier of the cell
    ///   - index: The index of the item requesting the cell
    /// - Returns: A reusable `UICollectionViewCell`
    func dequeueReusableCell(withReuseIdentifier identifier: String, for index: Int) -> UICollectionViewCell {
        let indexPath = IndexPath(item: index, section: 0)
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }
    
    /// Sets the original data array to be displayed in the carousel.
    ///
    /// This function internally expands the data array (`dataArrayForInfinite`) for infinite carousel implementation and refreshes the view (`reloadData()`).
    ///
    /// - Parameter dataArray: The data array to use for the carousel
    func setDataArray(_ dataArray: [Any]) {
        self.dataArray = dataArray
        
        if dataArray.count <= 1 {
            dataArrayForInfinite = dataArray
        } else {
            // Add one element to the front/back for infinite scrolling.
            // Example: [A, B, C] -> [C, A, B, C, A]
            dataArrayForInfinite = dataArray.suffix(1) + dataArray + dataArray.prefix(1)
        }
        isInitScroll = false
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension InfiniteCarousel: UICollectionViewDataSource {
    /// Returns the number of items in the collection view.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataArrayForInfinite.count
    }

    /// Returns the cell for the specified index path.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let realIndex = toRealIndex(from: indexPath.item) else { return .init() }
        return delegate?.infiniteCarousel(self, cellForItemAt: realIndex) ?? .init()
    }
}

// MARK: - UICollectionViewDelegate
extension InfiniteCarousel: UICollectionViewDelegate {
    /// Notifies the delegate when an item is selected.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let realIndex = toRealIndex(from: indexPath.item) else { return }
        delegate?.infiniteCarousel(self, didSelectItemAt: realIndex)
    }
    
    /// Performs infinite loop handling when scrolling occurs.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard dataArray.count > 1 else { return }
        
        let pageValue = collectionView.contentOffset.x / collectionView.frame.width
        if pageValue <= 0 {
            scrollTo(index: dataArrayForInfinite.count - 2)
        } else if pageValue >= CGFloat(dataArrayForInfinite.count - 1) {
            scrollTo(index: 1)
        }
    }
    
    /// Notifies the delegate of the current index change when the scroll animation stops.
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let fakeIndex = Int(collectionView.contentOffset.x / collectionView.frame.width)
        guard let realIndex = toRealIndex(from: fakeIndex) else { return }
        delegate?.infiniteCarousel(self, didChangeIndex: realIndex)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension InfiniteCarousel: UICollectionViewDelegateFlowLayout {
    /// Sets the size of each item to the full size of the collection view.
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        // TODO: Improve to allow customization from outside
        return collectionView.frame.size
    }
    
    /// Sets the minimum spacing between items to 0. (Required for Paging Mode)
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        // TODO: Improve to allow customization from outside
        return .zero
    }
}
