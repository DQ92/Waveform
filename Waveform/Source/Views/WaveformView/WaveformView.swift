import UIKit

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
        layer.frame = CGRect(x: 0.0, y: layer.dotSize / 2, width: 1, height: self.bounds.height - 2 * layer.dotSize)
        // TODO: Refactor
        self.layer.addSublayer(layer)

        return layer
    }()

    // MARK: - Private properties

    private let itemReuseIdentifier = WaveformConfiguration.collectionViewItemReuseIdentifier
    private let leadingLineAnimationDuration = WaveformConfiguration.timeInterval
    private var width: CGFloat {
        return UIScreen.main.bounds.size.width // TODO, powinno zwracać szerokość collectionView
    }

    weak var delegate: WaveformViewDelegate?
    var values = [[WaveformModel]]()
    var sampleIndex: Int = 0
    var isRecording: Bool = false
    var elementsPerSecond: Int = 0

    private var leadingLineTimeUpdater: LeadingLineTimeUpdater!
    weak var leadingLineTimeUpdaterDelegate: LeadingLineTimeUpdaterDelegate? {
        didSet {
            self.leadingLineTimeUpdater.delegate = leadingLineTimeUpdaterDelegate
        }
    }

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

    func reload() {
        values = []
        collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        leadingLine.position = CGPoint(x: 0, y: leadingLine.position.y)
        collectionView.reloadData()
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
        collectionView.contentInset = UIEdgeInsetsMake(0,
                                                       halfOfCollectionViewWidth,
                                                       0,
                                                       halfOfCollectionViewWidth - numberOfElementsInLastSection)
       
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0),
                                    at: .left,
                                    animated: true)
    }
}

// MARK: - Setup

extension WaveformView {
    private func commonInit() {
        self.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        elementsPerSecond = WaveformConfiguration.microphoneSamplePerSecond
        leadingLineTimeUpdater = LeadingLineTimeUpdater(elementsPerSecond: elementsPerSecond)
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
            updateLeadingLine()
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
                self.setOffset()
            }
        }
    }

    private func updateCell(_ cell: WaveformCollectionViewCell, _ x: CGFloat, _ model: WaveformModel) {
        cell.setup(model: model, sampleIndex: x)
    }

    func setOffset() {
        let x = CGFloat(sampleIndex)
        if x > (width / 2) {
            collectionView.setContentOffset(CGPoint(x: x - (self.width / 2), y: 0), animated: false)
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

    func onPause(sampleIndex: CGFloat) { // TODO: Zmienić nazwe
        let halfOfCollectionViewWidth = width / 2
        let currentX = sampleIndex
        let numberOfElementsMissingInLastSection = CGFloat(elementsPerSecond - values[values.count - 2].count)
        let additionalSectionWidth = CGFloat(elementsPerSecond)
        let rightInsetShiftToEndOfWaveform =  numberOfElementsMissingInLastSection + additionalSectionWidth

        if currentX < halfOfCollectionViewWidth {
            collectionView.contentSize = CGSize(width: width + currentX, height: collectionView.bounds.height)
            collectionView.contentInset = UIEdgeInsetsMake(0, currentX, 0, (width - currentX - rightInsetShiftToEndOfWaveform))
        } else {
            collectionView.contentInset = UIEdgeInsetsMake(0, halfOfCollectionViewWidth, 0, halfOfCollectionViewWidth - rightInsetShiftToEndOfWaveform)
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
            updateLeadingLine()
            updateCell(cell, CGFloat(x), valuesInSecond[x])
        }
        return cell
    }
}

// MARK: - ScrollView delegate

extension WaveformView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var x = leadingLine.position.x
        if x < width / 2 {
            print("LEADING: x \(x)")
        } else {
            x = scrollView.contentOffset.x
            delegate?.didScroll(x)
        }

        self.scrollDidChangeBlock?(scrollView.contentOffset)

        if scrollView.contentOffset.x < -leadingLine.position.x {
            leadingLineTimeUpdater.changeTime(withX: 0.0)
            return
        }

        leadingLinePositionChanged(x: scrollView.contentOffset.x + leadingLine.position.x)
    }
}
