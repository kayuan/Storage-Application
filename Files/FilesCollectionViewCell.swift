import UIKit
class FilesCollectionViewCell: UICollectionViewCell {
    let colorView: UIView = ({
        let colorView = UIView(frame: .zero)
        colorView.translatesAutoresizingMaskIntoConstraints = false
        return colorView
    })()
    let symbolLabel: UILabel = ({
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.lineBreakMode = .byClipping
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        return label
    })()
    let valueLabel: UILabel = ({
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.lineBreakMode = .byClipping
        label.font = UIFont.systemFont(ofSize: 11)
        return label
    })()
    override var tintColor: UIColor! {
        get {
            return colorView.backgroundColor
        }
        set {
            colorView.backgroundColor = newValue
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        contentView.addSubview(colorView)
        colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        colorView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -1.0).isActive = true
        colorView.heightAnchor.constraint(equalTo: contentView.heightAnchor, constant: -1.0).isActive = true
        contentView.addSubview(symbolLabel)
        symbolLabel.leftAnchor.constraint(equalTo: colorView.leftAnchor, constant: 3.0).isActive = true
        symbolLabel.topAnchor.constraint(equalTo: colorView.topAnchor, constant: 3.0).isActive = true
        contentView.addSubview(valueLabel)
        valueLabel.leftAnchor.constraint(equalTo: symbolLabel.leftAnchor).isActive = true
        valueLabel.topAnchor.constraint(equalTo: symbolLabel.bottomAnchor).isActive = true
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func prepareForReuse() {
        symbolLabel.text = nil
    }
    override var frame: CGRect {
        didSet {
            self.setNeedsLayout()
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
    }
}
