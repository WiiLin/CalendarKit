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
        subviews.forEach { $0.removeFromSuperview() }

        let spaceView = UIView(frame: CGRect(x: 0, y: 0, width: newStyle.leadingInset, height: 30))
        addSubview(spaceView)
      
        var currentX: CGFloat = 0
        for index in 0 ..< newStyle.group.count {
            let label = UILabel(frame: CGRect(x: currentX + newStyle.leadingInset, y: 0, width: newStyle.groupWidth(index: index), height: 30))
            label.numberOfLines = 0
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            let text = newStyle.group[index].name
            let texts = text.split(separator: "\n")
            if texts.count == 2 {
                let attribute = NSMutableAttributedString(string: text)
                let ranges = attribute.string.ranges(of: texts.last!)
                if let first = ranges.first {
                    let nsRange = NSRange(first, in: attribute.string)
                    attribute.addAttributes([.font: UIFont.systemFont(ofSize: 11, weight: .regular)], range: nsRange)
                    label.attributedText = attribute
                } else {
                    label.text = text
                }
            } else {
                label.text = text
            }
            addSubview(label)
            currentX += newStyle.groupWidth(index: index)
        }
        setNeedsDisplay()
    }
}

extension UIStackView {
    @discardableResult func removeAllArrangedSubviews() -> [UIView] {
        let removedSubviews = arrangedSubviews.reduce([]) { removedSubviews, subview -> [UIView] in
            self.removeArrangedSubview(subview)
            NSLayoutConstraint.deactivate(subview.constraints)
            subview.removeFromSuperview()
            return removedSubviews + [subview]
        }
        return removedSubviews
    }
}

extension StringProtocol {
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
              let range = self[startIndex...]
              .range(of: string, options: options)
        {
            result.append(range)
            startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
