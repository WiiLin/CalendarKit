//
//  GroupNameView.swift
//  CalendarKit
//
//  Created by Wii Lin on 2021/3/26.
//

import UIKit

class GroupNameView: UIView {
    
    var style = TimelineStyle()
    override func draw(_ rect: CGRect) {
//        let groupWidth = style.groupWidth()
//        let hourLineHeight = 1 / UIScreen.main.scale
//        for index in 0...style.groupCount {
//            let context = UIGraphicsGetCurrentContext()
//            context!.interpolationQuality = .none
//            context?.saveGState()
//            context?.setStrokeColor(UIColor.red.cgColor)
//            context?.setLineWidth(hourLineHeight)
//
//            context?.beginPath()
//            let x = style.leadingInset + CGFloat(index) * groupWidth
//            print("\(x)")
//            context?.move(to: CGPoint(x: x , y: 0))
//            context?.addLine(to: CGPoint(x: x, y: 30 ))
//            context?.strokePath()
//            context?.restoreGState()
//        }
    }
    
    
    func updateStyle(_ newStyle: TimelineStyle) {
        style = newStyle
        self.subviews.forEach { $0.removeFromSuperview() }
        let groupWidth = newStyle.groupWidth()
        let spaceView = UIView.init(frame: CGRect(x: 0, y: 0, width: newStyle.leadingInset, height: 30))
        addSubview(spaceView)
      
        for index in 0..<newStyle.group.count {
            let label: UILabel = UILabel.init(frame: CGRect(x: CGFloat(index) * groupWidth + newStyle.leadingInset, y: 0, width: groupWidth, height: 30))
            label.numberOfLines = 0
            label.minimumScaleFactor = 0.5
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            label.text = newStyle.group[index]
            addSubview(label)
        }
        setNeedsDisplay()
    }

}

extension UIStackView {
    @discardableResult func removeAllArrangedSubviews() -> [UIView] {
        let removedSubviews = arrangedSubviews.reduce([]) { (removedSubviews, subview) -> [UIView] in
            self.removeArrangedSubview(subview)
            NSLayoutConstraint.deactivate(subview.constraints)
            subview.removeFromSuperview()
            return removedSubviews + [subview]
        }
        return removedSubviews
    }
}
