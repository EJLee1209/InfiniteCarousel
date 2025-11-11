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
public protocol InfiniteCarouselDelegate: AnyObject {
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
public final class InfiniteCarousel: UIView {
    //*******************************************************
    // MARK: - UI
    //*******************************************************
    
    /// The `UICollectionView` instance used to render the carousel.
    private var collectionView: CustomCollectionView
    
    //*******************************************************
    // MARK: - Property
    //*******************************************************
    
    // The delegate to handle carousel events and cell configuration
    public weak var delegate: InfiniteCarouselDelegate?
    
    /// The **original data array** exposed to the outside
    private var dataArray: [Any] = .init()
    
    /// The **extended data array** with elements added to the front and back for infinite scrolling
    private var dataArrayForInfinite: [Any] = .init()
    
    /// Flag to check if the initial scroll position has been set
    private var isInitScroll = false
    
    /// A flag indicating whether auto-scrolling is enabled.
    public var isAutoScroll = false
    
    /// The time interval for automatic scrolling between pages. (Default: 3.0 seconds)
    public var autoScrollTimeInterval: TimeInterval = 3.0
    
    /// The timer object used for continuous automatic scrolling.
    private var autoScrollTimer: Timer?
    
    /// The computed size of a single carousel item, adjusted for the collection view's content inset.
    private var itemSize: CGSize {
        let collectionViewSize = collectionView.frame.size
        let itemWidth = collectionViewSize.width - (contentInset.left + contentInset.right)
        let itemHeight = collectionViewSize.height - (contentInset.top + contentInset.bottom)
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    /// The current page index value based on the content offset, item size, and spacing.
    private var pageValue: CGFloat {
        return (collectionView.contentOffset.x + contentInset.left) / (itemSize.width + spacing)
    }
    
    /// The minimum spacing between adjacent items in the carousel.
    public var spacing: CGFloat = .zero {
        didSet {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    /// The content inset applied to the collection view, determining the visible margin around items.
    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            collectionView.contentInset = contentInset
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
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
        collectionView.isPagingEnabled = false
        collectionView.decelerationRate = .fast
        collectionView.contentInset = contentInset
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
        
        // Subscribe to device orientation change notifications.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChangeDeviceOrientation),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    //*******************************************************
    // MARK: - Private Method
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
        guard fakeIndex >= 0, dataArrayForInfinite.count > fakeIndex else {
            return nil
        }
        guard dataArray.count > 1 else {
            if dataArray.count == 1, fakeIndex == 0 {
                return 0
            }
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
    
    /// Starts the automatic scrolling timer if the data count is greater than 1.
    private func startAutoScroll() {
        guard dataArray.count > 1 else { return }
        
        self.autoScrollTimer = Timer.scheduledTimer(withTimeInterval: autoScrollTimeInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                let pageIndex = Int(self.pageValue)
                self.scrollTo(index: pageIndex + 1, animated: true)
                
                // Manually notify delegate of index change since this scroll is animated
                // and scrollViewDidEndDecelerating won't be called immediately.
                if let nextPageIndex = self.toRealIndex(from: pageIndex + 1) {
                    self.delegate?.infiniteCarousel(self, didChangeIndex: nextPageIndex)
                }
            }
        }
    }
    
    /// Stops and invalidates the current automatic scrolling timer.
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    //*******************************************************
    // MARK: - Public Method
    //*******************************************************
    
    /// Registers a cell type with the collection view.
    ///
    /// - Parameters:
    ///   - cellType: The type of `UICollectionViewCell` to register
    ///   - forCellWithReuseIdentifier: The reuse identifier string
    public func register(cellType: UICollectionViewCell.Type, forCellWithReuseIdentifier: String) {
        collectionView.register(cellType, forCellWithReuseIdentifier: String(describing: cellType))
    }
    
    /// Dequeues a reusable cell corresponding to the specified index.
    ///
    /// - Parameters:
    ///   - identifier: The reuse identifier of the cell
    ///   - index: The index of the item requesting the cell
    /// - Returns: A reusable `UICollectionViewCell`
    public func dequeueReusableCell(withReuseIdentifier identifier: String, for index: Int) -> UICollectionViewCell {
        let indexPath = IndexPath(item: index, section: 0)
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }
    
    /// Sets the original data array to be displayed in the carousel.
    ///
    /// This function internally expands the data array (`dataArrayForInfinite`) for infinite carousel implementation and refreshes the view (`reloadData()`).
    ///
    /// - Parameter dataArray: The data array to use for the carousel
    public func setDataArray(_ dataArray: [Any]) {
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
        
        if isAutoScroll {
            stopAutoScroll()
            startAutoScroll()
        }
    }
    
    /// Moves the carousel directly to the specified real data index.
    ///
    /// This method translates the external real data index into the internal
    /// infinite index and scrolls the collection view.
    ///
    /// - Parameters:
    ///   - index: The real index of the item in the original data array
    ///   - animated: If `true`, the scrolling is animated. If `false`, the scrolling is instantaneous.
    public func setPage(index: Int, animated: Bool) {
        guard index >= 0, dataArray.count > index else { return }
        
        // The real index (0-based) corresponds to the infinite index (index + 1)
        // because of the padded element at the start (index 0).
        let indexForInfinite = index + 1
        scrollTo(index: indexForInfinite, animated: animated)
        
        if isAutoScroll {
            stopAutoScroll()
            startAutoScroll()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension InfiniteCarousel: UICollectionViewDataSource {
    /// Returns the number of items in the collection view.
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataArrayForInfinite.count
    }

    /// Returns the cell for the specified index path.
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let realIndex = toRealIndex(from: indexPath.item) else { return .init() }
        return delegate?.infiniteCarousel(self, cellForItemAt: realIndex) ?? .init()
    }
}

// MARK: - UICollectionViewDelegate
extension InfiniteCarousel: UICollectionViewDelegate {
    /// Notifies the delegate when an item is selected.
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let realIndex = toRealIndex(from: indexPath.item) else { return }
        delegate?.infiniteCarousel(self, didSelectItemAt: realIndex)
    }
    
    /// Performs infinite loop handling when scrolling occurs.
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard dataArray.count > 1 else { return }
        
        if pageValue <= 0 {
            scrollTo(index: dataArrayForInfinite.count - 2)
        } else if pageValue >= CGFloat(dataArrayForInfinite.count - 1) {
            scrollTo(index: 1)
        }
    }
    
    /// Stops the auto-scroll timer when the user starts manually dragging the carousel.
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoScroll()
    }
    
    /// Restarts the auto-scroll timer after the user finishes dragging the carousel.
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if isAutoScroll {
            startAutoScroll()
        }
    }
    
    /// Calculates the target content offset when the user lifts their finger, implementing custom paging behavior.
    ///
    /// Since `isPagingEnabled` is set to `false`, this method ensures the carousel snaps to the center
    /// of the nearest item after deceleration ends, simulating page-by-page scrolling.
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let pageIndex: CGFloat
        if velocity.x >= 0 {
            pageIndex = ceil(pageValue)
        } else {
            pageIndex = floor(pageValue)
        }
        let x = pageIndex * (itemSize.width + spacing) - scrollView.contentInset.left
        targetContentOffset.pointee = CGPoint(x: x, y: scrollView.contentInset.top)
        
        guard let realIndex = toRealIndex(from: Int(pageIndex)) else { return }
        delegate?.infiniteCarousel(self, didChangeIndex: realIndex)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension InfiniteCarousel: UICollectionViewDelegateFlowLayout {
    /// Sets the size of each item to the full size of the collection view.
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return itemSize
    }
    
    /// Sets the minimum spacing between items to 0. (Required for Paging Mode)
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return spacing
    }
}

// MARK: - Notification
extension InfiniteCarousel {
    /// Handles the `UIDevice.orientationDidChangeNotification`.
    ///
    /// When the device orientation changes, this method invalidates the collection view layout
    /// and resets the scroll state to ensure the carousel correctly re-centers and displays
    /// items based on the new dimensions.
    ///
    /// - Parameter notification: The notification object containing orientation change details.
    @objc private func handleChangeDeviceOrientation(_ notification: Notification) {
        isInitScroll = false
        
        collectionView.collectionViewLayout.invalidateLayout()
        setNeedsLayout()
    }
}
