//
//  UndoBanner.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 4/22/26.
//

import SwiftUI

// MARK: - Undo banner

struct UndoBanner: View {
    let name: String
    let laps: Int
    let metrics: LayoutMetrics
    let onUndo: () -> Void

    @State private var progress: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.2), lineWidth: 4)
                    .frame(width: 28, height: 28)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 28, height: 28)
                    .animation(.linear(duration: 3), value: progress)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Deleted \(name)")
                    .font(metrics.titleFont)
                Text("Lap count was \(laps)")
                    .font(metrics.secondaryFont)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Undo", action: onUndo)
                .apply(style: .borderedProminent(tint: nil))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal, 16)
        .onAppear {
            guard !reduceMotion else { return }
            progress = 1.0
            // animate to 0 over 3 seconds to match dismissal delay
            DispatchQueue.main.async {
                progress = 0.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to restore")
    }
}


