//
//  IllustrationMarkView.swift
//  Soou.me
//
//  Created by Piotr Olech on 13/09/2018.
//  Copyright © 2018 altconnect. All rights reserved.
//

import UIKit

protocol IllustrationMarkViewDelegate: class {
    func removeMark(in illustrationMarkView: IllustrationMarkView)
    func bringMarkToFront(in illustrationMarkView: IllustrationMarkView)
}

class IllustrationMarkView: UIView {
    
    // MARK: - Public properties
    
    weak var delegate: IllustrationMarkViewDelegate?
    
    // MARK: - Views
    
    private lazy var removeButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(removeView(sender:)), for: .touchUpInside)
        button.setImage(UIImage(named: "Trash")?.withRenderingMode(.alwaysTemplate) , for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .green
        self.addSubview(button)
        
        return button
    }()
    
    private lazy var imageWrapperView: UIControl = {
        let control = UIControl(frame: .zero)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(bringViewToFront(sender:)), for: .touchUpInside)
        control.backgroundColor = .lightGray
        self.addSubview(control)
        
        return control
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageWrapperView.addSubview(imageView)
        
        return imageView
    }()
    
    private lazy var lineView: TimeIndicatorView = {
        let view = TimeIndicatorView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        
        return view
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = .black
        self.addSubview(label)
        
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupConstraints()
    }
    
    private func setupConstraints() {
        self.setupConstraint(item: self.removeButton, attribute: .top, toItem: self, attribute: .top)
        self.setupConstraint(item: self.removeButton, attribute: .leading, toItem: self, attribute: .leading)
        self.setupConstraint(item: self.removeButton, attribute: .trailing, toItem: self, attribute: .trailing)
        self.setupConstraint(item: self.removeButton, attribute: .height, toItem: self.imageWrapperView, attribute: .height, multiplier: 4/10)
        
        self.setupConstraint(item: self.imageWrapperView, attribute: .top, toItem: self.removeButton, attribute: .bottom, constant: 5.0)
        self.setupConstraint(item: self.imageWrapperView, attribute: .leading, toItem: self, attribute: .leading)
        self.setupConstraint(item: self.imageWrapperView, attribute: .trailing, toItem: self, attribute: .trailing)
        self.setupConstraint(item: self.imageWrapperView, attribute: .width, toItem: self.imageWrapperView, attribute: .height, multiplier: 3/4)
        
        self.setupConstraint(item: self.imageView, attribute: .top, toItem: self.imageWrapperView, attribute: .top, constant: 3.0)
        self.setupConstraint(item: self.imageView, attribute: .leading, toItem: self.imageWrapperView, attribute: .leading, constant: 3.0)
        self.setupConstraint(item: self.imageWrapperView, attribute: .bottom, toItem: self.imageView, attribute: .bottom, constant: 3.0)
        self.setupConstraint(item: self.imageWrapperView, attribute: .trailing, toItem: self.imageView, attribute: .trailing, constant: 3.0)
        
        self.setupConstraint(item: self.lineView, attribute: .top, toItem: self.imageWrapperView, attribute: .bottom, constant: 9.0)
        self.setupConstraint(item: self.lineView, attribute: .centerX, toItem: self, attribute: .centerX)

        self.setupConstraint(item: self.timeLabel, attribute: .top, toItem: self.lineView, attribute: .bottom, constant: 10.0)
        self.setupConstraint(item: self, attribute: .bottom, toItem: self.timeLabel, attribute: .bottom)
        self.setupConstraint(item: self.timeLabel, attribute: .centerX, toItem: self, attribute: .centerX)
    }
    
    // MARK: - Access methods
    
    func setTime(_ text: String?) {
        self.timeLabel.text = text
    }
    
    func setImageUrl(_ url: URL?) {
        if let imageURL = url {
            imageView.image = UIImage(named: "mock_book0")
        } else {
            imageView.image = UIImage(named: "mock_book0")
        }
    }
    
    func setSelected(_ selected: Bool) {
        removeButton.isHidden = !selected
        timeLabel.isHidden = !selected
    }

    // MARK: - Actions
    
    @objc private func removeView(sender: UIButton) {
        self.delegate?.removeMark(in: self)
    }
    
    @objc private func bringViewToFront(sender: UIControl) {
        self.delegate?.bringMarkToFront(in: self)
    }
}
