//
// CarouselItemView.swift
// ExInfiniteCarousel
//
// Created by EJLee1209 on 11/11/25
// Copyright © 2025 EJLee1209. All rights reserved.
//

import UIKit

final class CarouselItemView: UICollectionViewCell {
    let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = .black
        label.clipsToBounds = true
        label.layer.cornerRadius = 16
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    static var identifier: String {
        return String(describing: self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //*******************************************************
    // MARK: - Helpers
    //*******************************************************
    /**
     * UI 레이아웃 초기화
     * - Author: EJLee1209
     */
    private func configUI() {
        contentView.addSubview(numberLabel)
        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            numberLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            numberLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            numberLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        ])
    }
}

