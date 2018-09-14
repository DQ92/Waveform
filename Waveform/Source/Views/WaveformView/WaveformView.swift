import UIKit

protocol WaveformViewDelegate: class {
    func currentTimeIntervalDidChange(_ timeInterval: TimeInterval)
    func contentOffsetDidChange(_ contentOffset: CGPoint)
    func secondWidthDidChange(_ secondWidth: CGFloat)
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
        layer.frame = CGRect(x: 0.0, y: layer.dotSize / 2, width: 1, height: self.bounds.height - 2 * layer.dotSize)
        // TODO: Refactor
        self.layer.addSublayer(layer)

        return layer
    }()

    private(set) var currentTimeInterval: TimeInterval = 0.0
    private(set) var sampleIndex: Int = 0
    
    var contentOffset: CGPoint = CGPoint.zero {
        didSet {
            self.collectionView.contentOffset = contentOffset
        }
    }
    var elementsPerSecond: Int = 0
    
    weak var delegate: WaveformViewDelegate?
    var values = [[WaveformModel]]()

    // MARK: - Private properties

    private let itemReuseIdentifier = WaveformConfiguration.collectionViewItemReuseIdentifier
    private let leadingLineAnimationDuration = WaveformConfiguration.timeInterval
    private let configurator = RecorderWaveformCollectionViewCellConfigurator()
    private var autoScrollTimer: Timer!

    private var leadingLineTimeUpdater: LeadingLineTimeUpdater!
    private var contentSize: CGSize = CGSize.zero

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
            self.elementsPerSecond = WaveformConfiguration.numberOfSamplesPerSecond(inViewWithWidth: self.collectionView.bounds.width)
        }
        self.delegate?.secondWidthDidChange(CGFloat(self.elementsPerSecond))
        self.values = values
        self.collectionView.reloadData()

        let halfOfCollectionViewWidth = self.collectionView.bounds.width / 2
        let numberOfElementsInLastSection = CGFloat(elementsPerSecond - values[values.count - 1].count)
        collectionView.contentInset = UIEdgeInsetsMake(0,
                                                       halfOfCollectionViewWidth,
                                                       0,
                                                       halfOfCollectionViewWidth - numberOfElementsInLastSection)
       
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0),
                                    at: .left,
                                    animated: true)
        leadingLine.position = CGPoint(x: collectionView.bounds.width / 2, y: leadingLine.position.y)
    }
}

extension WaveformView {
    func setValue(_ value: Float, for timeInterval: TimeInterval) {
      //  print("1 setValue")
        let section = Int(floor(self.currentTimeInterval))
        let indexOfSample = self.sampleIndex
        let offset =  CGFloat(self.sampleIndex) + 1.0
        let currentItem: WaveformModel

//        print("2 currentTimeInterval = \(currentTimeInterval)")
//        print("3 sampleIndex przed zmianą = \(indexOfSample)")

        if self.values.count <= section {
            currentItem = WaveformModel(value: CGFloat(value), recordType: .first, timeStamp: timeInterval)
            self.appendSecond(data: [currentItem]) { [weak self] _ in
                self!.contentSize = self!.collectionView.contentSize
                self?.updateLeadingLine(x: offset)
            }
        } else {
            let indexOfItem = indexOfSample - (section * self.elementsPerSecond)
            let items = self.values[section]

            if items.count <= indexOfItem {
                currentItem = WaveformModel(value: CGFloat(value), recordType: .first, timeStamp: timeInterval)
                self.values[section] = items + [currentItem]
            } else {
                let previousItem = self.values[section][indexOfItem]

                if case .override(let turn) = previousItem.recordType {
                    currentItem = WaveformModel(value: CGFloat(value),
                                                recordType: .override(turn: turn + 1),
                                                timeStamp: timeInterval)
                } else {
                    currentItem = WaveformModel(value: CGFloat(value),
                                                recordType: .override(turn: 1),
                                                timeStamp: timeInterval)
                }
                self.values[section][indexOfItem] = currentItem
            }

            self.updateSampleLayer(model: currentItem, section: section, sampleIndex: indexOfItem)
            self.updateLeadingLine(x: offset)
        }
    }

    private func appendSecond(data: [WaveformModel], completion: ((Bool) -> Void)? = nil) {
        UIView.performWithoutAnimation {
            self.values.append(contentsOf: [data, [], []])
            self.collectionView.performBatchUpdates({
                
                self.collectionView.insertSections(IndexSet([self.values.count - 3, self.values.count - 2, self.values.count - 1]))
            }, completion: completion)
        }
    }
}

// MARK: - Setup

extension WaveformView {
    private func commonInit() {
        self.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        self.elementsPerSecond = WaveformConfiguration.microphoneSamplePerSecond
        self.leadingLineTimeUpdater = LeadingLineTimeUpdater(elementsPerSecond: elementsPerSecond)
        self.leadingLineTimeUpdater.delegate = self
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

    func updateSampleLayer(model: WaveformModel, section: Int, sampleIndex: Int) {
        let indexPath = IndexPath(row: 0, section: section)
        if let cell = collectionView.cellForItem(at: indexPath) as? WaveformCollectionViewCell {
            let sample = Sample(value: model.value, color: WaveformColor.color(model: model), width: self.configurator.oneLayerWidth())

            cell.setupSample(sample: sample, at: sampleIndex)
        } else {
            Assert.checkRepresentation(true, "ERROR! lastCell is NIL!")
        }
    }

    func updateLeadingLine(x: CGFloat) {
        let scrollStartPosition = self.collectionView.bounds.width * 0.5
        let offset = abs(self.collectionView.contentOffset.x) + x
        
        if offset > scrollStartPosition {
            collectionView.setContentOffset(CGPoint(x: x - scrollStartPosition, y: 0), animated: false)
        } else {
            CATransaction.begin()
            CATransaction.setAnimationDuration(leadingLineAnimationDuration)
            self.leadingLineTimeUpdater.changeTime(withX: x)
            self.leadingLine.position.x = abs(self.collectionView.contentOffset.x) + x
            CATransaction.commit()
        }
    }

    func onPause() { // TODO: Zmienić nazwe
        let numberOfItems = self.values.map { $0.count }.reduce(0, +)

        let minimumRightInsets = self.collectionView.bounds.width * 0.5
        let currentRightInsets = self.collectionView.bounds.width - CGFloat(numberOfItems)

        let rightInsets = max(currentRightInsets, minimumRightInsets)
        let leftInsets = self.collectionView.bounds.width - rightInsets

        print("rightInsets = \(rightInsets), leftInsets = \(leftInsets)")
        
        self.collectionView.contentInset = UIEdgeInsets(top: 0.0, left: leftInsets, bottom: 0.0, right: rightInsets)

//        let halfOfCollectionViewWidth = round(width / 2)
//        let currentX = CGFloat(self.sampleIndex)
//        let numberOfElementsMissingInLastSection = CGFloat(elementsPerSecond - values[values.count - 2].count)
//        let additionalSectionWidth = CGFloat(elementsPerSecond)
//        let rightInsetShiftToEndOfWaveform =  numberOfElementsMissingInLastSection + additionalSectionWidth
//
//        if currentX < halfOfCollectionViewWidth {
//            collectionView.contentInset = UIEdgeInsetsMake(0, currentX, 0, (width - currentX - rightInsetShiftToEndOfWaveform))
//        } else {
//            collectionView.contentInset = UIEdgeInsetsMake(0, halfOfCollectionViewWidth, 0, halfOfCollectionViewWidth - rightInsetShiftToEndOfWaveform)
//        }
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

        let samples: [Sample] = self.values[indexPath.section].map { [weak self] in
            Sample(value: $0.value,
                   color: WaveformColor.color(model: $0),
                   width: self?.configurator.oneLayerWidth() ?? 0.0)
        }
        cell.setupSamples(samples: samples)
        return cell
    }
}

// MARK: - ScrollView delegate

extension WaveformView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.leadingLineTimeUpdater.changeTime(withX: max(round(scrollView.contentOffset.x + leadingLine.position.x), 0.0))
        self.contentOffset = scrollView.contentOffset
        self.delegate?.contentOffsetDidChange(scrollView.contentOffset)
    }
}

extension WaveformView: LeadingLineTimeUpdaterDelegate {
    func timeIntervalDidChange(with timeInterval: TimeInterval) {
//        print("4 timeIntervalDidChange = \(timeInterval)")
        let value = Double(self.elementsPerSecond) * timeInterval

        self.sampleIndex = Int(round(value))
//        print("5 sampleIndex po zmianie = \(value), casted = \(self.sampleIndex), round = \(Int(round(value)))")

        self.currentTimeInterval = timeInterval
        self.delegate?.currentTimeIntervalDidChange(timeInterval)
    }

    func scrollToTheEnd() {
        let point = collectionView.contentOffset
        collectionView.setContentOffset(point, animated: false)
        autoScrollTimer?.invalidate()
        autoScrollTimer = Timer.scheduledTimer(timeInterval: 0.01,
                                               target: self,
                                               selector: #selector(scrollContentOffset),
                                               userInfo: nil,
                                               repeats: true)
    }

    @objc func scrollContentOffset() {
        let difference: CGFloat = CGFloat(WaveformConfiguration.microphoneSamplePerSecond) / 100
        let finalPosition: CGFloat = self.collectionView.contentOffset.x + difference
        let point = CGPoint(x: finalPosition, y: 0.0)
        collectionView.bounds = CGRect(x: point.x,
                                       y: point.y,
                                       width: collectionView.bounds.size.width,
                                       height: collectionView.bounds.size.height)
        self.leadingLineTimeUpdater.changeTime(withX: point.x + leadingLine.position.x)
        self.delegate?.contentOffsetDidChange(point)
    }

    func stopScrolling() {
        autoScrollTimer.invalidate()
    }
}
