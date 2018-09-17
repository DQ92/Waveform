//
//  RecordingAddedIllustrationMarkView.swift
//  Soou.me
//
//  Created by Piotr Olech on 13/09/2018.
//  Copyright © 2018 altconnect. All rights reserved.
//

import UIKit

protocol RecordingAddedIllustrationMarkViewDelegate {
    func removeIllustrationMark()
}

class RecordingAddedIllustrationMarkView: UIView {
    
    // MARK: - IBOutlets
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var backgroundIllustrationView: UIView!
    @IBOutlet weak var illustrationImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var removeIllustrationButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    // MARK: - Private constants
    
    private let nibName = "RecordingAddedIllustrationMarkView"
    
    // MARK: - Public properties
    
    var delegate: RecordingAddedIllustrationMarkViewDelegate?
    
    // MARK: - Init
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadNib()
        
        setupImageViews()
        setupRemoveIllustrationButton()
        setupLabel()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadNib()
        
        setupImageViews()
        setupRemoveIllustrationButton()
        setupLabel()
    }
    
    private func loadNib() {
        let _ = Bundle.main.loadNibNamed(nibName, owner: self, options: nil)?.first
        translatesAutoresizingMaskIntoConstraints = false
        
        view.frame = bounds
        addSubview(view)
    }
    
    // MARK: - View setup
    
    private func setupLabel() {
        timeLabel.font = UIFont.systemFont(ofSize: 11)
        timeLabel.textColor = .green
    }
    
    private func setupImageViews() {
        backgroundIllustrationView.backgroundColor = .lightGray
        
        illustrationImageView.layer.borderWidth = 2.0
        illustrationImageView.layer.borderColor = UIColor.white.cgColor
    }
    
    private func setupRemoveIllustrationButton() {
        removeIllustrationButton.tintColor = .green
        removeIllustrationButton.backgroundColor = .green
        //removeIllustrationButton.setImage(Assets.trashImage, for: .normal)
    }
    
    // MARK: - Actions
    
    @IBAction func removeIllustrationClicked(_ sender: Any) {
        delegate?.removeIllustrationMark()
    }
}
