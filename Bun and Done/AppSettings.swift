//
//  AppSettings.swift
//  Bun and Done
//
//  Created by Clare Ahn on 3/11/2026.
//


import Foundation
import SwiftData

@Model
final class AppSettings {
    var focusLength: Int
    var breakLength: Int
    var notifySessionEnds: Bool

    init(
        focusLength: Int = 25,
        breakLength: Int = 5,
        notifySessionEnds: Bool = true,
    ) {
        self.focusLength = focusLength
        self.breakLength = breakLength
        self.notifySessionEnds = notifySessionEnds
    }
}
