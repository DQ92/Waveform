
import UIKit

class LeadingLineLayer: CALayer {

    private let width: CGFloat = 1
    var dotSize: CGFloat = 7
    let color: UIColor = .blue
    
    private func setup() {
        addSublayer(prepareDot(self.frame.size.height))
        addSublayer(prepareDot(0))
        backgroundColor = color.cgColor
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        setup()
    }

    func prepareDot(_ y: CGFloat) -> CAShapeLayer {
        let dot = CAShapeLayer()
        let x: CGFloat = -(dotSize / 2)
        dot.frame = CGRect(x: x, y: y, width: dotSize, height: dotSize)
        dot.backgroundColor = color.cgColor
        dot.cornerRadius = dotSize / 2
        dot.fillColor = color.cgColor
        return dot
    }
}
