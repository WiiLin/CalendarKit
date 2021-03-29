//
//  GroupNameView.swift
//  CalendarKit
//
//  Created by Wii Lin on 2021/3/26.
//

import UIKit

class GroupNameView: UIStackView {
    
    var style = TimelineStyle()
    override func draw(_ rect: CGRect) {
        let groupWidth = style.groupWidth()
        let hourLineHeight = 1 / UIScreen.main.scale
        for index in 1...style.groupCount {
            let context = UIGraphicsGetCurrentContext()
            context!.interpolationQuality = .none
            context?.saveGState()
            context?.setStrokeColor(style.separatorColor.cgColor)
            context?.setLineWidth(hourLineHeight)
            
            context?.beginPath()
            let x = style.leadingInset + CGFloat(index) * groupWidth
            context?.move(to: CGPoint(x: x , y: 0))
            context?.addLine(to: CGPoint(x: x, y: bounds.maxY ))
            context?.strokePath()
            context?.restoreGState()
        }
    }
    
    
    func updateStyle(_ newStyle: TimelineStyle) {
        style = newStyle
        removeAllArrangedSubviews()
        let groupWidth = newStyle.groupWidth()
        let spaceView = UIView.init(frame: CGRect(x: 0, y: 0, width: newStyle.leadingInset, height: self.bounds.height))
        
        spaceView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(spaceView)
        spaceView.widthAnchor.constraint(equalToConstant: newStyle.leadingInset).isActive = true
      
       
        for groupName in newStyle.group {
            let label: UILabel = UILabel.init(frame: CGRect(x: 0, y: 0, width: groupWidth, height: self.bounds.height))
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            label.text = groupName
            label.translatesAutoresizingMaskIntoConstraints = false
            addArrangedSubview(label)
            label.widthAnchor.constraint(equalToConstant: groupWidth).isActive = true
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
