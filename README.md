# XCI-Provider SDK
[![CircleCI](https://circleci.com/gh/Raizlabs/XCI-ProviderSDK-iOS/tree/develop.svg?style=svg&circle-token=0170863b5ec5b1ec6f14c3980c1f4e6e269f2adf)](https://circleci.com/gh/Raizlabs/XCI-ProviderSDK-iOS/tree/develop)


# Installation

There are 3 supported ways to integrate ProjectVerify and its dependency `AppAuth` to your project.

### Dependencies

This SDK current relies on *AppAuth* as an Open Id Connect client.
For more information about AppAuth, visit the repository [here](https://github.com/openid/AppAuth-iOS).

## CocoaPods

// TODO

## Carthage

// TODO:

## Manual

// TODO:

# Integration

## Configure your Info.plist

Retrieve your application's client id from the project verify dashboard.
Add the following keys to your application's Info.plist:

```xml
	<key>ProjectVerifyClientId</key>
	<string>{your application's client id}</string>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>{your bundle id}</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>{your application's client id}</string>
			</array>
		</dict>
	</array>
```

## Instantiate Project Verify in your Application Delegate:

First you must configure your application delegate to support project verify:

```swift
import CarriersSharedAPI

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        ProjectVerifyAppDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        // Perform additional application setup.

        return true
    }

    func application(_ app: UIApplication,
                    open url: URL,
                    options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {

        guard !ProjectVerifyAppDelegate.shared.application(app, open: url, options: options) else {
            return true
        }
        // Perform any other URL processing your app may need to perform. 
    }
}
```

## Perform An Authorization Request:

Once your Application Delegate is configured, use the `AuthorizationService` to request an authorization
code. Pass the code and associated identifiers to your secure server to complete the token request flow.

```swift
import CarriersSharedAPI

class LoginViewController {

    let authService = AuthorizationService()
    
    func loginWithProjectVerify() {
        // in response to some UI, perform an authorization using the AuthorizationService
        let scopes: [Scope] = [.profile, .email]
        authService.connectWithProjectVerify(
            scopes: scopes,
            fromViewController: self) { result in

            let appDelegate = UIApplication.shared.delegate! as! AppDelegate
            switch result {
            case .code(let authorizedResponse):
                let code = authorizedResponse.code
                let mcc = authorizedResponse.mcc
                let mnc = authorizedResponse.mnc
                // Pass these identifiers to your secure server to perform a token request
            case .error:
                // handle the error case appropriately
            case .cancelled:
                // perform any work required when the user cancels
            }
        }
    }
}
```


