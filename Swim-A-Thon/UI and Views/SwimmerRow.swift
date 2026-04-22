//
//  SwimmerRow.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 4/22/26.
//

import SwiftUI

// MARK: - Row
struct SwimmerRow: View {
    @Bindable var item: Swimmer
    let metersPerLap: Int
    let metrics: LayoutMetrics
    let onDeleteRequest: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("reduceLag") private var reduceLag: Bool = true

    @State private var pulse: Bool = false
    // NEW: particle splash trigger
    @State private var splashID: UUID = UUID()
    // NEW: invalid decrement shake
    @State private var shake: CGFloat = 0
    // NEW: reset confirmation alert
    @State private var showResetConfirmation: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.rowVSpacing) {
            HStack(alignment: .center, spacing: metrics.hStackSpacing) {
                Text(item.name)
                    .font(metrics.titleFont)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .accessibilityLabel("Swimmer \(item.name)")

                Spacer(minLength: metrics.spacerMinLength)

                Button(role: .destructive, action: onDeleteRequest) {
                    Label("Delete", systemImage: "trash")
                        .labelStyle(metrics.buttonLabelStyle)
                        .font(metrics.buttonFont)
                        .frame(minHeight: metrics.buttonHeight)
                }
                .apply(style: metrics.secondaryButtonStyle)
                .accessibilityLabel("Delete \(item.name)")
                .accessibilityHint("Double tap to confirm deletion")
            }

            HStack(spacing: metrics.hStackSpacing) {
                Text("🏁 Laps: \(item.laps)")
                    .font(metrics.lapsFont)
                    .bold()
                    .contentTransition(.numericText(value: Double(item.laps)))
                    .scaleEffect(pulse ? 1.05 : 1.0)
                    .opacity(pulse ? 0.95 : 1.0)
                    .animation(.spring(duration: 0.25, bounce: 0.4), value: pulse)
                    .onChange(of: item.laps) { _, _ in
                        // trigger a subtle pulse when laps change
                        pulse.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            pulse.toggle()
                        }
                    }
                    .accessibilityLabel("Laps")
                    .accessibilityValue("\(item.laps)")

                Spacer(minLength: metrics.spacerMinLength)

                Text("📏 \(item.laps * metersPerLap) meters")
                    .foregroundStyle(.secondary)
                    .font(metrics.secondaryFont)
                    .accessibilityLabel("Distance")
                    .accessibilityValue("\(item.laps * metersPerLap) meters")
            }
            .contextMenu {
                Button("+1 Lap") { increment(by: 1) }
                Button("+2 Laps") { increment(by: 2) }
                Button("-2 Laps") { decrement(by: 2) }
                if item.laps > 0 {
                    Button("-1 Lap") { decrement(by: 1) }
                    Button("Reset", role: .destructive) { showResetConfirmation = true }
                }
            }

            // Action buttons; allow wrapping on narrow widths
            FlexibleButtonsRow(metrics: metrics) {
                // +1 with press-and-hold repeat (delayed start)
                Button {
                    increment(by: 1)
                } label: {
                    Label("+1 Lap", systemImage: "plus.circle")
                        .labelStyle(metrics.buttonLabelStyle)
                        .font(metrics.buttonFont)
                        .frame(minHeight: metrics.buttonHeight)
                }
                .autoRepeat(onPressBegan: { increment(by: 1) },
                            onRepeat: { increment(by: 1) },
                            interval: 0.12)
                .apply(style: metrics.primaryButtonStyle)
                .accessibilityHint("Press and hold for 2 seconds to start repeating")

                Button {
                    increment(by: 2)
                } label: {
                    Label("+2 Laps", systemImage: "plus.circle.fill")
                        .labelStyle(metrics.buttonLabelStyle)
                        .font(metrics.buttonFont)
                        .frame(minHeight: metrics.buttonHeight)
                }
                .apply(style: metrics.primaryButtonStyle)

                Button {
                    decrement(by: 1)
                } label: {
                    Label("-1 Lap", systemImage: "minus.circle")
                        .labelStyle(metrics.buttonLabelStyle)
                        .font(metrics.buttonFont)
                        .frame(minHeight: metrics.buttonHeight)
                }
                .autoRepeat(onPressBegan: { decrement(by: 1) },
                            onRepeat: { decrement(by: 1) },
                            interval: 0.12)
                .apply(style: metrics.warningButtonStyle)

                Button {
                    decrement(by: 2)
                } label: {
                    Label("-2 Lap", systemImage: "minus.circle.fill")
                        .labelStyle(metrics.buttonLabelStyle)
                        .font(metrics.buttonFont)
                        .frame(minHeight: metrics.buttonHeight)
                }
                .apply(style: metrics.warningButtonStyle)

                Button {
                    showResetConfirmation = true
                } label: {
                    Label("Reset", systemImage: "arrow.clockwise")
                        .labelStyle(metrics.buttonLabelStyle)
                        .font(metrics.buttonFont)
                        .frame(minHeight: metrics.buttonHeight)
                }
                .apply(style: metrics.dangerButtonStyle)
            }
        }
        .padding(metrics.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: metrics.cardCornerRadius)
                .fill(Color(.secondarySystemBackground))
        )
        // NEW: shake on invalid decrement
        .offset(x: shake)
        .animation(.default, value: shake)
        // NEW: overlay confetti splash when laps increase
        .overlay {
            if !reduceLag {
                ParticleSplashView(id: splashID)
                    .allowsHitTesting(false)
            }
        }
        .alert("Reset laps for \(item.name)?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) { reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will set \(item.name)'s lap count to zero.")
        }
    }

    // MARK: - Mutations

    @MainActor
    private func increment(by value: Int) {
        let old = item.laps
        item.laps += value
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // trigger particles only when we actually increase
        if item.laps > old {
            splashID = UUID()
        }
    }

    @MainActor
    private func decrement(by value: Int) {
        if item.laps >= value {
            item.laps -= value
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } else {
            // invalid: shake
            guard !reduceMotion else { return }
            let sequence: [CGFloat] = [0, -8, 8, -6, 6, -3, 3, 0]
            for (i, x) in sequence.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02 * Double(i)) {
                    shake = x
                }
            }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    @MainActor
    private func reset() {
        item.laps = 0
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

