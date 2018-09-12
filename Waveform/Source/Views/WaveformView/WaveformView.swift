import UIKit

protocol WaveformViewDelegate: class {
    func currentTimeIntervalDidChange(with timeInterval: TimeInterval)
}

class WaveformView: UIView {

    // MARK: - Views

    private lazy var collectionView: UICollectionView = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumInteritemSpacing = 0.0
        collectionViewLayout.minimumLineSpacing = 0.0
        collectionViewLayout.sectionInset = .zero

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(WaveformCollectionViewCell.self, forCellWithReuseIdentifier: self.itemReuseIdentifier)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        self.addSubview(collectionView)

        return collectionView
    }()

    private lazy var leadingLine: LeadingLineLayer = {
        let layer = LeadingLineLayer()
        layer.frame = CGRect(x: 0.0, y: layer.dotSize / 2, width: 1, height: self.bounds.height)
        self.layer.addSublayer(layer)

        return layer
    }()
    
    private(set) var currentTimeInterval: TimeInterval = 0.0
    private(set) var sampleIndex: Int = 0

    // MARK: - Private properties

    private let itemReuseIdentifier = WaveformConfiguration.collectionViewItemReuseIdentifier
    private let leadingLineAnimationDuration = WaveformConfiguration.timeInterval
    private var width: CGFloat {
        return UIScreen.main.bounds.size.width // TODO, powinno zwracać szerokość collectionView
    }

    var values = [[WaveformModel]]()
    
    var elementsPerSecond: Int = 0
    weak var delegate: WaveformViewDelegate?

    private var leadingLineTimeUpdater: LeadingLineTimeUpdater!

    var scrollDidChangeBlock: ((CGPoint) -> Void)? // TODO: do usunięcia po zmianach Michała dotyczących usunięcia currentIndex z VC
    
    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInit()
        self.setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInit()
        self.setupConstraints()
    }

    // MARK: - Access methods
    
    func load(values: [[WaveformModel]]) {
        if let numberOfElements = values.first?.count {
            self.elementsPerSecond = numberOfElements
        } else {
            self.elementsPerSecond = WaveformConfiguration.numberOfSamplesPerSecond(inViewWithWidth: width)
        }
        self.values = values
        self.collectionView.reloadData()

        let halfOfCollectionViewWidth = width / 2
        let numberOfElementsInLastSection = CGFloat(elementsPerSecond - values[values.count - 1].count)
        collectionView.contentInset = UIEdgeInsetsMake(0, halfOfCollectionViewWidth, 0, halfOfCollectionViewWidth - numberOfElementsInLastSection)
        leadingLineTimeUpdater.changeTime(withX: 0.0)
    }
}

extension WaveformView {
    func setValue(_ value: Float, for timeInterval: TimeInterval) {
        let indexOfCell = Int(floor(self.currentTimeInterval))
        let indexOfSample = self.sampleIndex
        let currentItem: WaveformModel
        
        if self.values.count <= indexOfCell {
            currentItem = WaveformModel(value: CGFloat(value), recordType: .first, timeStamp: timeInterval)
            self.appendSecond(data: [currentItem])
        } else {
            let indexOfItem = indexOfSample - (indexOfCell * self.elementsPerSecond)
            let items = self.values[indexOfCell]

            if items.count <= indexOfItem {
                currentItem = WaveformModel(value: CGFloat(value), recordType: .first, timeStamp: timeInterval)
                self.values[indexOfCell] = items + [currentItem]
            } else {
                let previousItem = self.values[indexOfCell][indexOfItem]
                
                if case .override(let turn) = previousItem.recordType {
                    currentItem = WaveformModel(value: CGFloat(value),
                                                recordType: .override(turn: turn + 1),
                                                timeStamp: timeInterval)
                } else {
                    currentItem = WaveformModel(value: CGFloat(value),
                                                recordType: .override(turn: 1),
                                                timeStamp: timeInterval)
                }
                self.values[indexOfCell][indexOfItem] = currentItem
            }
        }
        self.update(model: currentItem, sampleIndex: indexOfSample)
        self.setOffset(CGFloat(indexOfSample))
        
        print("currentTimeInterval = \(currentTimeInterval)")
        print("sampleIndex = \(CGFloat(indexOfSample + 1))")
    }
    
    private func appendSecond(data: [WaveformModel], completion: ((Bool) -> Void)? = nil) {
        UIView.performWithoutAnimation {
            self.values.append(data)
            self.collectionView.performBatchUpdates({
                self.collectionView.insertSections(IndexSet([self.values.count - 1]))
            }, completion: completion)
        }
    }
}

// MARK: - Setup

extension WaveformView {
    private func commonInit() {
        self.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        elementsPerSecond = WaveformConfiguration.microphoneSamplePerSecond
        leadingLineTimeUpdater = LeadingLineTimeUpdater(elementsPerSecond: elementsPerSecond)
        leadingLineTimeUpdater.delegate = self
    }
    
    private func setupConstraints() {
        self.setupConstraint(attribute: .top, toItem: self.collectionView, attribute: .top, constant: -12.0)
        self.setupConstraint(attribute: .bottom, toItem: self.collectionView, attribute: .bottom, constant: 12.0)
        self.setupConstraint(attribute: .leading, toItem: self.collectionView, attribute: .leading)
        self.setupConstraint(attribute: .trailing, toItem: self.collectionView, attribute: .trailing)
    }
}

// MARK: - Waveform drawing

extension WaveformView {
    func refresh() {
        collectionView.reloadData()
    }

    func update(model: WaveformModel, sampleIndex: Int) {
        let lastCellIdx = IndexPath(row: 0, section: sampleIndex/elementsPerSecond)
        if let lastCell = collectionView.cellForItem(at: lastCellIdx) as? WaveformCollectionViewCell {
            let x = CGFloat(sampleIndex % elementsPerSecond)
            updateCell(lastCell, x, model)
        } else {
            Assert.checkRepresentation(true, "ERROR! lastCell is NIL!")
        }
    }

    func newSecond(_ second: Int, _ x: CGFloat) {
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates({
                let second = self.collectionView.numberOfSections
                self.collectionView.insertSections(IndexSet([second]))
            }) { (done) in
                self.setOffset(x)
            }
        }
    }

    private func updateCell(_ cell: WaveformCollectionViewCell, _ x: CGFloat, _ model: WaveformModel) {
        updateLeadingLine()
        cell.setup(model: model, sampleIndex: x)
    }

    func setOffset(_ x: CGFloat) {
        if x > (width / 2) {
            if collectionView.contentOffset.x != x {
                collectionView.setContentOffset(CGPoint(x: x - (self.width / 2), y: 0), animated: false)
            }
        }
    }

    private func updateLeadingLine() {
        let y: CGFloat = leadingLine.position.y
        let x = leadingLine.position.x
        if(x < (self.width / 2)) {
            CATransaction.begin()
            CATransaction.setAnimationDuration(leadingLineAnimationDuration)
            let point = CGPoint(x: x + 1, y: y)
            leadingLinePositionChanged(x: point.x) // TODO: - Refactor to call this from one place
            leadingLine.position = point
            CATransaction.commit()
        }
    }

    private func leadingLinePositionChanged(x value: CGFloat) {
        leadingLineTimeUpdater.changeTime(withX: value)
    }

    func onPause() { // TODO: Zmienić nazwe
        let halfOfCollectionViewWidth = width / 2
        let currentX: CGFloat = 0.0
        let numberOfElementsInLastSection = CGFloat(elementsPerSecond - values[values.count - 1].count)

        if currentX < halfOfCollectionViewWidth {
            collectionView.contentSize = CGSize(width: width + currentX, height: collectionView.bounds.height)
            collectionView.contentInset = UIEdgeInsetsMake(0, currentX, 0, (width - currentX - numberOfElementsInLastSection))
        } else {
            collectionView.contentInset = UIEdgeInsetsMake(0, halfOfCollectionViewWidth, 0, halfOfCollectionViewWidth - numberOfElementsInLastSection)
        }
    }
}

// MARK: - Delegate & DataSource

extension WaveformView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return values.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: elementsPerSecond, height: Int(collectionView.bounds.size.height))
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.itemReuseIdentifier, for: indexPath) as! WaveformCollectionViewCell
        cell.configurator = RecorderWaveformCollectionViewCellConfigurator()

        let second = indexPath.section
        let valuesInSecond: [WaveformModel] = values[second]

        for x in 0..<valuesInSecond.count {
            updateCell(cell, CGFloat(x), valuesInSecond[x])
        }
        return cell
    }
}

// MARK: - ScrollView delegate

extension WaveformView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.leadingLinePositionChanged(x: max(scrollView.contentOffset.x + leadingLine.position.x, 0.0))
        self.scrollDidChangeBlock?(scrollView.contentOffset)
    }
}

extension WaveformView: LeadingLineTimeUpdaterDelegate {
    func timeIntervalDidChange(with timeInterval: TimeInterval) {
        
        
//        let difference = timeInterval - self.currentTimeInterval
//
//        if abs(difference) < 1.0 {
//            if difference < 0 {
//                self.sampleIndex -= 1
//            } else {
//                self.sampleIndex += 1
//            }
//        } else {
//
//        }
        self.sampleIndex = Int(floor(Double(self.elementsPerSecond) * timeInterval))
        
        self.currentTimeInterval = timeInterval
        self.delegate?.currentTimeIntervalDidChange(with: timeInterval)
        
//        print("difference = \(difference)")
//        print("currentTimeInterval = \(currentTimeInterval)")
//        print("sampleIndex = \(sampleIndex)")
    }
}
