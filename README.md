# XCI-Provider SDK
[![CircleCI](https://circleci.com/gh/Raizlabs/XCI-ProviderSDK-iOS/tree/develop.svg?style=svg&circle-token=0170863b5ec5b1ec6f14c3980c1f4e6e269f2adf)](https://circleci.com/gh/Raizlabs/XCI-ProviderSDK-iOS/tree/develop)

⚠️ This software is pre-release! This integration process and the SDK's interface are subject to change.

# Installation

There are three supported ways to integrate ProjectVerify and its dependency `AppAuth` to your project.

### Dependencies

This SDK current relies on *AppAuth* as an Open Id Connect client.
For more information about AppAuth, visit the repository [here](https://github.com/openid/AppAuth-iOS).

## Pre-Release Git Access

⚠️ *these are pre-release integration steps and will change*

While the SDK is under development, we recommend maintaining the Provider SDK source code as a [git submodule][submodules]. If for some reason that is not possible, download the source [here][projectVerifyLogin] and place it in your project directory.

```bash
git submodule add https://github.com/Raizlabs/XCI-ProviderSDK-iOS
```

## CocoaPods

⚠️ *these are pre-release integration steps and will change*

During development, include the ProjectVerifyLogin SDK in your project as a development Cocoapod. Once you've placed the source code in your repository, add the following to your Podfile.

```ruby
  pod 'CarriersSharedAPI', path: '{your-relative-path}/CarriersSharedAPI.podspec'
```

Then run `pod install`. This will add the local source as well as `AppAuth` to your application's workspace.

## Carthage

⚠️️ *Carthage will be supported in the future.*

## Manual

These steps outline how to add ProjectVerifyLogin SDK to your project manually. For an example of a project which links ProjectVerifyLogin manually, see the example [SocialApp](https://github.com/Raizlabs/XCI-ProviderSDK-iOS/tree/develop/Example/SocialApp).

- Begin by retrieving the source for both `ProjectVerifyLogin` and its dependency `AppAuth`. The recommended way to do this is by adding them both as [git submodules][submodules]:

```bash
git submodule add https://github.com/Raizlabs/XCI-ProviderSDK-iOS
git submodule add https://github.com/openid/AppAuth-iOS
```
If it is not possible to use git submodules for some reason, download the source from the respective locations.

- Once you've added the source via submodule or manually, add both `CarriersSharedAPI.xcodeproj` and `AppAuth.xcodeproj` to your application's XCode project.

- Having added the two projects, confirm that their deployment targets match your application's deployment target.

- Next, view your project's `Embedded Binaries` under your project's "General" panel. Add both `AppAuth` and `CarriersSharedAPI` frameworks here. Be sure to select the corresponding framework for the platform your targeting (ie. the iOS framework for an iOS target).

- That's it! Build and run to ensure everything is working correctly.

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

[submodules]: https://git-scm.com/docs/git-submodule
[projectVerifyLogin]: https://github.com/Raizlabs/XCI-ProviderSDK-iOS
[appAuth]: https://github.com/openid/AppAuth-iOS
