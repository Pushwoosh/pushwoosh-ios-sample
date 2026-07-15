//
//  PromoCaptionedCell.swift
//  PushwooshSampleApp
//
//  Custom inbox cell registered in the alternate "Open Custom Inbox" entry.
//  Subclasses PushwooshInboxCell (the SDK's open base class) and builds a
//  fully bespoke layout: teal/cyan gradient surface, gold PROMO badge, a
//  circular hero image centred on the card, and centred text + frosted CTA
//  buttons. Demonstrates the most flexible customisation path — host owns
//  the entire layout while the SDK still drives data flow, lifecycle, taps,
//  pinning, image loading, and inline-button parsing.
//

import UIKit
import PushwooshFramework
import PushwooshInboxKit

@objc(PromoCaptionedCell)
final class PromoCaptionedCell: PushwooshInboxCell {

    // Card chrome
    private let card = UIView()
    private let gradientLayer = CAGradientLayer()
    private let promoBadge = UILabel()

    // Hero — round image centred on the card
    private let heroImage = UIImageView()

    private static let imageSize: CGFloat = 120

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        installPromoLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installPromoLayout()
    }

    /// Builds the entire layout from scratch. We `resetInheritedLayout` to
    /// drop the SDK's default cell chrome (which targets a Mail-style row),
    /// then add our own card + gradient + PROMO badge + hero + text stack.
    private func installPromoLayout() {
        resetInheritedLayout()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 18
        if #available(iOS 13.0, *) { card.layer.cornerCurve = .continuous }
        card.layer.masksToBounds = true
        contentView.addSubview(card)

        // Gradient as the card's bottom-most layer.
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.353, blue: 0.373, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.541, blue: 0.239, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        card.layer.insertSublayer(gradientLayer, at: 0)

        // PROMO badge — top-leading, gold pill.
        promoBadge.translatesAutoresizingMaskIntoConstraints = false
        promoBadge.text = "PROMO"
        promoBadge.font = .systemFont(ofSize: 11, weight: .heavy)
        promoBadge.textColor = .black
        promoBadge.textAlignment = .center
        promoBadge.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 1.0)
        promoBadge.layer.cornerRadius = 11
        promoBadge.layer.masksToBounds = true
        promoBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        card.addSubview(promoBadge)

        // Round hero image — 120×120, centred horizontally, near the top.
        heroImage.translatesAutoresizingMaskIntoConstraints = false
        heroImage.contentMode = .scaleAspectFill
        heroImage.clipsToBounds = true
        heroImage.layer.cornerRadius = Self.imageSize / 2
        heroImage.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        heroImage.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        heroImage.layer.borderWidth = 2
        card.addSubview(heroImage)

        // Title + body + date in a centred vertical column under the image.
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        card.addSubview(titleLabel)

        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.numberOfLines = 3
        bodyLabel.textAlignment = .center
        card.addSubview(bodyLabel)

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textAlignment = .center
        card.addSubview(dateLabel)

        // Inline CTA stack along the bottom — host calls applyButtons() in apply.
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .fillEqually
        buttonsStack.spacing = 8
        buttonsStack.isHidden = true
        card.addSubview(buttonsStack)

        NSLayoutConstraint.activate([
            // Card insets.
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            promoBadge.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            promoBadge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            promoBadge.heightAnchor.constraint(equalToConstant: 22),
            promoBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            heroImage.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            heroImage.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            heroImage.widthAnchor.constraint(equalToConstant: Self.imageSize),
            heroImage.heightAnchor.constraint(equalToConstant: Self.imageSize),

            titleLabel.topAnchor.constraint(equalTo: heroImage.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            bodyLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),

            dateLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            buttonsStack.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            buttonsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            buttonsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            buttonsStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -20),

            // Card has a min height so cards without buttons / body still look balanced.
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 280)
        ])
    }

    /// Keep the gradient layer's frame in sync with the card on every layout pass.
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = card.bounds
        gradientLayer.cornerRadius = card.layer.cornerRadius
    }

    override func apply(message: PWInboxMessageProtocol,
                        attributes: PushwooshInboxKitAttributes) {
        let style = attributes.style

        // Title — bigger SF Pro Rounded heavy, white.
        if #available(iOS 13.0, *),
           let descriptor = UIFont.systemFont(ofSize: 20, weight: .heavy)
                .fontDescriptor.withDesign(.rounded) {
            titleLabel.font = UIFont(descriptor: descriptor, size: 20)
        } else {
            titleLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        }
        titleLabel.text = message.title
        titleLabel.textColor = .white

        bodyLabel.font = style.bodyFont
        bodyLabel.text = message.message
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.85)

        dateLabel.font = .systemFont(ofSize: 12, weight: .medium)
        dateLabel.text = style.dateFormatter(message.sendDate ?? Date())
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.7)

        // Hero image — load remote, fall back to placeholder. Uses a tiny
        // URLSession + NSCache loader local to the sample (the SDK's
        // internal MessageImageLoader is not exposed publicly).
        heroImage.image = style.imagePlaceholder
        if let urlString = message.imageUrl, !urlString.isEmpty {
            SamplePromoImageLoader.shared.load(urlString, into: heroImage)
        }
        startHeroAnimation()

        // Inline CTAs through the SDK helper. We re-tint after the helper
        // populates the stack so the buttons match the dark gradient.
        let buttons = attributes.inlineButtonsEnabled ? PushwooshInboxButton.decode(from: message) : []
        applyButtons(buttons, style: style)
        for arranged in buttonsStack.arrangedSubviews {
            guard let button = arranged as? UIButton else { continue }
            button.backgroundColor = UIColor.black.withAlphaComponent(0.40)
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 10
            if #available(iOS 13.0, *) { button.layer.cornerCurve = .continuous }
        }

        // PROMO badge follows the message — show only when the marketer
        // opted in via actionParams["promoBadge"] = true. Otherwise keep
        // the layout but hide the pill.
        let params = (message.actionParams as NSDictionary?)
        let showBadge = (params?["promoBadge"] as? Bool) ?? true
        promoBadge.isHidden = !showBadge

        // Pin glyph — same plumbing as in stock cells. Place it next to the
        // PROMO badge, top-trailing of the card.
        let isPinned = attributes.pinningEnabled && PushwooshInboxKitAttributes.isPinned(message)
        pinIndicatorView.isHidden = !isPinned
        if isPinned, pinIndicatorView.superview == nil {
            pinIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            pinIndicatorView.tintColor = .white
            card.addSubview(pinIndicatorView)
            NSLayoutConstraint.activate([
                pinIndicatorView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                pinIndicatorView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                pinIndicatorView.widthAnchor.constraint(equalToConstant: 16),
                pinIndicatorView.heightAnchor.constraint(equalToConstant: 16)
            ])
            if #available(iOS 13.0, *) {
                let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
                pinIndicatorView.image = UIImage(systemName: "pin.fill", withConfiguration: cfg)
            }
        }

        // Unread dot — overlay on the bottom-leading of the hero image.
        unreadIndicatorView.isHidden = message.isRead
        unreadIndicatorView.backgroundColor = .white
        if unreadIndicatorView.superview == nil {
            unreadIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            unreadIndicatorView.layer.cornerRadius = 5
            card.addSubview(unreadIndicatorView)
            NSLayoutConstraint.activate([
                unreadIndicatorView.trailingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: -4),
                unreadIndicatorView.bottomAnchor.constraint(equalTo: heroImage.bottomAnchor, constant: -4),
                unreadIndicatorView.widthAnchor.constraint(equalToConstant: 10),
                unreadIndicatorView.heightAnchor.constraint(equalToConstant: 10)
            ])
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        SamplePromoImageLoader.shared.cancelLoad(for: heroImage)
        heroImage.image = nil
        heroImage.layer.removeAllAnimations()
        heroImage.transform = .identity
        promoBadge.isHidden = false
        pinIndicatorView.isHidden = true
        unreadIndicatorView.isHidden = true
    }

    /// Continuous "breathing" pulse plus a slow border-color shimmer. Layered
    /// CAAnimations attached to the heroImage so the cell feels alive while
    /// it sits on screen. Idempotent — replaces any prior animations.
    private func startHeroAnimation() {
        heroImage.layer.removeAllAnimations()

        // Scale pulse — 1.0 → 1.04 → 1.0, soft autoreverse.
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.04
        pulse.duration = 1.6
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        heroImage.layer.add(pulse, forKey: "promo.pulse")

        // Border-color shimmer — white → bright cyan → white.
        let border = CABasicAnimation(keyPath: "borderColor")
        border.fromValue = UIColor.white.withAlphaComponent(0.35).cgColor
        border.toValue = UIColor(red: 1.0, green: 0.353, blue: 0.373, alpha: 0.85).cgColor
        border.duration = 1.6
        border.autoreverses = true
        border.repeatCount = .infinity
        border.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        heroImage.layer.add(border, forKey: "promo.borderShimmer")
    }
}

// MARK: - Tiny URLSession-backed image loader (sample-only)

/// Local replacement for the SDK-internal `MessageImageLoader`. Sample apps
/// can drop in any third-party loader (SDWebImage, Kingfisher, Nuke). The
/// only requirements: cancel previous load when a cell is reused, and
/// guard against the cell being recycled mid-flight (identity check via
/// associated `URLSessionDataTask`).
private final class SamplePromoImageLoader {

    static let shared = SamplePromoImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let session = URLSession.shared
    private static var taskKey: UInt8 = 0

    func load(_ urlString: String, into imageView: UIImageView) {
        cancelLoad(for: imageView)

        if let cached = cache.object(forKey: urlString as NSString) {
            imageView.image = cached
            return
        }

        guard let url = URL(string: urlString) else { return }

        var taskRef: URLSessionDataTask?
        let task = session.dataTask(with: url) { [weak self, weak imageView] data, _, error in
            guard error == nil,
                  let data = data,
                  let image = UIImage(data: data) else { return }
            self?.cache.setObject(image, forKey: urlString as NSString)
            DispatchQueue.main.async {
                guard let imageView = imageView else { return }
                let stored = objc_getAssociatedObject(imageView, &SamplePromoImageLoader.taskKey) as? URLSessionDataTask
                if stored === taskRef {
                    imageView.image = image
                }
            }
        }
        taskRef = task
        objc_setAssociatedObject(imageView, &SamplePromoImageLoader.taskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        task.resume()
    }

    func cancelLoad(for imageView: UIImageView) {
        if let task = objc_getAssociatedObject(imageView, &SamplePromoImageLoader.taskKey) as? URLSessionDataTask {
            task.cancel()
        }
        objc_setAssociatedObject(imageView, &SamplePromoImageLoader.taskKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
