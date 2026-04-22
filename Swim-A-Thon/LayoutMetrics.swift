//
//  LayoutMetrics.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 4/22/26.
//

import SwiftUI

// MARK: - Layout metrics

struct LayoutMetrics {
    // Baseline chosen around iPhone 13/14 portrait width ~390pt
    let width: CGFloat
    let scale: CGFloat

    // Derived tokens
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let vStackSpacing: CGFloat
    let hStackSpacing: CGFloat
    let rowVSpacing: CGFloat

    let cardPadding: CGFloat
    let cardCornerRadius: CGFloat

    let spacerMinLength: CGFloat

    // Fonts
    let baseFont: Font
    let titleFont: Font
    let lapsFont: Font
    let secondaryFont: Font
    let buttonFont: Font

    // Buttons
    let buttonHeight: CGFloat
    let primaryButtonStyle: ButtonStyleToken
    let secondaryButtonStyle: ButtonStyleToken
    let warningButtonStyle: ButtonStyleToken
    let dangerButtonStyle: ButtonStyleToken
    let buttonLabelStyle: AnyLabelStyle

    init(width: CGFloat) {
        self.width = width

        // Clamp scale for reasonable bounds (e.g., 320–1024)
        let clamped = max(320, min(width, 1024))
        self.scale = clamped / 390.0

        // Spacing/padding
        self.horizontalPadding = max(12, 16 * scale)
        self.verticalPadding = max(8, 12 * scale)
        self.vStackSpacing = max(8, 12 * scale)
        self.hStackSpacing = max(6, 8 * scale)
        self.rowVSpacing = max(6, 8 * scale)

        self.cardPadding = max(10, 14 * scale)
        self.cardCornerRadius = max(8, 12 * scale)

        self.spacerMinLength = max(8, 12 * scale)

        // Fonts
        self.baseFont = .system(size: max(14, 16 * scale))
        self.titleFont = .system(size: max(16, 18 * scale), weight: .semibold)
        self.lapsFont = .system(size: max(18, 22 * scale), weight: .semibold)
        self.secondaryFont = .system(size: max(12, 14 * scale))
        self.buttonFont = .system(size: max(12, 14 * scale), weight: .semibold)

        // Buttons
        self.buttonHeight = max(30, 36 * scale)

        // Style tokens (defer actual style application to a View extension)
        self.primaryButtonStyle = .borderedProminent(tint: nil)
        self.secondaryButtonStyle = .bordered(tint: nil)
        self.warningButtonStyle = .bordered(tint: .orange)
        self.dangerButtonStyle = .bordered(tint: .red)

        // Label style: icon-only when very compact
        if width < 350 {
            self.buttonLabelStyle = AnyLabelStyle(.iconOnly)
        } else {
            self.buttonLabelStyle = AnyLabelStyle(.titleAndIcon)
        }
    }
}
