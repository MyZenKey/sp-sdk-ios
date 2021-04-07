![ZenKey](image/ZenKey_rgb.png "ZenKey")

# ZenKey SDKs and Web Integrations

ZenKey SDKs (iOS and Android) and web integrations provide effective resources for you as a service provider to authenticate users accessing your apps with their mobile device or web browser. There are several resources you can access to get started integrating ZenKey into your apps.

## Try It Out

1. Check out the SDK code for iOS and Android SDKs, as well as web integrations at https://github.com/myzenkey.
2. Build and test the [Example App](./Example/ZenKey-SDK-Example).
3. Learn the ZenKey flow by exploring the Developer Playground (https://playground.myzenkey.com/playground). You can submit requests to various endpoints and view the responses your users will experience.
4. Start coding! Visit http://developer.myzenkey.com for documentation (integration guides, references and best practices) and API resources including SDKs for iOS and Android and resources for Web integration.

## Features

- Developer Portal login - Setup your account as a service provider at http://portal.myzenkey.com
- ZenKey app - Find the Beta app links inside the Developer Portal
- Trust Services - A premium fraud prevention add-on or event alert subscription (see Developer Portal)

## Branching Strategy and Release Conventions

As the iOS SP SDK is imported as a `pod` by other ZenKey repositories, the process for releasing a new version involves several parts. Note: process will likely change as the JV dev team takes over fulltime development and maintenance, and this documentation should be updated as necessary to reflect current practices.

### Part 1 - Finalize develop branch
  1. Squash merge all feature PRs into local develop
  2. Update CHANGELOG (https://github.com/MyZenKey/sp-sdk-ios/blob/master/CHANGELOG.md) for release and commit PR: 
     - Make version link at top
     - Title unreleased section with version
     - Create new unreleased section from template
  3. Check for any updated dependencies (e.g. in Gemfile.lock)
  4. Run tests on develop!
  5. Update/build/test the example app(s) with the new SDK version: 
     - `pod update ZenKeySDK`
     - Run tests
  6. Clear publication with JV:
     - Push local develop branch to remote
     - Notify security team about doing a new scan Make any changes needed to pass scans 
     - Confirm JV approval for publication
  7. Squash merge develop PR into master (single commit in history for release)
  8. Run tests on master!
  9. Tag release on master branch

### Part 2 - Publish to Cocoapod trunk repo
  1. Get access to techsupport@myzenkey.com SalesForce account (either direct access or someone who has access and can approve the session below)
  2. Start a new session:
     - `$ pod spec lint ZenKeySDK.podspec`
     - `$ pod trunk register techsupport@myzenkey.com`
  3. Approve session and publish
     - Access techsupport@myzenkey.com email in JV SalesForce and follow instructions
     - Close the SalesForce ticket/case. (Assign yourself as owner in case anyone has questions) 
     - `$ pod trunk push ZenKeySDK.podspec`
  4. Test that BankApp pulls new version of public pod: 
     - `$ pod update`

### Part 3 - Notify and clean-up
  1. Work with documentation team to make sure that the integration guide has been updated to keep in sync with changes (doc changes should be queued up before release)
  2. Notify JV SP support so they can notify all subscribing SPs (should eventually be automated through portal)
  3. Bump version for next minimum release with fastlane script: fastlane bump
  4. Confirm changelog is prepped for next version as described above
 

## Feedback

Please report bugs or issues to our [support team](mailto:techsupport@myzenkey.com).

## History

View history of SDK versions and changes in the [Changelog](./CHANGELOG.md).

## License

NOTICE: © 2019-2020 ZENKEY, LLC. ZENKEY IS A TRADEMARK OF ZENKEY, LLC. ALL RIGHTS RESERVED. THE INFORMATION CONTAINED HEREIN IS NOT AN OFFER, COMMITMENT, REPRESENTATION OR WARRANTY AND IS SUBJECT TO CHANGE.
