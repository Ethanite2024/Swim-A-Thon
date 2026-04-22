//
//  Animations.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 4/22/26.
//

import SwiftUI

// MARK: - Animated waves (Canvas + TimelineView for performance)

struct AnimatedWaves: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                // Light/mid blue palette with subtle, gradual animation.

                func oceanBlue(hueBase: CGFloat, sat: CGFloat, bri: CGFloat, opacity: CGFloat) -> Color {
                    Color(hue: Double(hueBase), saturation: Double(sat), brightness: Double(bri), opacity: Double(opacity))
                }

                // Very gentle modulation to keep it gradual and within range
                let satPulse = CGFloat(0.012 * sin(t * 0.22)) // ±0.012 saturation
                let briPulse = CGFloat(0.018 * sin(t * 0.16)) // ±0.018 brightness

                // Hue locked tightly around blue (very small wobble)
                let hueBlue: CGFloat = 0.60 + CGFloat(0.003 * sin(t * 0.10)) // ±0.003

                // Wave parameters
                let bob = sin(CGFloat(t) * 0.8) * 4 // slow vertical bob
                let baseY: CGFloat = size.height * 0.5 + bob

                let amplitude1: CGFloat = max(8, size.height * 0.10)
                let amplitude2: CGFloat = max(6, size.height * 0.07)
                let amplitude3: CGFloat = max(5, size.height * 0.05)

                let speed1: CGFloat = 0.6
                let speed2: CGFloat = 0.9
                let speed3: CGFloat = 0.35

                let wavelength1: CGFloat = max(120, size.width * 0.8)
                let wavelength2: CGFloat = max(90, size.width * 0.6)
                let wavelength3: CGFloat = max(150, size.width * 1.1)

                // Paths
                var path1 = Path()
                path1.move(to: CGPoint(x: 0, y: size.height))
                for x in stride(from: 0 as CGFloat, through: size.width, by: 2 as CGFloat) {
                    let angle = (x / wavelength1) * CGFloat.pi * 2 + CGFloat(t) * speed1
                    let y = baseY + sin(angle) * amplitude1
                    path1.addLine(to: CGPoint(x: x, y: y))
                }
                path1.addLine(to: CGPoint(x: size.width, y: size.height))
                path1.closeSubpath()

                var path2 = Path()
                path2.move(to: CGPoint(x: 0, y: size.height))
                for x in stride(from: 0 as CGFloat, through: size.width, by: 2 as CGFloat) {
                    let angle = (x / wavelength2) * CGFloat.pi * 2 - CGFloat(t) * speed2 + .pi / 6
                    let y = baseY + cos(angle) * amplitude2 + 8
                    path2.addLine(to: CGPoint(x: x, y: y))
                }
                path2.addLine(to: CGPoint(x: size.width, y: size.height))
                path2.closeSubpath()

                var path3 = Path()
                path3.move(to: CGPoint(x: 0, y: size.height))
                for x in stride(from: 0 as CGFloat, through: size.width, by: 2 as CGFloat) {
                    let angle = (x / wavelength3) * CGFloat.pi * 2 + CGFloat(t) * speed3 + .pi / 3
                    let y = baseY + sin(angle) * amplitude3 + 14
                    path3.addLine(to: CGPoint(x: x, y: y))
                }
                path3.addLine(to: CGPoint(x: size.width, y: size.height))
                path3.closeSubpath()

                // Light/mid blue variants only, with tight clamps
                let midBlue  = oceanBlue(
                    hueBase: hueBlue,
                    sat: min(0.76, max(0.62, 0.70 + satPulse)),
                    bri: min(0.80, max(0.66, 0.74 + briPulse)),
                    opacity: 0.26
                )
                let lightBlue = oceanBlue(
                    hueBase: hueBlue,
                    sat: min(0.68, max(0.52, 0.60 + satPulse)),
                    bri: min(0.90, max(0.74, 0.82 + briPulse)),
                    opacity: 0.21
                )
                let lighterBlue = oceanBlue(
                    hueBase: hueBlue,
                    sat: min(0.58, max(0.42, 0.50 + satPulse)),
                    bri: min(0.95, max(0.82, 0.90 + briPulse)),
                    opacity: 0.17
                )

                // Back to front layering (lightest in the back)
                context.fill(path3, with: .color(lighterBlue))
                context.fill(path2, with: .color(lightBlue))
                context.fill(path1, with: .color(midBlue))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Shimmer

struct ShimmerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("reduceLag") private var reduceLag: Bool = true
    @State private var phase: CGFloat = -1

    var body: some View {
        if reduceLag {
            EmptyView()
        } else {
            GeometryReader { proxy in
                let g = Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .white.opacity(0.35), location: 0.5),
                    .init(color: .clear, location: 1.0)
                ])
                LinearGradient(gradient: g, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .blendMode(.plusLighter)
                    .mask(
                        Rectangle()
                            .fill(
                                LinearGradient(colors: [.black.opacity(0), .black, .black.opacity(0)],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .offset(x: phase * proxy.size.width)
                    )
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                            phase = 2
                        }
                    }
            }
        }
    }
}

// MARK: - Particle Splash

struct ParticleSplashView: View {
    // Change id to retrigger animation
    var id: UUID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("reduceLag") private var reduceLag: Bool = true
    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var angle: CGFloat
        var speed: CGFloat
        var lifetime: Double
        var color: Color
        var scale: CGFloat
    }

    var body: some View {
        if reduceLag {
            EmptyView()
        } else {
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: 6 * p.scale, height: 6 * p.scale)
                        .modifier(ParticleMotion(angle: p.angle, speed: p.speed, lifetime: p.lifetime))
                }
            }
            // Updated to avoid iOS 17 deprecation while keeping iOS 16 compatibility
            .modifier(OnChangeCompat(value: id) {
                spawn()
            })
            .onAppear { spawn() }
        }
    }

    private func spawn() {
        guard !reduceMotion else { return }
        let count: Int = 14
        var newParticles: [Particle] = []
        newParticles.reserveCapacity(count)

        for i in 0..<count {
            let base: Double = Double(i) / Double(count) * .pi * 2
            let jitter: Double = Double.random(in: -0.3...0.3)
            let angle: CGFloat = CGFloat(base + jitter)

            let speed: CGFloat = CGFloat.random(in: 40...110)
            let lifetime: Double = Double.random(in: 0.6...1.0)
            let colorChoices: [Color] = [.blue, .teal, .cyan]
            let color: Color = colorChoices.randomElement()!.opacity(0.8)
            let scale: CGFloat = CGFloat.random(in: 0.7...1.4)

            let particle = Particle(angle: angle,
                                    speed: speed,
                                    lifetime: lifetime,
                                    color: color,
                                    scale: scale)
            newParticles.append(particle)
        }

        particles = newParticles

        // Clear after longest lifetime
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            particles.removeAll()
        }
    }
}

struct ParticleMotion: ViewModifier {
    var angle: CGFloat
    var speed: CGFloat
    var lifetime: Double

    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                let dx = cos(angle) * speed
                let dy = sin(angle) * speed
                withAnimation(.easeOut(duration: lifetime)) {
                    offset = CGSize(width: dx, height: dy)
                    opacity = 0.0
                }
            }
    }
}
