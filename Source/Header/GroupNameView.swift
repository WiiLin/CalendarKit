//
//  GroupNameView.swift
//  CalendarKit
//
//  Created by Wii Lin on 2021/3/26.
//

import UIKit

class GroupNameView: UIView {
    var style = TimelineStyle()

    /// 固定欄位與下方時段內容之間的分隔線，避免捲動時內容看起來疊在一起
    private lazy var bottomSeparator: UIView = {
        let separator = UIView()
        separator.backgroundColor = style.separatorColor
        addSubview(separator)
        return separator
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        let lineHeight = 1 / UIScreen.main.scale
        bottomSeparator.frame = CGRect(x: 0, y: bounds.height - lineHeight, width: bounds.width, height: lineHeight)
        bringSubviewToFront(bottomSeparator)
    }

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
        bottomSeparator.backgroundColor = newStyle.separatorColor
        addSubview(bottomSeparator)

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
            label.attributedText = text
           
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
