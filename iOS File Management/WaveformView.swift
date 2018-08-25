
import UIKit


class WaveformView : UIScrollView {
    
    private let space = 5
    var x: Int = 0
    var averagePower: Float = 0 {
        didSet {
            update()
        }
    }
    private var layerY: Int = 0
    private let layerLineWidth: CGFloat = 1
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layerY = Int(self.bounds.size.height / 2)
    }
    
    func update() {
        let val = Int(averagePower / 2)
        
        let upLayer = CAShapeLayer()
        upLayer.frame = CGRect(x: x, y: layerY, width: 1, height: -val)
        upLayer.backgroundColor = UIColor.red.cgColor
        upLayer.lineWidth = layerLineWidth
        layer.addSublayer(upLayer)
        
        let downLayer = CAShapeLayer()
        downLayer.frame = CGRect(x: x, y: layerY, width: 1, height: val)
        downLayer.backgroundColor = UIColor.orange.cgColor
        downLayer.lineWidth = layerLineWidth
        layer.addSublayer(downLayer)
        
        x = x + space
        resize()
    }
    
    func resize() {
        if(!self.isDragging && (Int(self.contentSize.width) >= Int(self.bounds.width / 4))) {
            let _x = self.contentSize.width - (self.bounds.size.width - (self.bounds.size.width / 2))
            contentInset = UIEdgeInsetsMake(0, 0, 0, _x)
            self.scrollTo(direction: .Center, animated: false)
        }
        if(x >= Int(self.bounds.width / 2)) {
            self.contentSize = CGSize(width: x, height: Int(self.contentSize.height))
        }
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




