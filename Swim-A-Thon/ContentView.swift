//
//  ContentView.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 6/24/25.
//

import SwiftUI
import SwiftData
import Combine

struct LapCounterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.createdAt, order: .forward) private var items: [Item]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var newSwimmerName: String = ""
    @State private var nameHelper: String? = nil
    @FocusState private var isNameFieldFocused: Bool

    @State private var pendingDeletion: Item? = nil
    @State private var showUndoBanner: Bool = false
    @State private var lastDeleted: (name: String, laps: Int)? = nil

    // NEW: Add button animation state
    @State private var addButtonEnabled: Bool = false
    @State private var addButtonGlow: Bool = false

    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @State private var showTutorial: Bool = false
    
    @AppStorage("reduceLag") private var reduceLag: Bool = true

    private let metersPerLap = 25

    var body: some View {
        GeometryReader { proxy in
            let metrics = LayoutMetrics(width: proxy.size.width)

            ZStack(alignment: .bottom) {
                // Content
                ScrollView {
                    VStack(spacing: metrics.vStackSpacing) {
                        addSwimmerBar(metrics: metrics)

                        if items.isEmpty {
                            EmptyState(metrics: metrics)
                                .padding(.horizontal, metrics.horizontalPadding)
                                .padding(.top, 24)
                                // NEW: gentle appear transition
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            ForEach(items, id: \.id) { item in
                                SwimmerRow(
                                    item: item,
                                    metersPerLap: metersPerLap,
                                    metrics: metrics,
                                    onDeleteRequest: { pendingDeletion = item }
                                )
                                .padding(.horizontal, metrics.horizontalPadding)
                                // NEW: row appear/disappear transitions
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        }
                    }
                    // Apply only top padding to avoid lifting content above the waves
                    .padding(.top, metrics.verticalPadding)
                }
                .scrollDismissesKeyboard(.interactively)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { isNameFieldFocused = false }
                            .keyboardShortcut(.escape, modifiers: [])
                    }
                }
                .onTapGesture { isNameFieldFocused = false }
                .alert("Delete swimmer?", isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                )) {
                    Button("Delete", role: .destructive) { confirmDelete() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    if let item = pendingDeletion {
                        Text("This will remove \(item.name) and their lap count.")
                    }
                }
                .overlay(alignment: .bottom) {
                    if showUndoBanner, let lastDeleted {
                        UndoBanner(name: lastDeleted.name, laps: lastDeleted.laps, metrics: metrics) {
                            undoDelete()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                    }
                }
                .animation(reduceMotion ? .default : .spring(response: 0.45, dampingFraction: 0.9), value: items)
                .animation(.snappy, value: showUndoBanner)
                .onAppear {
                    if !hasSeenTutorial {
                        showTutorial = true
                    }
                }
                // Tutorial full screen cover overlay
                .fullScreenCover(isPresented: $showTutorial) {
                    TutorialView(dismiss: {
                        hasSeenTutorial = true
                        showTutorial = false
                    }, reduceLag: $reduceLag)
                }

                // Decorative animated waves at the bottom
                if !reduceLag {
                    AnimatedWaves()
                        // Make the waves a bit taller so they can extend under the safe area
                        .frame(height: max(210, 260 * metrics.scale))
                        // Allow drawing under the home indicator/safe area
                        .ignoresSafeArea(edges: .bottom)
                        // Pull the waves down slightly to visually continue beyond the bottom edge
                        .padding(.bottom, -100)
                        // NEW: subtle parallax based on scroll position (approx using geometry)
                        .offset(y: reduceMotion ? 0 : -min(20, proxy.safeAreaInsets.bottom / 2))
                        // NEW: dim slightly in dark mode
                        .opacity(colorScheme == .dark ? 0.9 : 1.0)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    // MARK: - Add swimmer UI

    private func addSwimmerBar(metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: metrics.hStackSpacing) {
                TextField("New swimmer name", text: $newSwimmerName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .font(metrics.baseFont)
                    .onChange(of: newSwimmerName) { _, _ in
                        validateName()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            addButtonEnabled = canAddName
                        }
                    }
                    .onSubmit {
                        addItem()
                    }
                    .accessibilityLabel("New swimmer name")
                    .accessibilityHint("Type a name and press Add")
                    // NEW: slight highlight sweep when first focused
                    .overlay(alignment: .trailing) {
                        if isNameFieldFocused && !reduceMotion && !reduceLag {
                            ShimmerView()
                                .frame(width: 60, height: 24)
                                .offset(x: 10)
                                .transition(.opacity)
                        }
                    }

                Button {
                    addItem()
                } label: {
                    Label("Add", systemImage: "person.badge.plus")
                        .labelStyle(metrics.buttonLabelStyle)
                        .font(metrics.buttonFont)
                        .frame(minHeight: metrics.buttonHeight)
                        .contentShape(Rectangle())
                }
                .apply(style: metrics.primaryButtonStyle)
                .disabled(!canAddName)
                // NEW: spring pop when becomes enabled
                .scaleEffect(addButtonEnabled ? 1.0 : 0.96)
                .animation(.spring(response: 0.28, dampingFraction: 0.8), value: addButtonEnabled)
                // NEW: pulsing glow when enabled and field has text
                .shadow(color: (addButtonEnabled && !reduceMotion) ? .blue.opacity(addButtonGlow ? 0.6 : 0.2) : .clear,
                        radius: addButtonGlow ? 10 : 4,
                        x: 0, y: 0)
                .onChange(of: addButtonEnabled) { _, enabled in
                    guard !reduceMotion else { return }
                    if enabled {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            addButtonGlow = true
                        }
                    } else {
                        addButtonGlow = false
                    }
                }
                .accessibilityHint(canAddName ? "Adds a new swimmer" : (nameHelper ?? "Enter a unique name"))
            }

            if let helper = nameHelper, !helper.isEmpty {
                Text(helper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .accessibilityLabel(helper)
            }
        }
        .padding(.horizontal, metrics.horizontalPadding)
    }

    private var canAddName: Bool {
        let name = newSwimmerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        return !items.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })
    }

    private func validateName() {
        let name = newSwimmerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            nameHelper = nil
        } else if items.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            nameHelper = "A swimmer with this name already exists."
        } else {
            nameHelper = nil
        }
    }

    // MARK: - Database helpers (SwiftData)

    @MainActor
    private func addItem() {
        let name = newSwimmerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            isNameFieldFocused = false
            return
        }
        guard !items.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            nameHelper = "A swimmer with this name already exists."
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            modelContext.insert(Item(name: name, laps: 0))
        }
        newSwimmerName = ""
        isNameFieldFocused = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @MainActor
    private func confirmDelete() {
        guard let item = pendingDeletion else { return }
        lastDeleted = (name: item.name, laps: item.laps)
        withAnimation(.easeInOut(duration: 0.25)) {
            modelContext.delete(item)
        }
        pendingDeletion = nil
        showUndoBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showUndoBanner = false }
            lastDeleted = nil
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    @MainActor
    private func undoDelete() {
        guard let lastDeleted else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            modelContext.insert(Item(name: lastDeleted.name, laps: lastDeleted.laps))
        }
        self.lastDeleted = nil
        withAnimation { showUndoBanner = false }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

// MARK: - Row

private struct SwimmerRow: View {
    @Bindable var item: Item
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

// MARK: - Empty state

private struct EmptyState: View {
    let metrics: LayoutMetrics
    @State private var bob: Bool = false
    @State private var shimmer: Bool = false
    @AppStorage("reduceLag") private var reduceLag: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .offset(y: bob ? -4 : 4)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: bob)
                .onAppear { bob = true }
                // NEW: parallax tilt
                .rotation3DEffect(.degrees(bob ? 2 : -2), axis: (x: 0, y: 1, z: 0))
            Text("No swimmers yet")
                .font(metrics.titleFont)
                .overlay {
                    // NEW: gentle shimmer sweep
                    if !reduceLag {
                        ShimmerView()
                            .opacity(shimmer ? 0.35 : 0)
                            .allowsHitTesting(false)
                    }
                }
            Text("Add a swimmer above to start tracking laps.")
                .font(metrics.secondaryFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: metrics.cardCornerRadius)
                .fill(Color(.tertiarySystemBackground))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).delay(0.4).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Undo banner

private struct UndoBanner: View {
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

// MARK: - Layout metrics

private struct LayoutMetrics {
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

// MARK: - Button style token and application

private enum ButtonStyleToken {
    case borderedProminent(tint: Color?)
    case bordered(tint: Color?)
}

private extension View {
    @ViewBuilder
    func apply(style token: ButtonStyleToken) -> some View {
        switch token {
        case .borderedProminent(let tint):
            if let tint {
                self.buttonStyle(.borderedProminent).tint(tint)
            } else {
                self.buttonStyle(.borderedProminent)
            }
        case .bordered(let tint):
            if let tint {
                self.buttonStyle(.bordered).tint(tint)
            } else {
                self.buttonStyle(.bordered)
            }
        }
    }

    // Auto-repeat using DragGesture with reliable delayed start/stop
    func autoRepeat(onPressBegan: @escaping () -> Void,
                    onRepeat: @escaping () -> Void,
                    interval: TimeInterval) -> some View {
        modifier(AutoRepeatModifier(onPressBegan: onPressBegan,
                                    onRepeat: onRepeat,
                                    interval: interval))
    }
}

// MARK: - Label style wrapper

private struct AnyLabelStyle: LabelStyle {
    enum Kind {
        case iconOnly
        case titleAndIcon
    }

    let kind: Kind

    init(_ kind: Kind) {
        self.kind = kind
    }

    func makeBody(configuration: Configuration) -> some View {
        switch kind {
        case .iconOnly:
            configuration.icon
        case .titleAndIcon:
            HStack(spacing: 6) {
                configuration.icon
                configuration.title
            }
        }
    }
}

// MARK: - Flexible buttons row (wraps on narrow widths)

private struct FlexibleButtonsRow<Content: View>: View {
    let metrics: LayoutMetrics
    @ViewBuilder let content: () -> Content

    var body: some View {
        let minButtonWidth = max(110, 120 * metrics.scale)

        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: minButtonWidth), spacing: metrics.hStackSpacing)
            ],
            spacing: metrics.hStackSpacing
        ) {
            content()
        }
    }
}

// MARK: - Auto-repeat modifier using DragGesture (2s delayed start)

private struct AutoRepeatModifier: ViewModifier {
    @State private var delayTimer: Timer?
    @State private var repeatTimer: Timer?
    let onPressBegan: () -> Void
    let onRepeat: () -> Void
    let interval: TimeInterval
    private let delay: TimeInterval = 2.0

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        // Start the 2-second delay timer once on initial press
                        if delayTimer == nil && repeatTimer == nil {
                            startDelayTimer()
                        }
                    }
                    .onEnded { _ in
                        stopAllTimers()
                    }
            )
            .onDisappear {
                stopAllTimers()
            }
    }

    private func startDelayTimer() {
        stopAllTimers()
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            onPressBegan()
            startRepeatTimer()
        }
        delayTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func startRepeatTimer() {
        repeatTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: max(0.05, interval), repeats: true) { _ in
            onRepeat()
        }
        repeatTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopAllTimers() {
        delayTimer?.invalidate()
        repeatTimer?.invalidate()
        delayTimer = nil
        repeatTimer = nil
    }
}

// MARK: - Animated waves (Canvas + TimelineView for performance)

private struct AnimatedWaves: View {
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

private struct ShimmerView: View {
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

private struct ParticleSplashView: View {
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

private struct ParticleMotion: ViewModifier {
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

// A small compatibility modifier to bridge onChange API differences across iOS 16/17.
private struct OnChangeCompat<Value: Equatable>: ViewModifier {
    let value: Value
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: value, action)
        } else {
            content.onChange(of: value) { _ in action() }
        }
    }
}

private struct TutorialView: View {
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

#Preview {
    LapCounterView()
        .modelContainer(for: Item.self, inMemory: true)
}

