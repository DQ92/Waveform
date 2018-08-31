
import UIKit

class WaveformInfoView: UIView {
    
    @IBOutlet var view: UIView!
    private let lines = 13
    private let rightPadding: CGFloat = 80
    private let labelHeight: CGFloat = 16
    
    
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
    }
    
    func loadViewFromNib() -> UIView {
        let thisType = type(of: self)
        let bundle = Bundle(for: thisType)
        let nib = UINib(nibName: String(describing: thisType), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        generateLines()
    }
        
    func generateLines() {
        let height = self.frame.size.height - CGFloat(lines)
        let width = self.frame.size.width - rightPadding
        let space = height / CGFloat(lines - 1) + 1
        let middleLineY = Int(lines / 2) + 1 // TODO, obsługa dla parzystych wartości linii, np 12..
        
        for i in 0..<lines {
            let y = space * CGFloat(i)
            let line = CAShapeLayer()
            line.frame = CGRect(x: 0, y: y, width: width, height: 1)
            line.lineWidth = 1
            if(i + 1 == middleLineY) {
                line.backgroundColor = UIColor.white.cgColor
            } else {
                line.backgroundColor = UIColor.clear.cgColor
            }
            layer.addSublayer(line)
            
            addDbLabel(y, CGFloat(i), space)
        }
    }
    
    func addDbLabel(_ y: CGFloat, _ i: CGFloat, _ space: CGFloat) {
        let labelY = space * CGFloat(i) - (labelHeight / 2)
        let minDb: CGFloat = 0
        let maxDb: CGFloat = 10
        let middleDb: CGFloat = ((CGFloat(lines) / 2)) // TODO, tylko dla nieparzystych
        let spaceDb: CGFloat = ((maxDb - minDb) / middleDb) + 1
        var db: Int = 0
        var dbs: [Int] = []
        for idx in 0..<Int(middleDb) { //TODO, wbić na szytwno jak w dyktafonie?
            dbs.append(idx * Int(spaceDb))
        }
        if(i > middleDb) {
            let idx = dbs.count - Int(i) +  dbs.count
            db = dbs[idx]
        } else if(Int(i) == Int(middleDb)) {
            db = 0
        } else {
            db = dbs[Int(i)]
        }
        let f = CGRect(x: self.frame.width - rightPadding, y: labelY, width: 32, height: labelHeight)
        let label = UILabel(frame: f)
        label.text = "-\(db)"
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.italicSystemFont(ofSize: 10)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
//        self.addSubview(label)
    }
    
}
