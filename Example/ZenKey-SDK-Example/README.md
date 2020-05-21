## The ZenKey SDK Example App

This ZenKey example app uses a simple programmatic UI to demonstrate how to integrate the ZenKey SDK for sign-in. Because of the secure nature of the ZenKey service, you will need to create real project credentials and use those to build the app and test with a real phone.

This basic integration of the ZenKey SDK matches the steps described in the [iOS Quick Start Guide](https://developer.myzenkey.com/ios-quickstart/).

Search for `// ZENKEY SDK` to find the integration steps in the example code.


## Set up

There are three steps to building and running the `ZenKey-SDK-Example` app to test a complete auth flow:

1. Configure a `client_id`.
2. Create a sample backend server.
3. Set the location of your sample backend server.

## 1. Configure a `client_id`

Create an account and project in the [ZenKey Developer Portal](https://portal.myzenkey.com).

When creating a project, the portal provides a default `redirect-uri`. To simplify ZenKey integration, keep this default value; the SDK uses the default for quick-start integration. You can always add or edit the URI at a later time. See the [iOS Integration Guide](https://developer.myzenkey.com/ios/) for details about using a custom `redirect-uri`.

Once your project receives approval, copy your `client_id` and secret from the ZenKey Developer Portal dashboard. You can start using the `client_id` after it is provisioned by the carriers. Using a non-provisioned `client_id` will cause errors in API responses.

Next, add your `client_id` to the `ZenKey-SDK-Example` app:
1. Select the `Info.plist`.
2. Replace the current value of "\<your-client-id\>" with your `client_id` in two places: in `ZenKeyClientId` and in `Item 0` under `URL Types`.
Afterwards, your `Info.plist` should resemble this sample:

   ![Example Info.plist](https://developer.myzenkey.com/static/plist_example-fee9d2c8f143c6588810064b768f6cd9.png)

## 2. Create a sample backend server

The `ZenKey-SDK-Example` app can only start the ZenKey authorization flow. For security, the final token request must be made from a secure server. To test the complete authorization flow, use the provided Python sample code to set up a server instance. In the instance, you set the ZenKey secret you got from the portal. The server sample code and instructions are here:
[API Backend Sample Repo](https://github.com/MyZenKey/sp-sdk-provider-integration-web/Examples/APIBackend).

Note: Never store the ZenKey secret in a public binary.

## 3. Set the location of the sample backend server

The `ZenKey-SDK-Example` app needs to know how to call the APIs in the server sample code. In the `Info.plist`'s `baseURL` key, replace "\<your-base-url\>" with the location of the sample backend server instance you created.

## Run the example app

You can run the example app on a real phone with a real SIM card to authorize a sign-in request; or you can use an iPad simulator to test a secondary-device flow, where you pair the device with a primary phone.

To test a carrier authorization request:
1. Launch the sample app and tap "Sign in with ZenKey".
2. The SDK Determines if it is running on a primary or secondary device and helps you install the ZenKey app for your carrier, if needed.
3. The SDK launches the ZenKey app which asks you to authorize your app.
4. The ZenKey app redirects you back to the example app with an `AuthorizedResponse` from the user's carrier.
5. The example app uses the `AuthorizedResponse` to request a sign-in from the sample server.
6. The sample server makes the token request and userInfo request to complete sign-in.

## Send us your feedback

Please report bugs or issues to our [support team](mailto:techsupport@myzenkey.com).

## View SDK version and history information

View history of SDK versions and changes in the [Changelog](../../CHANGELOG.md).

## License

NOTICE: © 2020 ZENKEY, LLC. ZENKEY IS A TRADEMARK OF ZENKEY, LLC. ALL RIGHTS RESERVED. THE INFORMATION CONTAINED HEREIN IS NOT AN OFFER, COMMITMENT, REPRESENTATION OR WARRANTY AND IS SUBJECT TO CHANGE.
