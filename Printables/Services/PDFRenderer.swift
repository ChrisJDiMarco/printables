import Foundation
import UIKit
import PDFKit

struct PDFRenderer {
    let pageSize: CGSize
    let margin: CGFloat = 36

    init(paperSize: PaperSize) {
        self.pageSize = paperSize.pointsSize
    }

    /// Wrap an AI-generated worksheet image in a print-ready PDF page.
    /// Image is aspect-fit centered with small white margin around it.
    func renderImagePage(image: UIImage, title: String? = nil) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        var info: [String: Any] = [
            kCGPDFContextAuthor as String: "Printables for little learners",
            kCGPDFContextCreator as String: "Printables iOS"
        ]
        if let title { info[kCGPDFContextTitle as String] = title }
        format.documentInfo = info

        let bounds = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            UIColor.white.setFill()
            UIRectFill(bounds)

            let pageMargin: CGFloat = 18
            let drawRect = bounds.insetBy(dx: pageMargin, dy: pageMargin)

            let imgRatio = image.size.width / image.size.height
            let pageRatio = drawRect.width / drawRect.height

            var fitted = drawRect
            if imgRatio > pageRatio {
                let h = drawRect.width / imgRatio
                fitted = CGRect(
                    x: drawRect.minX,
                    y: drawRect.midY - h / 2,
                    width: drawRect.width,
                    height: h
                )
            } else {
                let w = drawRect.height * imgRatio
                fitted = CGRect(
                    x: drawRect.midX - w / 2,
                    y: drawRect.minY,
                    width: w,
                    height: drawRect.height
                )
            }

            image.draw(in: fitted)
        }
    }

    func render(worksheet: Worksheet, photo: UIImage?) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: worksheet.content.title,
            kCGPDFContextAuthor as String: "Printables for little learners",
            kCGPDFContextCreator as String: "Printables iOS"
        ]

        let bounds = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()
            drawPageBackground(in: bounds)
            drawCoverHeader(in: bounds, worksheet: worksheet)
            drawHero(in: bounds, worksheet: worksheet, photo: photo)
            drawTrace(in: bounds, worksheet: worksheet)
            drawCounting(in: bounds, worksheet: worksheet)
            drawCreativeRow(in: bounds, worksheet: worksheet)
            drawVocabularyAndQuestions(in: bounds, worksheet: worksheet)
            drawFooter(in: bounds, worksheet: worksheet)
        }
        return data
    }

    private func drawPageBackground(in bounds: CGRect) {
        UIColor(red: 1.00, green: 0.99, blue: 0.93, alpha: 1.0).setFill()
        UIRectFill(bounds)

        let dotCount = 28
        let palette: [UIColor] = [
            UIColor(red: 1.00, green: 0.82, blue: 0.32, alpha: 0.65),
            UIColor(red: 0.91, green: 0.36, blue: 0.36, alpha: 0.45),
            UIColor(red: 0.43, green: 0.74, blue: 0.91, alpha: 0.55)
        ]
        var generator = SystemRandomNumberGenerator()
        for index in 0..<dotCount {
            let radius = CGFloat.random(in: 3...8, using: &generator)
            let x = CGFloat.random(in: bounds.minX...bounds.maxX, using: &generator)
            let y = CGFloat.random(in: bounds.minY...bounds.maxY, using: &generator)
            let color = palette[index % palette.count]
            color.setFill()
            UIBezierPath(ovalIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)).fill()
        }
    }

    private func drawCoverHeader(in bounds: CGRect, worksheet: Worksheet) {
        let badgeText: String
        if let name = worksheet.childName, !name.isEmpty {
            badgeText = "Made for \(name)"
        } else {
            badgeText = "Printables for little learners"
        }
        let badgeFont = UIFont.systemFont(ofSize: 11, weight: .heavy)
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: UIColor(red: 0.91, green: 0.36, blue: 0.36, alpha: 1.0)
        ]
        let badgeSize = (badgeText as NSString).size(withAttributes: badgeAttrs)
        let badgePadding: CGFloat = 12
        let badgeRect = CGRect(
            x: bounds.midX - (badgeSize.width / 2) - badgePadding,
            y: bounds.minY + 22,
            width: badgeSize.width + badgePadding * 2,
            height: badgeSize.height + 10
        )
        let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeRect.height / 2)
        UIColor.white.setFill()
        badgePath.fill()
        UIColor(red: 0.91, green: 0.36, blue: 0.36, alpha: 0.25).setStroke()
        badgePath.lineWidth = 1
        badgePath.stroke()

        // Sparkle dot left of badge text
        let dotRect = CGRect(x: badgeRect.minX + badgePadding - 4, y: badgeRect.midY - 3, width: 6, height: 6)
        UIColor(red: 1.00, green: 0.82, blue: 0.32, alpha: 1.0).setFill()
        UIBezierPath(ovalIn: dotRect).fill()

        (badgeText as NSString).draw(
            at: CGPoint(x: badgeRect.minX + badgePadding + 6, y: badgeRect.minY + 5),
            withAttributes: badgeAttrs
        )

        let titleFont = UIFont.systemFont(ofSize: 32, weight: .heavy)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 1.0)
        ]
        let title = worksheet.content.title
        let titleRect = CGRect(
            x: bounds.minX + margin,
            y: badgeRect.maxY + 10,
            width: bounds.width - margin * 2,
            height: 80
        )
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        var styled = titleAttrs
        styled[.paragraphStyle] = paragraph
        (title as NSString).draw(in: titleRect, withAttributes: styled)
    }

    private func drawHero(in bounds: CGRect, worksheet: Worksheet, photo: UIImage?) {
        let yStart = bounds.minY + 160
        let cardWidth = bounds.width - margin * 2
        let cardRect = CGRect(x: bounds.minX + margin, y: yStart, width: cardWidth, height: 200)
        drawCard(rect: cardRect, fill: UIColor.white)

        let photoRect = CGRect(
            x: cardRect.minX + 18,
            y: cardRect.minY + 18,
            width: 164,
            height: 164
        )
        let photoPath = UIBezierPath(roundedRect: photoRect, cornerRadius: 16)
        UIColor(red: 1.00, green: 0.95, blue: 0.80, alpha: 1.0).setFill()
        photoPath.fill()

        if let image = photo {
            let context = UIGraphicsGetCurrentContext()
            context?.saveGState()
            photoPath.addClip()
            drawAspectFill(image: image, in: photoRect)
            context?.restoreGState()
        } else {
            let placeholderAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor(red: 0.62, green: 0.55, blue: 0.38, alpha: 1.0)
            ]
            let placeholder = "Photo"
            let size = (placeholder as NSString).size(withAttributes: placeholderAttrs)
            (placeholder as NSString).draw(
                at: CGPoint(
                    x: photoRect.midX - size.width / 2,
                    y: photoRect.midY - size.height / 2
                ),
                withAttributes: placeholderAttrs
            )
        }

        let textX = photoRect.maxX + 18
        let textWidth = cardRect.maxX - textX - 18

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor(red: 0.20, green: 0.60, blue: 0.83, alpha: 1.0),
            .kern: 1.4
        ]
        let label = "TODAY WE LEARN ABOUT"
        (label as NSString).draw(
            at: CGPoint(x: textX, y: cardRect.minY + 22),
            withAttributes: labelAttrs
        )

        let subjectAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26, weight: .heavy),
            .foregroundColor: UIColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 1.0)
        ]
        let subjectRect = CGRect(x: textX, y: cardRect.minY + 38, width: textWidth, height: 38)
        (worksheet.content.subjectLabel as NSString).draw(in: subjectRect, withAttributes: subjectAttrs)

        let introAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor(red: 0.32, green: 0.33, blue: 0.40, alpha: 1.0)
        ]
        let introParagraph = NSMutableParagraphStyle()
        introParagraph.lineSpacing = 3
        var introStyled = introAttrs
        introStyled[.paragraphStyle] = introParagraph
        let introRect = CGRect(x: textX, y: cardRect.minY + 82, width: textWidth, height: 64)
        (worksheet.content.intro as NSString).draw(in: introRect, withAttributes: introStyled)

        var chipX = textX
        let chipY = cardRect.maxY - 38
        let chipPalette: [UIColor] = [
            UIColor(red: 1.00, green: 0.82, blue: 0.32, alpha: 1.0),
            UIColor(red: 0.50, green: 0.83, blue: 0.67, alpha: 1.0),
            UIColor(red: 0.76, green: 0.70, blue: 0.92, alpha: 1.0),
            UIColor(red: 0.43, green: 0.74, blue: 0.91, alpha: 1.0)
        ]
        for (idx, goal) in worksheet.content.learningGoals.prefix(4).enumerated() {
            let goalAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .heavy),
                .foregroundColor: UIColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 1.0)
            ]
            let goalSize = (goal as NSString).size(withAttributes: goalAttrs)
            let chipRect = CGRect(x: chipX, y: chipY, width: goalSize.width + 16, height: 22)
            if chipRect.maxX > cardRect.maxX - 16 { break }
            let chipPath = UIBezierPath(roundedRect: chipRect, cornerRadius: 11)
            chipPalette[idx % chipPalette.count].setFill()
            chipPath.fill()
            (goal as NSString).draw(
                at: CGPoint(x: chipRect.minX + 8, y: chipRect.minY + 6),
                withAttributes: goalAttrs
            )
            chipX = chipRect.maxX + 6
        }
    }

    private func drawTrace(in bounds: CGRect, worksheet: Worksheet) {
        let cardY = bounds.minY + 380
        let cardRect = CGRect(x: bounds.minX + margin, y: cardY, width: bounds.width - margin * 2, height: 124)
        drawCard(rect: cardRect, fill: UIColor.white)

        drawSectionHeader(text: "1. Trace the word", in: cardRect, color: UIColor(red: 0.91, green: 0.36, blue: 0.36, alpha: 1.0))

        let traceWord = worksheet.content.traceWord
        guard !traceWord.isEmpty else { return }

        let letterCount = traceWord.count
        let availableWidth = cardRect.width - 32
        let letterWidth = min(70, availableWidth / CGFloat(letterCount))
        let totalWidth = letterWidth * CGFloat(letterCount)
        var x = cardRect.midX - totalWidth / 2
        let baseY = cardRect.minY + 50

        for ch in traceWord {
            let letterRect = CGRect(x: x, y: baseY, width: letterWidth, height: 60)
            let boxPath = UIBezierPath(roundedRect: letterRect.insetBy(dx: 4, dy: 2), cornerRadius: 10)
            UIColor(red: 0.99, green: 0.95, blue: 0.80, alpha: 1.0).setFill()
            boxPath.fill()
            UIColor(red: 1.00, green: 0.82, blue: 0.32, alpha: 0.7).setStroke()
            boxPath.lineWidth = 1
            boxPath.stroke()

            let letterAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .heavy),
                .foregroundColor: UIColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 0.18)
            ]
            let letterStr = String(ch)
            let size = (letterStr as NSString).size(withAttributes: letterAttrs)
            (letterStr as NSString).draw(
                at: CGPoint(
                    x: letterRect.midX - size.width / 2,
                    y: letterRect.midY - size.height / 2
                ),
                withAttributes: letterAttrs
            )
            x += letterWidth
        }
    }

    private func drawCounting(in bounds: CGRect, worksheet: Worksheet) {
        let cardY = bounds.minY + 520
        let cardRect = CGRect(x: bounds.minX + margin, y: cardY, width: bounds.width - margin * 2, height: 110)
        drawCard(rect: cardRect, fill: UIColor.white)

        let target = worksheet.content.countingTarget
        let item = worksheet.content.countingItem
        let headerText = "2. Count the \(item) — circle \(target)"
        drawSectionHeader(text: headerText, in: cardRect, color: UIColor(red: 0.20, green: 0.60, blue: 0.83, alpha: 1.0))

        let circleCount = max(target + 2, target + 1)
        let availableWidth = cardRect.width - 32
        let circleSize: CGFloat = 36
        let gap: CGFloat = max(4, (availableWidth - circleSize * CGFloat(circleCount)) / CGFloat(max(1, circleCount - 1)))
        var x = cardRect.minX + 16
        let centerY = cardRect.minY + 70

        for index in 0..<circleCount {
            let rect = CGRect(x: x, y: centerY, width: circleSize, height: circleSize)
            let path = UIBezierPath(ovalIn: rect)
            UIColor(red: 1.00, green: 0.95, blue: 0.80, alpha: 1.0).setFill()
            path.fill()
            UIColor(red: 1.00, green: 0.82, blue: 0.32, alpha: 0.9).setStroke()
            path.lineWidth = 1.5
            path.stroke()

            let numberAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .heavy),
                .foregroundColor: UIColor(red: 0.32, green: 0.33, blue: 0.40, alpha: 0.6)
            ]
            let number = String(index + 1)
            let size = (number as NSString).size(withAttributes: numberAttrs)
            (number as NSString).draw(
                at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2),
                withAttributes: numberAttrs
            )
            x += circleSize + gap
        }
    }

    private func drawCreativeRow(in bounds: CGRect, worksheet: Worksheet) {
        let cardY = bounds.minY + 650
        let totalWidth = bounds.width - margin * 2
        let gap: CGFloat = 14
        let cardWidth = (totalWidth - gap) / 2
        let cardHeight: CGFloat = 130

        let coloringRect = CGRect(x: bounds.minX + margin, y: cardY, width: cardWidth, height: cardHeight)
        drawCard(rect: coloringRect, fill: UIColor.white)
        drawSectionHeader(text: "3. Color it in", in: coloringRect, color: UIColor(red: 0.91, green: 0.36, blue: 0.36, alpha: 1.0))
        drawWrapped(
            text: worksheet.content.coloringPrompt,
            rect: CGRect(
                x: coloringRect.minX + 16,
                y: coloringRect.minY + 46,
                width: coloringRect.width - 32,
                height: 50
            ),
            font: UIFont.systemFont(ofSize: 12, weight: .medium),
            color: UIColor(red: 0.32, green: 0.33, blue: 0.40, alpha: 1.0)
        )
        drawSwatches(
            in: CGRect(
                x: coloringRect.minX + 16,
                y: coloringRect.maxY - 30,
                width: coloringRect.width - 32,
                height: 18
            )
        )

        let drawingRect = CGRect(x: coloringRect.maxX + gap, y: cardY, width: cardWidth, height: cardHeight)
        drawCard(rect: drawingRect, fill: UIColor.white)
        drawSectionHeader(text: "4. Draw your own", in: drawingRect, color: UIColor(red: 0.50, green: 0.83, blue: 0.67, alpha: 1.0))
        drawWrapped(
            text: worksheet.content.drawingPrompt,
            rect: CGRect(
                x: drawingRect.minX + 16,
                y: drawingRect.minY + 46,
                width: drawingRect.width - 32,
                height: 50
            ),
            font: UIFont.systemFont(ofSize: 12, weight: .medium),
            color: UIColor(red: 0.32, green: 0.33, blue: 0.40, alpha: 1.0)
        )
        let boxRect = CGRect(
            x: drawingRect.minX + 16,
            y: drawingRect.maxY - 46,
            width: drawingRect.width - 32,
            height: 34
        )
        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 8)
        UIColor(red: 0.99, green: 0.97, blue: 0.92, alpha: 1.0).setFill()
        boxPath.fill()
        UIColor(red: 0.50, green: 0.83, blue: 0.67, alpha: 0.6).setStroke()
        boxPath.setLineDash([3, 3], count: 2, phase: 0)
        boxPath.lineWidth = 1
        boxPath.stroke()
    }

    private func drawVocabularyAndQuestions(in bounds: CGRect, worksheet: Worksheet) {
        let cardY = bounds.minY + 800
        let totalWidth = bounds.width - margin * 2
        let gap: CGFloat = 14
        let cardWidth = (totalWidth - gap) / 2
        let cardHeight: CGFloat = 150

        let vocabRect = CGRect(x: bounds.minX + margin, y: cardY, width: cardWidth, height: cardHeight)
        drawCard(rect: vocabRect, fill: UIColor.white)
        drawSectionHeader(text: "Word bank", in: vocabRect, color: UIColor(red: 0.76, green: 0.70, blue: 0.92, alpha: 1.0))

        var listY = vocabRect.minY + 44
        for entry in worksheet.content.vocabulary.prefix(3) {
            let wordAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
                .foregroundColor: UIColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 1.0)
            ]
            (entry.word as NSString).draw(
                at: CGPoint(x: vocabRect.minX + 16, y: listY),
                withAttributes: wordAttrs
            )
            drawWrapped(
                text: entry.definition,
                rect: CGRect(
                    x: vocabRect.minX + 16,
                    y: listY + 14,
                    width: vocabRect.width - 32,
                    height: 22
                ),
                font: UIFont.systemFont(ofSize: 10.5, weight: .medium),
                color: UIColor(red: 0.32, green: 0.33, blue: 0.40, alpha: 1.0)
            )
            listY += 34
        }

        let questionsRect = CGRect(x: vocabRect.maxX + gap, y: cardY, width: cardWidth, height: cardHeight)
        drawCard(rect: questionsRect, fill: UIColor.white)
        drawSectionHeader(text: "Let's chat", in: questionsRect, color: UIColor(red: 0.20, green: 0.60, blue: 0.83, alpha: 1.0))

        var qY = questionsRect.minY + 44
        for (idx, question) in worksheet.content.questions.prefix(3).enumerated() {
            let bulletAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .heavy),
                .foregroundColor: UIColor(red: 0.91, green: 0.36, blue: 0.36, alpha: 1.0)
            ]
            (("Q\(idx + 1).") as NSString).draw(
                at: CGPoint(x: questionsRect.minX + 16, y: qY),
                withAttributes: bulletAttrs
            )
            drawWrapped(
                text: question,
                rect: CGRect(
                    x: questionsRect.minX + 42,
                    y: qY,
                    width: questionsRect.width - 56,
                    height: 26
                ),
                font: UIFont.systemFont(ofSize: 11, weight: .medium),
                color: UIColor(red: 0.32, green: 0.33, blue: 0.40, alpha: 1.0)
            )
            qY += 30
        }
    }

    private func drawFooter(in bounds: CGRect, worksheet: Worksheet) {
        let footerY = bounds.maxY - 110
        let footerRect = CGRect(
            x: bounds.minX + margin,
            y: footerY,
            width: bounds.width - margin * 2,
            height: 80
        )
        let footerPath = UIBezierPath(roundedRect: footerRect, cornerRadius: 18)
        UIColor(red: 1.00, green: 0.82, blue: 0.32, alpha: 0.25).setFill()
        footerPath.fill()

        let factHeaderAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .heavy),
            .foregroundColor: UIColor(red: 0.91, green: 0.36, blue: 0.36, alpha: 1.0),
            .kern: 1.2
        ]
        ("DID YOU KNOW?" as NSString).draw(
            at: CGPoint(x: footerRect.minX + 18, y: footerRect.minY + 12),
            withAttributes: factHeaderAttrs
        )

        drawWrapped(
            text: worksheet.content.funFact,
            rect: CGRect(
                x: footerRect.minX + 18,
                y: footerRect.minY + 28,
                width: footerRect.width - 36,
                height: 28
            ),
            font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            color: UIColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 1.0)
        )

        drawWrapped(
            text: "Grown-up tip: " + worksheet.content.parentTip,
            rect: CGRect(
                x: footerRect.minX + 18,
                y: footerRect.minY + 56,
                width: footerRect.width - 36,
                height: 20
            ),
            font: UIFont.italicSystemFont(ofSize: 10),
            color: UIColor(red: 0.32, green: 0.33, blue: 0.40, alpha: 1.0)
        )

        let madeText = "Made for little curious minds"
        let madeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: UIColor(red: 0.32, green: 0.33, blue: 0.40, alpha: 0.65)
        ]
        let size = (madeText as NSString).size(withAttributes: madeAttrs)
        (madeText as NSString).draw(
            at: CGPoint(x: bounds.midX - size.width / 2, y: bounds.maxY - 18),
            withAttributes: madeAttrs
        )
    }

    private func drawCard(rect: CGRect, fill: UIColor) {
        let shadowOffset: CGFloat = 4
        let shadowRect = rect.offsetBy(dx: 0, dy: shadowOffset)
        let shadowPath = UIBezierPath(roundedRect: shadowRect, cornerRadius: 18)
        UIColor(red: 0, green: 0, blue: 0, alpha: 0.05).setFill()
        shadowPath.fill()

        let path = UIBezierPath(roundedRect: rect, cornerRadius: 18)
        fill.setFill()
        path.fill()
    }

    private func drawSectionHeader(text: String, in cardRect: CGRect, color: UIColor) {
        let bulletRect = CGRect(x: cardRect.minX + 16, y: cardRect.minY + 18, width: 6, height: 6)
        let bulletPath = UIBezierPath(ovalIn: bulletRect)
        color.setFill()
        bulletPath.fill()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: UIColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 1.0)
        ]
        (text as NSString).draw(
            at: CGPoint(x: bulletRect.maxX + 8, y: cardRect.minY + 14),
            withAttributes: attrs
        )
    }

    private func drawWrapped(text: String, rect: CGRect, font: UIFont, color: UIColor) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 2
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        (text as NSString).draw(in: rect, withAttributes: attrs)
    }

    private func drawSwatches(in rect: CGRect) {
        let colors: [UIColor] = [
            UIColor(red: 0.91, green: 0.36, blue: 0.36, alpha: 1.0),
            UIColor(red: 1.00, green: 0.82, blue: 0.32, alpha: 1.0),
            UIColor(red: 0.50, green: 0.83, blue: 0.67, alpha: 1.0),
            UIColor(red: 0.20, green: 0.60, blue: 0.83, alpha: 1.0),
            UIColor(red: 0.76, green: 0.70, blue: 0.92, alpha: 1.0)
        ]
        let size: CGFloat = min(rect.height, 14)
        let gap: CGFloat = 6
        var x = rect.minX
        for color in colors {
            let dotRect = CGRect(x: x, y: rect.midY - size / 2, width: size, height: size)
            let path = UIBezierPath(ovalIn: dotRect)
            color.setFill()
            path.fill()
            x += size + gap
        }
    }

    private func drawAspectFill(image: UIImage, in rect: CGRect) {
        let imageRatio = image.size.width / image.size.height
        let rectRatio = rect.width / rect.height
        var drawRect = rect
        if imageRatio > rectRatio {
            let newWidth = rect.height * imageRatio
            drawRect = CGRect(
                x: rect.midX - newWidth / 2,
                y: rect.minY,
                width: newWidth,
                height: rect.height
            )
        } else {
            let newHeight = rect.width / imageRatio
            drawRect = CGRect(
                x: rect.minX,
                y: rect.midY - newHeight / 2,
                width: rect.width,
                height: newHeight
            )
        }
        image.draw(in: drawRect)
    }
}
