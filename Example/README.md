
# Example Apps

There are several example apps which demonstrate different pieces of project verify functionality. These flows demonstrate how to make a request for a set of scopes from Project Verify and demonstrate how that information might be transported back to your server. These flows mock and simplify the server contract, which will ultimately be up to you to implement. For guidance on how to implement Project Verify on the server, see the [Project Verify Web Integration Guidelines]().

## SocialApp (iOS)

This app simulates a social network. It demonstrates:
- Signing in with Project Verify.
- Signing up with Project Verify.
- How to use the ProjectVerifyAuthorizeButton.

A social network might leverage Project Verify to make registration and login easier for the user. The sign up / sign in flow is comprised of the social network requesting the necessary scopes from Project Verify. The social app receives an authorization code and mcc/mnc identifer from Project Verify. It passes this back to the mock social app server where the assumption would be that the token exchange is completed. Once the server has an a token, it can access the user info endpoint for the information authorized in the scopes.

## BankApp (iOS)

This app simulates a banking app. It demonstrates:
- How to link Project Verify to an existing user account.
- How to use Project Verify as a second factor to authorize a transaction.

A bank or financial institution might leverage Project Verify to provide a second factor for large or risky transactions. The authorization flow demonstrates how to request the second factor scope to authorize a money transfer. The bank app receives an authorization code and mcc/mnc identifer from Project Verify. It passes this back to the mock bank app server where the assumption would be that the token exchange is completed. Once the server has an a token, it can proceed with the transaction with the knowledge that the user has provided the second factor authorization.

## PhotoApp (iOS)

This app simulates a commerce app. It demonstrates:
- How to use Project Verify to fill out a form.
- How to configure custom redirect URLs.

An e-commerce app might leverage Project Verify to retrieve user information from a trusted source before the user has created a profile. The social app demonstrates how to authorize the required scopes to complete a form. The photo app receives an authorization code and mcc/mnc identifer from Project Verify. It passes this back to the mock photo app server where the assumption would be that the token exchange is completed. Once the server has an a token,it can access the user info endpoint for the information authorized in the scopes.

## Branding Guidelines (iOS)

This app has some simple UI to showcase Project Verify branding guidelines. It demonstrates how to layout the branded buttons using different UI paradigms.

## TV App (tvOS)

TODO: -