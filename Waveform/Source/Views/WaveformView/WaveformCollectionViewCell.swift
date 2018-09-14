
import UIKit

struct Sample {
    let value: CGFloat
    let color: UIColor
    let width: CGFloat
}

class WaveformCollectionViewCell: UICollectionViewCell {

    // MARK: - Private properties
    
    private var sampleDictionary = [Int: Sample]()
    
    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.backgroundColor = UIColor.clear
    }
    
    // MARK: - Subclass methods
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.sampleDictionary = [:]
    }
    
    // MARK: - Access methods
    
    func setupSample(sample: Sample, at index: Int) {
        self.sampleDictionary[index] = sample
        self.setNeedsDisplay()
    }
    
    func setupSamples(samples: [Sample]) {
        samples.enumerated().forEach { [weak self] (index, sample) in
            self?.sampleDictionary[index] = sample
        }
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let samples: [Sample] = self.sampleDictionary.sorted { $0.key < $1.key }.map { $0.value }
        
        for (index, sample) in samples.enumerated() {
            let size = CGSize(width: sample.width, height: max(sample.value, 1))
            let origin = CGPoint(x: CGFloat(index), y: (rect.height - size.height) * 0.5)
            let sampleRect = CGRect(origin: origin, size: size)
            
            context.addRect(sampleRect)
            context.setFillColor(sample.color.cgColor)
            context.fill(sampleRect)
        }
    }
}
