import Foundation
import UIKit

public protocol EventDescriptor: AnyObject {
    var startDate: Date { get set }
    var endDate: Date { get set }
    var isAllDay: Bool { get }
    var text: String { get }
    var attributedText: NSAttributedString? { get }
    var lineBreakMode: NSLineBreakMode? { get }
    var font: UIFont { get }
    var color: UIColor { get }
    var textColor: UIColor { get }
    var backgroundColor: UIColor { get }
    var group: Int { get }
    var borderColor: UIColor { get set }
    var borderWidth: CGFloat { get set }
    var cornerRadius: CGFloat { get set }
    var images: [UIImage] { get set }
    var bottomRightText: String? { get }
}
