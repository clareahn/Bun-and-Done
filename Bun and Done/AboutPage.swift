//
//  AboutPage.swift
//  Bun and Done
//
//  Created by Clare Ahn on 10/11/2026.
//

import SwiftUI

struct AboutPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Bun & Done")
                    .font(.title.bold())

                Text("A productivity app that combines a task list with a Pomodoro-style focus timer. Each completed focus session grows a carrot.")

                Text("Developer")
                    .font(.headline)
                Text("Clare Ahn\nStudent ID: 33890560\nFIT3178 iOS App Development")

                Text("Acknowledgements")
                    .font(.headline)
                Text("• Background sounds from the Freesound API (freesound.org), using Creative Commons 0 sounds\n• Built with SwiftUI, SwiftData, AVFoundation and UserNotifications\n• Icons from SF Symbols\n• Night sky artwork designed by me in Figma\n• Claude (Anthropic) was used to design carrot artwork, explain concepts and review code architecture\n• FIT3178 lecture and lab materials, and Apple Developer Documentation")
            }
            .foregroundStyle(Color.primaryText)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutPage()
    }
}
