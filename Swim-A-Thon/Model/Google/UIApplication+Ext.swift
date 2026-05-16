import UIKit

extension UIApplication {
	// Google sign in needs a view controller to present from, so we need this extension to make it work with SwiftUI where we don't have access to the view controllers
	func getTopViewController() -> UIViewController? {
		var topController = connectedScenes
			.filter { $0.activationState == .foregroundActive }
			.map { $0 as? UIWindowScene }
			.compactMap { $0 }
			.first?
			.windows
			.filter { $0.isKeyWindow }
			.first?
			.rootViewController
		
		// ensures any presented views will be treated as 'top-most' viewController
		while let presentedViewController = topController?.presentedViewController {
			topController = presentedViewController
		}
		
		return topController
	}
}
