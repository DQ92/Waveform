
import UIKit

class WaveformView: UIView {

    @IBOutlet private var view: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    private let leadingLineAnimationDuration = timeInterval //TODO wywalić zmienną globalną
    private let leadingLine = LeadingLineLayer()
    private var elementsPerSecond: Int = 0
    private var width: CGFloat {
        return UIScreen.main.bounds.size.width // TODO, nie działa dla self.view  UIScreen.main.bounds.size.width //
    }
    
    var values = [[CGFloat]]()
    var sampleIndex: Int = 0 {
        didSet {
            let sec = (values.count - 1) * elementsPerSecond
            let temp = values[values.count - 1].count + sec
            if temp == sampleIndex {
                
            } else {
                print("BŁĄD! temo: \(temp) | sampleIndex: \(sampleIndex)")
            }
        }
    }
    var isRecording: Bool = false
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        xibSetup()
    }
    
    private func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        addSubview(view)
        setup()
    }
    
    private func loadViewFromNib() -> UIView {
        let thisType = type(of: self)
        let bundle = Bundle(for: thisType)
        let nib = UINib(nibName: String(describing: thisType), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
}


extension WaveformView {
    
    private func setup() {
        self.view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        collectionView.register(WaveformCollectionViewCell.self, forCellWithReuseIdentifier: "collectionViewCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: partOfView, height: 100) //TODO
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets.zero
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        collectionView.scrollTo(direction: .Left)

        leadingLine.frame = CGRect(x: 0, y: leadingLine.dotSize / 2, width: 1, height: 110) //TODO
        self.layer.addSublayer(leadingLine)
        elementsPerSecond = Int(width / 6)
    }
    
    func update(value: CGFloat, sampleIndex: Int) {
        let lastCellIdx = IndexPath(row: 0, section: collectionView.numberOfSections - 1)
        if let lastCell = collectionView.cellForItem(at: lastCellIdx) {
            let x = CGFloat(sampleIndex % elementsPerSecond)
            updateCell(lastCell, x, value)
        }
    }
    
    func newSecond(_ second: Int, _ x: CGFloat) {
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates({
                self.collectionView.insertSections(IndexSet([second]))
            }) { (done) in
                self.setOffset()
            }
        }
    }
    
    private func updateCell(_ cell: UICollectionViewCell, _ x: CGFloat, _ value: CGFloat) {
        updateLeadingLine()
        let layerY = CGFloat(cell.bounds.size.height / 2)
        let upLayer = CAShapeLayer()
        upLayer.frame = CGRect(x: x, y: layerY, width: 1, height: -value)
        upLayer.backgroundColor = UIColor.red.cgColor
        upLayer.lineWidth = 1
        cell.contentView.layer.addSublayer(upLayer)
        let downLayer = CAShapeLayer()
        downLayer.frame = CGRect(x: x, y: layerY, width: 1, height: value)
        downLayer.backgroundColor = UIColor.orange.cgColor
        downLayer.lineWidth = 1
        cell.contentView.layer.addSublayer(downLayer)
        setOffset()
    }
    
    private func setOffset() {
        let x = CGFloat(sampleIndex)
        if(x > (width / 2) && isRecording) {
            collectionView.setContentOffset(CGPoint(x: x - (self.width / 2), y: 0), animated: false)
        }
    }
    
    private func updateLeadingLine() {
        let y: CGFloat = leadingLine.position.y
        let x = leadingLine.position.x
        if(x < (self.width / 2)) {
            CATransaction.begin()
            CATransaction.setAnimationDuration(leadingLineAnimationDuration)
            leadingLine.position = CGPoint(x: x + 1, y: y)
            CATransaction.commit()
        }
    }
    
    func onPause(sampleIndex: CGFloat) {
        let halfOfCollectionViewWidth = collectionView.bounds.width / 2
        let currentX = sampleIndex
        
        if currentX < halfOfCollectionViewWidth {
            collectionView.contentInset = UIEdgeInsetsMake(0, currentX, 0, halfOfCollectionViewWidth + currentX)
            collectionView.contentSize = CGSize(width: collectionView.bounds.width + currentX, height: collectionView.bounds.height)
        } else {
            let test = CGFloat(elementsPerSecond - values[values.count - 1].count)
            collectionView.contentInset = UIEdgeInsetsMake(0, halfOfCollectionViewWidth, 0, halfOfCollectionViewWidth - test)
        }
    }
}


// MARK - delegate & datasource
extension WaveformView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return values.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: elementsPerSecond, height: Int(collectionView.bounds.size.height))
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! WaveformCollectionViewCell
        
        let second = indexPath.section
        let valuesInSecond: [CGFloat] = values[second]
        
        for x in 0..<valuesInSecond.count {
            updateCell(cell, CGFloat(x), valuesInSecond[x])
        }
        return cell
    }
}



//TODO przenieść
class WaveformCollectionViewCell: UICollectionViewCell {
    
    var baseLayer = CAShapeLayer()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        contentView.layer.sublayers = []
        contentView.backgroundColor = nil
    }
}

