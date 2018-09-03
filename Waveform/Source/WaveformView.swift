import UIKit



class WaveformModel {
    var value: CGFloat = 0.0
    var part: Int = 0
    
    init(value: CGFloat, part: Int) {
        self.value = value
        self.part = part
    }
}

class WaveformColor {
    
    static func colors(model: WaveformModel) -> (UIColor, UIColor)  {
        let part: CGFloat = CGFloat(model.part)
        let rand: CGFloat = part * 25
        let upColor = UIColor(red: rand/255 , green: 0.3 + rand, blue: 0.5, alpha: 1)
        let downColor = UIColor(red: rand/255 , green: 0.3, blue: 0.5 + rand, alpha: 1)
        return (upColor, downColor)
    }
}

protocol WaveformViewDelegate: class {
    func didScroll(_ x: CGFloat, _ leadingLineX: CGFloat)
}


class WaveformView: UIView {

    // MARK: - IBOutlets

    @IBOutlet private var view: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet weak var timeLabel: UILabel!

    // MARK: - Private properties

    private let itemReuseIdentifier = "collectionViewCell"
    private let leadingLineAnimationDuration = timeInterval //TODO wywalić zmienną globalną
    private let leadingLine = LeadingLineLayer()
    private var elementsPerSecond: Int = 0
    private var width: CGFloat {
        return UIScreen.main.bounds.size.width // TODO, nie działa dla self.view  UIScreen.main.bounds.size.width //
    }

    weak var delegate: WaveformViewDelegate?
    var values = [[WaveformModel]]()
    var sampleIndex: Int = 0
        
    var isRecording: Bool = false

    private var leadingLineTimeUpdater: LeadingLineTime!

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        xibSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        xibSetup()
    }

    // MARK: - Nib loading

    private func loadViewFromNib() -> UIView {
        let thisType = type(of: self)
        let bundle = Bundle(for: thisType)
        let nib = UINib(nibName: String(describing: thisType), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
}

// MARK: - Setup

extension WaveformView {
    private func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        addSubview(view)
        setup()
    }

    private func setup() {
        self.view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)

        setupCollectionView()

        leadingLine.frame = CGRect(x: 0, y: leadingLine.dotSize / 2, width: 1, height: 140) //TODO
        self.layer.addSublayer(leadingLine)
        elementsPerSecond = Int(width / 6)
        leadingLineTimeUpdater = LeadingLineTime(timeLabel: timeLabel, elementsPerSecond: elementsPerSecond)
    }

    private func setupCollectionView() {
        collectionView.register(WaveformCollectionViewCell.self, forCellWithReuseIdentifier: self.itemReuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        setupCollectionViewLayout()
    }

    private func setupCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: partOfView, height: 130) //TODO
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets.zero
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        collectionView.scrollTo(direction: .left)
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
            print("ERROR! lastCell is NIL!")
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
        updateLeadingLine()
        cell.setup(model: model, sampleIndex: x)
        setOffset()
    }

    private func setOffset() {
        let x = CGFloat(sampleIndex)
        if (x > (width / 2) && isRecording) {
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
            leadingLine.position = point
            leadingLineTimeUpdater.changeTime(withXPosition: point.x)
            CATransaction.commit()
        }
    }

    func onPause(sampleIndex: CGFloat) {
        let halfOfCollectionViewWidth = width / 2
        let currentX = sampleIndex
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
        cell.numberOfLayers = elementsPerSecond
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
        var x = leadingLine.position.x
        if x < (width / 2) {
            print("LEADING: x \(x)")
        } else {
            x = scrollView.contentOffset.x + leadingLine.position.x
//            print("SCROLL: x \(x)")
            delegate?.didScroll(x, leadingLine.position.x)
        }

        if( scrollView.contentOffset.x < -scrollView.contentInset.left ) || ( scrollView.contentOffset.x > scrollView
                .contentSize.width - scrollView.frame.size.width + scrollView.contentInset.right ) {
            return
        }
        leadingLineTimeUpdater.changeTime(withXPosition: scrollView.contentOffset.x + leadingLine.position.x)
    }
}


