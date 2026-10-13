import Foundation

enum QuoteBook {
    static let offsetKey = "quoteOffset"

    static let lines: [String] = [
        "Small steps still move you forward.",
        "Rest is part of the work.",
        "Today is a good day to start.",
        "Be the calm in the room.",
        "Done is better than perfect.",
        "You have done hard things before.",
        "Drink some water. Seriously.",
        "Make it simple. Then make it great.",
        "Curiosity beats fear.",
        "One page at a time.",
        "The best time is now.",
        "Kindness is free. Spend it.",
        "Breathe in. Breathe out. Begin.",
        "Progress, not perfection.",
        "Your future self says thanks.",
        "Slow is smooth. Smooth is fast.",
        "Fold the day in half. Rest.",
        "Keep going. You are closer than you think.",
        "Good things take time.",
        "Ask one more question.",
        "Leave it better than you found it.",
        "Focus on what you can change.",
        "Tiny habits. Big results.",
        "Sleep is a superpower.",
        "Say yes to the walk.",
        "Learn something new today.",
        "Every expert was once a beginner.",
        "Clear desk. Clear mind.",
        "Laugh at least once today.",
        "You are allowed to take up space.",
    ]

    static func quote(for date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let hour = calendar.component(.hour, from: date)
        let offset = AppGroup.defaults.integer(forKey: offsetKey)
        let index = (day * 24 + hour + offset) % lines.count
        return lines[(index + lines.count) % lines.count]
    }

    static func advance() {
        let defaults = AppGroup.defaults
        defaults.set(defaults.integer(forKey: offsetKey) + 1, forKey: offsetKey)
    }
}
