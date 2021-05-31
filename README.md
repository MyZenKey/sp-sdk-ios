![ZenKey](image/ZenKey_rgb.png "ZenKey")

# ZenKey SDKs and Web Integrations

ZenKey SDKs (iOS and Android) and web integrations provide effective resources for you as a service provider to authenticate users accessing your apps with their mobile device or web browser. There are several resources you can access to get started integrating ZenKey into your apps.

## Try It Out

1. Check out the SDK code for iOS and Android SDKs, as well as web integrations at https://github.com/myzenkey.
2. Build and test the [Example App](./Example/ZenKey-SDK-Example).
3. Learn the ZenKey flow by exploring the Developer Playground (https://playground.myzenkey.com/playground). You can submit requests to various endpoints and view the responses your users will experience.
4. Start coding! Visit http://developer.myzenkey.com for documentation (integration guides, references and best practices) and API resources including SDKs for iOS and Android and resources for Web integration.

## Government ID

By default the ZenKey SDK is setup to handle non-premium scopes.  So if you are already an SDK user, and have no plans to support premium scopes, everything still works as is.  No changes needed in your project.

Otherwise, use the ***scopes*** property on **ZenKeyAuthorizeButton** to set a fixed array of supported scopes.  To adopt premium scopes, like government ID, assign an *empty array* of scopes.  In this state, supported scopes will be fetched at launch.

## Features

- Developer Portal login - Setup your account as a service provider at http://portal.myzenkey.com
- ZenKey app - Find the Beta app links inside the Developer Portal
- Trust Services - A premium fraud prevention add-on or event alert subscription (see Developer Portal)

## Feedback

Please report bugs or issues to our [support team](mailto:techsupport@myzenkey.com).

## History

View history of SDK versions and changes in the [Changelog](./CHANGELOG.md).

## License

NOTICE: © 2019-2020 ZENKEY, LLC. ZENKEY IS A TRADEMARK OF ZENKEY, LLC. ALL RIGHTS RESERVED. THE INFORMATION CONTAINED HEREIN IS NOT AN OFFER, COMMITMENT, REPRESENTATION OR WARRANTY AND IS SUBJECT TO CHANGE.
