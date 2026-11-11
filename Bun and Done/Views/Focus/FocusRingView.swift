//
//  FocusRingView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 5/11/2026.
//

import SwiftUI
// Progress ring with the carrot picture in the middle. Only displays what it's given; no logic of its own
struct FocusRingView: View {
    let progress: Double   // 0 to 1
    let isBreak: Bool

    var body: some View {
        ZStack { // ZStack: "Layers"
            // Background track
            Circle()
                .stroke(Color.chipBackground, lineWidth: 10)

            // Progress, starting from the top
            Circle()
                .trim(from: 0, to: progress)
                .stroke(isBreak ? Color.successGreen : Color.accentColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            Image(carrotImageName)
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .padding(18)
        }
        // VoiceOver reads the whole ring as one item, with a percentage
        .accessibilityElement()
        .accessibilityLabel(isBreak ? "On break" : "Carrot \(Int(progress * 100)) percent grown")
    }
    // Picks the carrot image from progress: 4 growth stages, a quarter each. Night sky during a break.
    private var carrotImageName: String {
        if isBreak { return "nighttime" }
        
        switch progress {
        case ..<0.25: return "carrot_stage1"
        case ..<0.5:  return "carrot_stage2"
        case ..<0.75: return "carrot_stage3"
        default:      return "carrot_stage4"
        }
    }
}
