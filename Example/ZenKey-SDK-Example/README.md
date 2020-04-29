## ZenKey SDK Example App

This example app demonstrates a basic programmatic integration of the ZenKey SDK. For security, you must create a real `client_id` before testing the ZenKey sign-in flow, and you must run the app on a real phone with a real SIM card to authorize a request. You can target an iPad simulator to test a secondary-device flow, but will still need your carrier's ZenKey app installed on a real phone.

Follow along with the steps in the ios-quickstart guide:
<https://developer.myzenkey.com/ios-quickstart/>

### What does the Example App do?

This example presents a simple sign-in UX. Once you have configured your `client_id`, tapping on the "Sign in with ZenKey" button will begin a basic sign-in flow. The SDK will resolve whether the user is on their primary device or secondary device and help them install the ZenKey app for their carrier, if needed. Finally they will be prompted to authorize your app within the ZenKey app and redirected back to the example app with an `AuthorizedResponse` from the user's carrier. The `AuthorizedResponse` will include all the parameters you will need to pass to your secure backend—`code`, `mccmnc`, `redirectURI`, and `codeVerifier`—in order to issue a final token request and complete the authentication flow.

## Overview

Although you should be able to build `ZenKey-SDK-Example.xcworkspace` immediately, you will see errors until you assign real project credentials for a secure exchange. There are three steps to set-up for a full auth flow:

1. Configure Your `client_id`
2. Set Up Sample Backend
3. Configure Your `baseURL`

## 1. Configure Your `client_id `

You will need to create an account and project in the ZenKey Developer Portal:
<https://portal.myzenkey.com>

When creating a project, the portal will recommend a default `redirect-uri`. For the simplest integration, it is recommended that you keep this default value, as the SDK expects it to be available for the quick-start integration. You can always add or edit other URIs later.

Once your project has been approved, copy your `client_id` and secret from the ZenKey Developer Portal dashboard. You will be notified when your `client_id` has been provisioned and is ready for use. Requests will fail if the `client_id` is not yet provisioned.

Next, you will need to add your `client_id` to the `ZenKey-SDK-Example` app. Select the `Info.plist` and replace the current value of "\<your-client-id\>" with your `client_id`. This occurs in two places: in `ZenKeyClientId` and `Item 0` under `URL Types`. Once complete, your `Info.plist` should resemble the sample shown here:

![Example Info.plist](https://developer.myzenkey.com/static/plist_example-fee9d2c8f143c6588810064b768f6cd9.png)

## Configure Your `redirect-uri` (Optional)

If you are not using the default `redirect-uri` for this `client_id` (provided by the portal) please consult the integration guide to set up a custom `redirect-uri` (a Universal Link requires setting up proof of ownership with Apple):
<https://developer.myzenkey.com/ios/>

## 2. Set Up Sample Backend

The `ZenKey-SDK-Example` app can only begin a ZenKey auth flow. For security, the final token request must be done on a secure server. For you to test the complete round-trip, we also provide backend sample code to set up an instance of the APIs used by the sample app. It is in this backend instance that you will set the ZenKey secret you got from the portal (the secret should never be stored in a public binary). Find the backend sample code and instructions here:
<https://github.com/MyZenKey/sp-sdk-provider-integration-web/Examples/APIBackend>

## 3. Configure Your `baseURL`

Finally, the `ZenKey-SDK-Example` app needs to know how to call the APIs you just set up. In the `Info.plist`'s `baseURL` key, replace "\<your-base-url\>" with the location of the sample backend instance you created.

## Completion

Now you can build and run the `ZenKey-SDK-Example` app on a test device. Tapping on the "Sign in with ZenKey" button will let the SDK begin a carrier auth request, which will provide an auth-code which is used to sign in to the sample backend service.

## Feedback

Please report bugs or issues to our [support team](mailto:techsupport@myzenkey.com).

## History

View history of SDK versions and changes in the [Changelog](../../CHANGELOG.md).

## License

Copyright © 2020 ZenKey, LLC.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

NOTICE: © 2020 ZenKey, LLC. ZENKEY IS A TRADEMARK OF ZenKey, LLC. ALL RIGHTS RESERVED. THE INFORMATION CONTAINED HEREIN IS NOT AN OFFER, COMMITMENT, REPRESENTATION OR WARRANTY AND IS SUBJECT TO CHANGE
