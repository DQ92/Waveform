//
//  RecordingAddedIllustrationMarkView.swift
//  Soou.me
//
//  Created by Piotr Olech on 13/09/2018.
//  Copyright © 2018 altconnect. All rights reserved.
//

import UIKit

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
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss:SS"
        
        return formatter
    }()
    
    // MARK: - Public properties
    
    var removeMarkBlock: (() -> Void)?
    var bringMarkViewToFrontBlock: (() -> Void)?
    var data: IllustrationMarkModel!
    
    // MARK: - Init
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadNib()
        commonSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadNib()
        commonSetup()
    }
    
    private func loadNib() {
        let _ = Bundle.main.loadNibNamed(nibName, owner: self, options: nil)?.first
        translatesAutoresizingMaskIntoConstraints = false
        
        view.frame = frame
        addSubview(view)
    }
    
    // MARK: - View setup
    
    private func commonSetup() {
        setupImageViews()
        setupRemoveIllustrationButton()
        setupLabel()
    }
    
    private func setupLabel() {
        timeLabel.font = UIFont.systemFont(ofSize: 11)
        timeLabel.textColor = .black
    }
    
    private func setupImageViews() {
        backgroundIllustrationView.backgroundColor = .lightGray
        
        illustrationImageView.layer.borderWidth = 2.0
        illustrationImageView.layer.borderColor = UIColor.white.cgColor
        illustrationImageView.image = UIImage(named: "mock_book0")
        
        let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(bringIllustrationMarkViewToFront))
        illustrationImageView.addGestureRecognizer(gestureRecognizer)
        illustrationImageView.isUserInteractionEnabled = true
    }
    
    private func setupRemoveIllustrationButton() {
        removeIllustrationButton.tintColor = .green
        removeIllustrationButton.backgroundColor = .clear
        removeIllustrationButton.setImage(UIImage(named: "Trash"), for: .normal)
    }
    
    func setupTimeLabel(with timeInterval: TimeInterval) {
        timeLabel.text = dateFormatter.string(from: Date(timeIntervalSince1970: timeInterval))
    }
    
    func setupImageView(with imageURL: URL?) {
        if let imageURL = imageURL {
            illustrationImageView.image = UIImage(named: "mock_book0")
        } else {
            illustrationImageView.image = UIImage(named: "mock_book0")
        }
    }
    
    func setupTimeLabelAndRemoveButtonVisibility(isHidden: Bool) {
        removeIllustrationButton.isHidden = isHidden
        timeLabel.isHidden = isHidden
    }
    
    // MARK: - Actions
    
    @IBAction func removeIllustrationClicked(_ sender: Any) {
       removeMarkBlock?()
    }
    
    @objc private func bringIllustrationMarkViewToFront() {
        bringMarkViewToFrontBlock?()
    }
}
