import Foundation
import SwiftUI

enum WorksheetStyle: String, CaseIterable, Codable, Identifiable, Hashable {
    case pastel
    case monoInk
    case comic
    case watercolor
    case crayon
    case storybook
    case jungle
    case space

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pastel: return "Pastel"
        case .monoInk: return "Mono Ink"
        case .comic: return "Comic"
        case .watercolor: return "Watercolor"
        case .crayon: return "Crayon"
        case .storybook: return "Storybook"
        case .jungle: return "Jungle"
        case .space: return "Space"
        }
    }

    var tagline: String {
        switch self {
        case .pastel: return "Soft & cheerful"
        case .monoInk: return "Ink-friendly B&W"
        case .comic: return "Bold & punchy"
        case .watercolor: return "Painterly & soft"
        case .crayon: return "Hand-drawn charm"
        case .storybook: return "Classic warmth"
        case .jungle: return "Adventure ready"
        case .space: return "Cosmic fun"
        }
    }

    var emoji: String {
        switch self {
        case .pastel: return "🌸"
        case .monoInk: return "✒️"
        case .comic: return "💥"
        case .watercolor: return "🎨"
        case .crayon: return "🖍️"
        case .storybook: return "📖"
        case .jungle: return "🌿"
        case .space: return "🚀"
        }
    }

    var swatchColors: [Color] {
        switch self {
        case .pastel: return [Color(red: 1.0, green: 0.97, blue: 0.86), Color(red: 0.91, green: 0.36, blue: 0.36), Color(red: 0.20, green: 0.60, blue: 0.83)]
        case .monoInk: return [.white, Color(white: 0.18), Color(white: 0.55)]
        case .comic: return [Color(red: 1.0, green: 0.96, blue: 0.93), Color(red: 0.94, green: 0.22, blue: 0.27), Color(red: 0.18, green: 0.32, blue: 0.95)]
        case .watercolor: return [Color(red: 0.98, green: 0.95, blue: 0.91), Color(red: 0.62, green: 0.78, blue: 0.86), Color(red: 0.78, green: 0.55, blue: 0.68)]
        case .crayon: return [Color(red: 1.0, green: 0.98, blue: 0.93), Color(red: 0.95, green: 0.55, blue: 0.32), Color(red: 0.32, green: 0.68, blue: 0.45)]
        case .storybook: return [Color(red: 0.99, green: 0.94, blue: 0.82), Color(red: 0.55, green: 0.32, blue: 0.18), Color(red: 0.88, green: 0.40, blue: 0.18)]
        case .jungle: return [Color(red: 0.94, green: 0.97, blue: 0.85), Color(red: 0.20, green: 0.55, blue: 0.30), Color(red: 0.94, green: 0.66, blue: 0.20)]
        case .space: return [Color(red: 0.06, green: 0.08, blue: 0.22), Color(red: 0.42, green: 0.36, blue: 0.92), Color(red: 1.0, green: 0.86, blue: 0.36)]
        }
    }

    var isDarkBackground: Bool {
        switch self {
        case .space: return true
        default: return false
        }
    }

    /// Rich style description injected into the image generation prompt.
    /// This is what makes each style distinct in the generated worksheet.
    var promptDescription: String {
        switch self {
        case .pastel:
            return """
            STYLE DIRECTION — Pastel & Cheerful (default):
            - Background: soft warm cream (#FFF8E1) with very subtle paper texture
            - Accent palette: coral (#E85C5C), sky blue (#3498DB), sun yellow (#FFD151), mint (#7FCFAA), lilac (#C1B2EB)
            - Typography: rounded heavy sans-serif (like Nunito or SF Rounded), warm and friendly
            - Illustration style: hand-drawn flat illustrations with soft rounded shapes, small ink outline
            - Cards: clean white rounded rectangles with corner radius ~28pt and subtle soft drop shadow
            - Decoration: small colorful dots scattered subtly across the background as confetti
            - Mood: joyful, calm, breathable, like Big Little Feelings or Lovevery design language
            """

        case .monoInk:
            return """
            STYLE DIRECTION — Mono Ink (print-friendly black & white):
            - Background: pure white paper, no color anywhere
            - All ink: pure black (#000000) — no shading, no gradients, no greys
            - Typography: rounded heavy sans-serif in solid black
            - Illustration style: clean black-line drawings only, no fills, like a coloring book
            - Cards: thin black outlined rounded rectangles, no fills
            - Decoration: small black dot accents, dashed lines for tracing
            - Mood: clean, focused, looks great printed on any home printer with low ink
            - IMPORTANT: this is a black and white worksheet only, NO COLOR at all
            """

        case .comic:
            return """
            STYLE DIRECTION — Comic Book:
            - Background: cream paper with subtle halftone dot texture
            - Accent palette: bold red (#E63946), electric blue (#2D5BFA), bright yellow (#FFD60A), white
            - Typography: chunky bold display sans (like Bangers or Luckiest Guy), with subtle drop shadows
            - Illustration style: bold black outlines, flat saturated fills, action lines, halftone shading
            - Cards: white with thick black border (3pt) and offset shadow (like a comic panel)
            - Decoration: speech bubbles for instructions, "POW!" / "WOW!" burst stars in corners
            - Mood: high-energy, exciting, like classic Sunday comics
            """

        case .watercolor:
            return """
            STYLE DIRECTION — Watercolor:
            - Background: warm cream/parchment paper with visible watercolor wash texture
            - Accent palette: dusty rose (#C8908A), sage green (#9BAE93), powder blue (#A8C5D6), soft butter (#E8D08F)
            - Typography: gentle serif-influenced hand-lettered feel
            - Illustration style: loose painterly watercolor washes with visible brush strokes, slightly imperfect edges, soft color bleeds
            - Cards: torn-paper edges, soft watercolor washes inside, no hard borders
            - Decoration: small painted dots, organic shapes, hand-drawn arrows and stars
            - Mood: gentle, artistic, calming, like a Beatrix Potter or Sophie Blackall picture book
            """

        case .crayon:
            return """
            STYLE DIRECTION — Crayon Kid:
            - Background: white paper with visible paper grain
            - Accent palette: crayon-vivid red, blue, green, yellow, purple — like a 64-pack of Crayolas
            - Typography: chunky hand-lettered uppercase, slightly wobbly like a kid wrote it
            - Illustration style: thick waxy crayon textures, visible crayon stroke marks, occasional outside-the-lines moments
            - Cards: outlined in scribbly crayon strokes, slightly imperfect rectangles
            - Decoration: scribbled stars and hearts, a few crayon shavings, kid-art energy
            - Mood: playful, imperfect, full of personality, like art by a 5-year-old but composed
            """

        case .storybook:
            return """
            STYLE DIRECTION — Classic Storybook:
            - Background: aged paper / vintage cream with very subtle vignette
            - Accent palette: warm brown (#8B5A3C), terracotta (#C2693E), forest green (#558B6E), gold (#D4AF37), cream
            - Typography: a warm display serif for headings (like Bookerly or Cardo) paired with friendly sans for body
            - Illustration style: detailed traditional book illustrations with cross-hatching shading, ornate frames around art
            - Cards: rounded with thin double-line borders, decorative corner flourishes
            - Decoration: small floral vignettes, vintage ribbons, ornamental dividers
            - Mood: timeless, warm, like a treasured hand-bound picture book
            """

        case .jungle:
            return """
            STYLE DIRECTION — Jungle Adventure:
            - Background: cream paper with subtle paper texture, scattered leaf silhouettes in corners
            - Accent palette: jungle green (#3A7D44), warm earth (#A0623C), sunset orange (#E89B4A), banana yellow (#F0CB58)
            - Typography: bold sans with adventure-poster vibe, slightly weathered look
            - Illustration style: bold flat illustrations of jungle animals and plants, screen-printed feel
            - Cards: white with thick green or earth-brown borders, faux torn-paper edges
            - Decoration: monstera and banana leaves in corners, vines along borders, compass and binocular doodles
            - Mood: adventurous, lush, exciting, like a kids' nature magazine spread
            """

        case .space:
            return """
            STYLE DIRECTION — Space Adventure:
            - Background: deep navy (#0F1430) with scattered tiny stars and faint nebula gradients
            - Accent palette: cosmic purple (#6C5CE7), star yellow (#FFE145), nebula pink (#FF6B9D), aqua (#36C5F0)
            - Typography: futuristic rounded sans with subtle glow, sci-fi but kid-friendly
            - Illustration style: vector flat illustrations of planets, rockets, astronauts, in vibrant colors against dark sky
            - Cards: dark navy or deep purple cards with bright accent borders, glowing soft edges
            - Decoration: tiny stars, orbit lines, planet doodles in corners
            - Mood: cosmic, dreamy, exciting; text remains highly readable on dark backgrounds (use white/bright text)
            - NOTE: text contrast must be high — light text on dark cards, never dark text on dark cards
            """
        }
    }

    static let `default`: WorksheetStyle = .pastel
}
