import Foundation

/// A single activity block on a worksheet. The AI picks 3-5 of these per worksheet based on
/// what fits the photo's subject and the child's age.
struct WorksheetActivity: Codable, Hashable {
    let kind: String
    let title: String
    let instruction: String
    let payload: [String: String]

    init(kind: String, title: String, instruction: String, payload: [String: String] = [:]) {
        self.kind = kind
        self.title = title
        self.instruction = instruction
        self.payload = payload
    }
}

/// Layout treatments — the AI picks one based on subject + age. This drives the overall page composition.
enum WorksheetLayout: String, Codable, CaseIterable {
    /// Classic 6-section grid (cover → activity grid → footer). Best for academic topics.
    case classicGrid
    /// Single large hero illustration with smaller activities woven around it. Best for animals, places, vehicles.
    case heroScene
    /// Comic-style 4-frame story or sequence. Best for life cycles, recipes, processes.
    case storyboard
    /// Big illustrated scene with circles/arrows around items in the scene. Best for "find / identify / count in this picture".
    case explorerSpread
    /// Top-down magazine-style spread (headline, big image, columns). Best for older kids 7-12.
    case magazineSpread

    var promptHint: String {
        switch self {
        case .classicGrid:
            return "Layout: traditional worksheet grid. Header at top, hero card next, then a 2x2 grid of activity cards, then a wide footer. Each card has a clear title and is enclosed in a rounded rectangle."
        case .heroScene:
            return "Layout: one large dominant scene illustration in the upper two-thirds of the page (showing the subject in context), with 3-4 smaller activity panels in the lower third. The scene illustration is the visual centerpiece."
        case .storyboard:
            return "Layout: 4 or 6 numbered storyboard panels arranged in a grid, each showing one stage. Below the storyboard, a 'Let's chat' question row and a fun fact strip."
        case .explorerSpread:
            return "Layout: one giant detailed illustration filling most of the page, with small numbered call-outs (circles, arrows, magnifying-glass icons) pointing to interesting items. A small question/activity list runs along the right margin."
        case .magazineSpread:
            return "Layout: magazine spread feel. A bold headline at top, a wide hero photo/illustration band, then 2 columns of text+activity cards. Includes a sidebar with vocabulary or fun facts."
        }
    }
}

/// Catalogue of activity types. The AI picks from these based on the photo + subject + age + topic.
/// Each kind has a Swift-side rendering hint that gets injected into the gpt-image prompt, so the image
/// model knows exactly how to draw it.
enum ActivityKind: String, CaseIterable {
    case traceWord
    case traceShape
    case countObjects
    case sortGroups
    case matchPairs
    case colorOutline
    case colorByNumber
    case drawBlank
    case drawSequence
    case connectDots
    case mazePath
    case findHidden
    case wordBank
    case discussion
    case labelParts
    case lifeCycle
    case habitatMap
    case compareSize
    case sameDifferent
    case fillBlank
    case opposites
    case timeOfDay
    case feelings
    case pathToSafety
    case foodGroups
    case sequenceSteps
    case observe
    case factSheet

    var description: String {
        switch self {
        case .traceWord: return "Trace the letters of a word (uppercase, hollow outlines with dashed guides)"
        case .traceShape: return "Trace a shape (circle, triangle, star) with dashed outlines"
        case .countObjects: return "Count N items in a row and circle the target number"
        case .sortGroups: return "Sort items into 2 or 3 labeled boxes/categories"
        case .matchPairs: return "Match pictures or words by drawing lines between them"
        case .colorOutline: return "A black-line drawing of the subject ready to color in"
        case .colorByNumber: return "Color by number — sections labeled 1-4 with a key showing which color goes where"
        case .drawBlank: return "An empty dashed rectangle for the child to draw their own version"
        case .drawSequence: return "Draw the next frame in a sequence (storyboard)"
        case .connectDots: return "Connect numbered dots in order to reveal a hidden picture"
        case .mazePath: return "Find the path through a small maze"
        case .findHidden: return "Find the listed items hidden in a scene illustration"
        case .wordBank: return "List of 3 vocabulary words with kid-friendly definitions"
        case .discussion: return "Open-ended discussion questions for parent and child"
        case .labelParts: return "Label the parts of the subject (arrows pointing from labels to parts of an illustration)"
        case .lifeCycle: return "4-stage life cycle illustration (e.g., seed → sprout → plant → flower)"
        case .habitatMap: return "Map or scene showing where the subject lives"
        case .compareSize: return "Compare sizes — order from smallest to biggest"
        case .sameDifferent: return "Spot the differences between two near-identical scenes"
        case .fillBlank: return "Fill in the missing letter in a word"
        case .opposites: return "Match opposites (hot/cold, day/night)"
        case .timeOfDay: return "Order pictures of morning, noon, evening, night"
        case .feelings: return "Identify the feeling shown on a character's face"
        case .pathToSafety: return "Trace the safe path to an exit (great for safety topics)"
        case .foodGroups: return "Sort foods into food groups (great for nutrition topics)"
        case .sequenceSteps: return "Number the steps in the correct order"
        case .observe: return "Observe and write down what you notice (lines provided)"
        case .factSheet: return "Quick fact sheet with 3-4 short facts about the subject"
        }
    }

    var imagePromptInstruction: String {
        switch self {
        case .traceWord:
            return "Large UPPERCASE hollow outline letters with dashed guide lines inside each letter for the child to trace; each letter sits in its own dotted bounding box."
        case .traceShape:
            return "One or two large shapes drawn as dashed outlines for the child to trace over with their finger or pencil."
        case .countObjects:
            return "A neat row of small illustrations of the relevant item — one more than the target number — each surrounded by an empty circle for the child to circle the correct count."
        case .sortGroups:
            return "Two or three labeled boxes drawn side-by-side, with small illustrations of items above the boxes to be sorted into them (show empty arrows or dashed connectors)."
        case .matchPairs:
            return "Two columns of small illustrations or words. The child draws lines connecting matching pairs."
        case .colorOutline:
            return "A clean black-line drawing of the subject, ready for the child to color. No fills — just outlines and details."
        case .colorByNumber:
            return "The subject drawn as labeled regions, each region containing a small number (1, 2, 3, 4). Below it a color key: 1=red, 2=blue, 3=yellow, 4=green."
        case .drawBlank:
            return "A large empty rectangle with a thin dashed border for the child to draw inside."
        case .drawSequence:
            return "Three or four small boxes in a row — the first 1-2 boxes contain illustrated frames of a story, the remaining are blank for the child to complete the sequence."
        case .connectDots:
            return "A pattern of numbered dots (1 through 10-15) arranged in the rough outline of the subject. The child connects them to reveal the picture."
        case .mazePath:
            return "A small simple maze with a clear START (with a small character) and END (with a small icon of the subject). One correct winding path through."
        case .findHidden:
            return "An illustrated scene related to the subject, with 4-5 small items hidden in it. Below the scene, a small key showing the items to find."
        case .wordBank:
            return "A list of 3 vocabulary words. Each word is in bold on its own line, with a 1-line kid-friendly definition directly below it."
        case .discussion:
            return "A numbered list of 2-3 open-ended discussion questions (Q1, Q2, Q3) in clear easy-to-read text."
        case .labelParts:
            return "A large illustration of the subject with 3-4 thin arrow lines pointing from short text labels to specific parts of the subject."
        case .lifeCycle:
            return "Four illustrated panels arranged in a circle or row, each showing one stage of the life cycle, connected by curved arrows. Each panel has a small caption."
        case .habitatMap:
            return "An illustrated environment showing where the subject lives (forest, ocean, savanna, kitchen, etc.) with the subject placed naturally within it."
        case .compareSize:
            return "Three or four illustrated objects in a row, ordered from smallest to largest, with subtle size labels or arrows."
        case .sameDifferent:
            return "Two nearly-identical scenes side by side; 4-5 small details differ between them. The child circles the differences."
        case .fillBlank:
            return "A word with one letter replaced by a blank line, like 'A_PLE'. Below, 2-3 letter options for the child to write in."
        case .opposites:
            return "Two columns of 3 small illustrated pairs that are opposites (e.g., sun/moon, big/small). Child connects pairs with lines."
        case .timeOfDay:
            return "Four small illustrated scenes showing morning, noon, evening, night, but out of order. Child numbers them in the correct sequence 1-4."
        case .feelings:
            return "Three or four small illustrated faces showing different emotions, with empty labels beneath for the child to write or match."
        case .pathToSafety:
            return "A small overhead illustration of a room or place with the subject (e.g., fire truck), and a dashed path showing the safe route to an exit or safe area."
        case .foodGroups:
            return "A food pyramid or 4-section grid with food group labels (Fruits, Vegetables, Grains, Protein). Small food illustrations float above to be sorted in."
        case .sequenceSteps:
            return "Four illustrated step panels showing a process, but out of order. Each has a small empty circle for the child to number 1-4."
        case .observe:
            return "A box labeled 'I noticed…' with 3 horizontal writing lines for the child to record observations."
        case .factSheet:
            return "A small information panel with the subject's name as a header and 3-4 short bullet-point facts beneath it. Use a fact-card visual style."
        }
    }
}
