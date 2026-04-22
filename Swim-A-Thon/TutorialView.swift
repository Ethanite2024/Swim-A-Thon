//
//  TutorialView.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 4/22/26.
//

import SwiftUI

struct TutorialView: View {
    var dismiss: () -> Void
    @State private var page: Int = 0
    private let totalPages = 4
    @Binding var reduceLag: Bool

    var body: some View {
        TabView(selection: $page) {
            Group {
                tutorialPage(title: "Welcome to Swim-A-Thon!", text: "Keep track of how many laps each swimmer completes — all in one place. With Swim-A-Thon, you can add every swimmer by name and see their progress instantly, whether you’re running a team, a family event, or just competing with friends.", image: "person.3")
                    .tag(0)
                tutorialPage(title: "Add & Remove Swimmers", text: "Tap the field at the top to enter a new swimmer’s name, then tap Add. To remove a swimmer, swipe them or tap the trash button — you’ll always have a chance to undo in case of mistakes. This makes organizing your swim event easy and stress-free.", image: "plus.circle")
                    .tag(1)
                tutorialPage(title: "Track Laps & Distance", text: "Increase lap counts with +1 or +2 buttons, or hold a button for rapid counting. Remove Laps by tapping -1 for the swimmer. Instant feedback shows both total laps and distance in meters, so you’re always up to date. All changes happen in real time, with smooth animations and accessibility in mind.", image: "flag.checkered")
                    .tag(2)
                tutorialPage(title: "Beautiful Animations", text: "Enjoy lively, fluid animations like ocean waves, shimmer effects, and bursts of confetti every time a swimmer achieves more. Every effect respects Accessibility settings, so everyone can enjoy the experience comfortably.", image: "sparkles")
                    .tag(3)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Button("Skip") { dismiss() }
                .padding(20)
                .font(.headline)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 12) {
                Toggle("Performance Mode (Reduce Lag)", isOn: $reduceLag)
                    .padding(.horizontal, 24)
                    .font(.headline)
                HStack {
                    if page > 0 {
                        Button("Back") { withAnimation { page -= 1 } }
                    }
                    Spacer()
                    if page < totalPages - 1 {
                        Button("Next") { withAnimation { page += 1 } }
                    } else {
                        Button("Get Started") { dismiss() }
                            .bold()
                    }
                }
                .padding([.horizontal, .bottom], 24)
                .font(.headline)
            }
            .background(.ultraThinMaterial)
        }
    }
    func tutorialPage(title: String, text: String, image: String) -> some View {
        VStack(spacing: 30) {
            Spacer(minLength: 60)
            Image(systemName: image)
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .shadow(radius: 6)
            Text(title)
                .font(.largeTitle.bold())
            Text(text)
                .multilineTextAlignment(.center)
                .font(.title3)
                .padding(.horizontal, 24)
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}

