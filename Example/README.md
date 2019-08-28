
# Example Apps

There are several example apps which demonstrate different pieces of ZenKey functionality. These flows demonstrate how to make a request for a set of scopes from ZenKey and demonstrate how that information might be transported back to your server. These flows mock and simplify the server contract, which will ultimately be up to you to implement. For guidance on how to implement ZenKey on the server, see the [ZenKey Web Integration Guidelines]().

## BankApp (iOS)

This app simulates a banking app. It demonstrates:
- How to link ZenKey to an existing user account.
- How to use ZenKey as a second factor to authorize a transaction.

A bank or financial institution might leverage ZenKey to provide a second factor for large or risky transactions. The authorization flow demonstrates how to request the second factor scope to authorize a money transfer. The bank app receives an authorization code and mcc/mnc identifer from ZenKey. It passes this back to the mock bank app server where the assumption would be that the token exchange is completed. Once the server has a token, it can proceed with the transaction with the knowledge that the user has provided the second factor authorization.

## Branding Guidelines (iOS)

This app has some simple UI to showcase ZenKey branding guidelines. It demonstrates how to layout the branded buttons using different UI paradigms.
