import SwiftUI

// Persist sign in state across the app using SwiftUI environment since both app launch and the sign in button can change the state
// There are other, perhaps better, ways to handle this but for this quick demo this was easiest

private struct IsSignedInKey: EnvironmentKey {
	static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var isSignedIn: Binding<Bool> {
        get { self[IsSignedInKey.self] }
        set { self[IsSignedInKey.self] = newValue }
    }
}
