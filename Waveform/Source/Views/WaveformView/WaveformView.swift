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
        collectionView.register(WaveformCollectionViewCell.self, forCellWithReuseIdentifier: self.collectionViewCellIdentifier)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self.coordinator
        collectionView.delegate = self.coordinator
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
    var recordingModeEnabled: Bool = false {
        didSet {
            if recordingModeEnabled {
                self.enableRecordingMode()
            } else {
                self.disableRecordingMode()
            }
        }
    }

    weak var delegate: WaveformViewDelegate?

    // MARK: - Private properties

    private let collectionViewCellIdentifier = WaveformConfiguration.collectionViewItemReuseIdentifier
    private let leadingLineAnimationDuration = WaveformConfiguration.timeInterval
    private var autoScrollTimer: Timer!
    private var leadingLineTimeUpdater: LeadingLineTimeUpdater!
    private var zoomMultiplier: Double = 1.0
    private var samplePerLayer: Int = 1

    private lazy var coordinator: WaveformCoordinator = {
        let coordinator = WaveformCoordinator(cellIdentifier: self.collectionViewCellIdentifier, endlessScrollingEnabled: false)
        coordinator.contentOffsetDidChangeBlock = { [weak self] contentOffset in
            guard let caller = self else {
                return
            }
            let currentX = max(round(contentOffset.x + caller.leadingLine.position.x), 0.0)
            caller.leadingLineTimeUpdater.changeTime(withX: currentX, and: caller.samplePerLayer)
            caller.contentOffset = contentOffset
            caller.delegate?.contentOffsetDidChange(contentOffset)
        }
        return coordinator
    }()

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
        coordinator.values = []
        collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        leadingLine.position = CGPoint(x: 0, y: leadingLine.position.y)
        collectionView.reloadData()
    }

    // MARK: - Access methods

    func load(values: [WaveformModel]) {
        self.coordinator.values = values
        self.collectionView.reloadData()
        updateLeadingLine(x: self.collectionView.bounds.size.width / 2)
        self.collectionView.contentInset = self.calculateContentInset()
    }

    private func enableRecordingMode() {
        self.coordinator.endlessScrollingEnabled = true
        self.collectionView.reloadData()
    }

    private func disableRecordingMode() {
        self.collectionView.contentInset = self.calculateContentInset()
        self.coordinator.endlessScrollingEnabled = false
        self.collectionView.reloadData()
    }

    private func calculateContentInset() -> UIEdgeInsets {
        let contentWidth = CGFloat(self.coordinator.values.count) * self.coordinator.configurator.sampleLayerWidth
        let minimumRightInsets = self.collectionView.bounds.width * 0.5
        let currentRightInsets = self.collectionView.bounds.width - contentWidth
        let rightInsets = max(currentRightInsets, minimumRightInsets)
        let leftInsets = self.collectionView.bounds.width - rightInsets
        return UIEdgeInsets(top: 0.0, left: leftInsets, bottom: 0.0, right: rightInsets)
    }
}

extension WaveformView {
    func setCurrentValue(_ value: Float, for timeInterval: TimeInterval, mode: RecordingMode) {
        let currentRow = self.sampleIndex / self.coordinator.configurator.layersPerSecond
        let offset = CGFloat(self.sampleIndex) + 1.0 * CGFloat(zoomMultiplier)
        let indexPath = IndexPath(row: currentRow, section: 0)
        let model = WaveformModel(value: CGFloat(value), mode: mode, timeStamp: timeInterval)
        if self.coordinator.shouldLoadMoreItems(forIndexPath: indexPath) {
            self.coordinator.values.append(model)
            self.coordinator.appendItems(atSection: indexPath.section,
                                         collectionView: self.collectionView) { [weak self] in
                self?.updateLeadingLine(x: offset)
            }
        } else {
            if self.sampleIndex == self.coordinator.values.count {
                self.coordinator.values.append(model)
            } else {
                self.coordinator.values[self.sampleIndex] = model
            }
//            self.collectionView.reloadItems(at: [indexPath])
            self.collectionView.reloadData()
            self.updateLeadingLine(x: offset)
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

    func updateLeadingLine(x: CGFloat) {
        let scrollStartPosition = self.collectionView.bounds.width * 0.5
        let offset = abs(self.collectionView.contentOffset.x) + x
        if offset > scrollStartPosition {
            collectionView.setContentOffset(CGPoint(x: x - scrollStartPosition, y: 0), animated: false)
        } else {
            CATransaction.begin()
            CATransaction.setAnimationDuration(leadingLineAnimationDuration)
            self.leadingLineTimeUpdater.changeTime(withX: x, and: samplePerLayer)
            self.leadingLine.position.x = abs(self.collectionView.contentOffset.x) + x
            CATransaction.commit()
        }
    }
}

// MARK: - Player

extension WaveformView {
    func scrollToTheEndOfFile() {
        let point = collectionView.contentOffset
        collectionView.setContentOffset(point, animated: false)
        autoScrollTimer?.invalidate()
        autoScrollTimer = Timer.scheduledTimer(timeInterval: 0.01,
                                               target: self,
                                               selector: #selector(changeOffsetTimerRepetition),
                                               userInfo: nil,
                                               repeats: true)
    }

    @objc func changeOffsetTimerRepetition() {
        let numberOfLayersPerSecond = CGFloat(WaveformConfiguration.microphoneSamplePerSecond)
        let difference: CGFloat = CGFloat(numberOfLayersPerSecond) / CGFloat((100 * samplePerLayer))
        let finalPosition: CGFloat = collectionView.contentOffset.x + difference
        let point = CGPoint(x: finalPosition, y: 0.0)
        collectionView.bounds = CGRect(x: point.x,
                                       y: point.y,
                                       width: collectionView.bounds.size.width,
                                       height: collectionView.bounds.size.height)
        leadingLineTimeUpdater.changeTime(withX: point.x + leadingLine.position.x, and: samplePerLayer)
        delegate?.contentOffsetDidChange(point)
    }

    func stopScrolling() {
        autoScrollTimer.invalidate()
    }
}

// MARK: - Leading line delegate

extension WaveformView: LeadingLineTimeUpdaterDelegate {
    func timeIntervalDidChange(with timeInterval: TimeInterval) {
        let value = Double(self.elementsPerSecond) * timeInterval
        self.sampleIndex = Int(round(value))
        self.currentTimeInterval = timeInterval
        self.delegate?.currentTimeIntervalDidChange(timeInterval)
    }
}

// MARK: - Zoom

extension WaveformView {
    func zoomDidChange(with zoom: Zoom) {
        self.zoomMultiplier = zoom.multiplier
        self.samplePerLayer = zoom.samplesPerLayer
        self.coordinator.samplePerLayer = zoom.samplesPerLayer
        self.collectionView.reloadData()
    }
}