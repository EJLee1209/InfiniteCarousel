//
// ViewController.swift
// ExInfiniteCarousel
//
// Created by EJLee1209 on 11/11/25
// Copyright © 2025 EJLee1209. All rights reserved.
//

import UIKit
import InfiniteCarousel

final class ViewController: UIViewController {
    private let infiniteCarousel: InfiniteCarousel = {
        let carousel = InfiniteCarousel()
        carousel.isAutoScroll = true
        carousel.spacing = 24
        carousel.contentInset = .init(top: 0, left: 48, bottom: 0, right: 48)
        carousel.register(cellType: CarouselItemView.self, forCellWithReuseIdentifier: CarouselItemView.identifier)
        carousel.translatesAutoresizingMaskIntoConstraints = false
        return carousel
    }()
    
    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.pageIndicatorTintColor = .systemGray4
        control.currentPageIndicatorTintColor = .systemIndigo
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let numbers = (1...3).map { $0 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configUI()
        
        infiniteCarousel.delegate = self
        infiniteCarousel.setDataArray(numbers)
        
        pageControl.numberOfPages = numbers.count
        pageControl.addTarget(self, action: #selector(handleChangePageControlValue(_:)), for: .valueChanged)
    }
    
    private func configUI() {
        view.backgroundColor = .white
        
        view.addSubview(infiniteCarousel)
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([
            infiniteCarousel.leftAnchor.constraint(equalTo: view.leftAnchor),
            infiniteCarousel.rightAnchor.constraint(equalTo: view.rightAnchor),
            infiniteCarousel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            infiniteCarousel.heightAnchor.constraint(equalToConstant: 240),
            
            pageControl.topAnchor.constraint(equalTo: infiniteCarousel.bottomAnchor, constant: 12),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func handleChangePageControlValue(_ sender: UIPageControl) {
        infiniteCarousel.setPage(index: sender.currentPage, animated: true)
    }
}

extension ViewController: InfiniteCarouselDelegate {
    func infiniteCarousel(_ infiniteCarousel: InfiniteCarousel, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = infiniteCarousel.dequeueReusableCell(withReuseIdentifier: CarouselItemView.identifier, for: index)
        if let itemCell = cell as? CarouselItemView {
            itemCell.numberLabel.text = String(numbers[index])
        }
        
        return cell
    }
    
    func infiniteCarousel(_ infiniteCarousel: InfiniteCarousel, didSelectItemAt index: Int) {
        print("infiniteCarousel(didSelectItemAt:) : \(index)")
    }
    
    func infiniteCarousel(_ infiniteCarousel: InfiniteCarousel, didChangeIndex index: Int) {
        self.pageControl.currentPage = index
    }
}

