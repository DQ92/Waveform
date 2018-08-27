
import UIKit


class WaveformView : UIScrollView {
    
    var x: CGFloat = 0
    var averagePower: Float = 0 {
        didSet {
            update()
        }
    }
    private var layerY: CGFloat = 0
    private let layerLineWidth: CGFloat = 1
    let padding: CGFloat = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        delegate = self
        layerY = CGFloat(self.bounds.size.height / 2)
        
    }
    
    func update() {
        let val: CGFloat = CGFloat(averagePower)
        
        let upLayer = CAShapeLayer()
        upLayer.frame = CGRect(x: x, y: layerY, width: CGFloat(layerLineWidth), height: -val)
        upLayer.backgroundColor = UIColor.red.cgColor
        upLayer.lineWidth = layerLineWidth
        layer.addSublayer(upLayer)
        
        let downLayer = CAShapeLayer()
        
        downLayer.frame = CGRect(x: x, y: layerY, width: CGFloat(layerLineWidth), height: val)
        downLayer.backgroundColor = UIColor.orange.cgColor
        downLayer.lineWidth = layerLineWidth
        layer.addSublayer(downLayer)
    
        resize()
        x = x + 1
    }
    
    func onPause() {
        isUserInteractionEnabled = true
        let x = (UIScreen.main.bounds.width - padding) / 2
        
        UIView.animate(withDuration: 2) {
            self.contentInset = UIEdgeInsetsMake(0, x + (self.padding / 2), 0, x - (self.padding / 2))
        }
    }
    
    func resize() {
        if(!self.isDragging) {
            self.scrollTo(direction: .Right, animated: false)
        }
        self.contentSize = CGSize(width: x, height: CGFloat(self.contentSize.height))
    }
}

extension WaveformView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
    }
}

enum ScrollDirection {
    case Top
    case Right
    case Bottom
    case Left
    case Center
    
    func contentOffsetWith(scrollView: UIScrollView) -> CGPoint {
        var contentOffset = CGPoint.zero
        switch self {
        case .Top:
            contentOffset = CGPoint(x: 0, y: -scrollView.contentInset.top)
        case .Right:
            contentOffset = CGPoint(x: scrollView.contentSize.width - scrollView.bounds.size.width, y: 0)
        case .Bottom:
            contentOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height)
        case .Left:
            contentOffset = CGPoint(x: -scrollView.contentInset.left, y: 0)
        case .Center:
            let x = scrollView.contentSize.width - (scrollView.bounds.size.width - (scrollView.bounds.size.width / 2))
            contentOffset = CGPoint(x: x, y: 0)
        }
        return contentOffset
    }
}

extension UIScrollView {
    func scrollTo(direction: ScrollDirection, animated: Bool = true) {
        self.setContentOffset(direction.contentOffsetWith(scrollView: self), animated: animated)
    }
}




