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
    @Query(sort: \Swimmer.createdAt, order: .forward) private var swimmers: [Swimmer]
    @State private var showResetAlert = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let width = proxy.size.width
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
                        // Button to submit data
                        Button {
                            // the code to submit to database
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

                        // Reset ALL Swimmers
                        Button {
                            // Reset laps for all swimmers
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
    SettingsSheetView(dismiss: {})
}
