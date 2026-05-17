//
//  SettingsSheetView.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 4/23/26.
//

import SwiftUI
import SwiftData
import Combine

struct SettingsSheetView: View {
    var dismiss: () -> Void
    var presentSendToSheets: () -> Void
    @AppStorage("selectedLane") var selectedLane: Int = 0
    @Query(sort: \Swimmer.createdAt, order: .forward) private var swimmers: [Swimmer]
    @State private var showResetAlert = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let rawWidth = proxy.size.width
                let width = rawWidth > 0 ? rawWidth : 375.0  // Guard against zero/negative on first layout pass
                let isRegular = (horizontalSizeClass == .regular) || width >= 700
                let scale = min(max(width / 375.0, 0.9), 1.6)
                let baseHeight: CGFloat = isRegular ? 56 : 48
                let buttonHeight = min(max(baseHeight * CGFloat(scale), 44), 72)
                let fontSize = min(max(CGFloat(17) * CGFloat(scale), 16), 28)
                let cornerRadius = isRegular ? 14.0 : 10.0
                let maxContentWidth = min(width - 32, isRegular ? 900 : 500)
                let contentPadding: CGFloat = isRegular ? 24 : 16
                let spacing: CGFloat = isRegular ? 24 : 20
                let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: isRegular ? 2 : 1)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        LaneSelecter().padding()
                        Button {
                            dismiss()
                            presentSendToSheets()
                        } label: {
                            Text("Submit Swimmer Lap Counts")
                                .font(.system(size: fontSize, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: buttonHeight)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)

                        Button {
                            for swimmer in swimmers {
                                swimmer.laps = 0
                            }
                        } label: {
                            Text("Reset All Swimmers")
                                .font(.system(size: fontSize, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: buttonHeight)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)

                        Button {
                            dismiss()
                            presentSendToSheets()
                        } label: {
                            Text("Send Swimmer Data Method: Google")
                                .font(.system(size: fontSize, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: buttonHeight)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white).disabled(selectedLane < 1 || selectedLane > 13)
                    }
                    .frame(maxWidth: maxContentWidth)
                    .padding(contentPadding)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsSheetView(dismiss: {}, presentSendToSheets: {})
}
