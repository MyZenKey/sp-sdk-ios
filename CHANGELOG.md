# Changelog
All notable changes to this project will be documented in this file.

Any release before 1.0.0 may contain breaking changes.
After 1.0.0 this project will adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Versions
- [0.9.1 - 2019-11-25](#091---2019-11-25)
- [0.9.0 - 2019-10-21](#090---2019-10-21)

## Updating
When the Unreleased section becomes a new version, duplicate the Template to create a new Unreleased section. Breaking changes should begin with a [breaking] tag.

## [Template]
### Added
### Changed
### Removed
### Deprecated
### Fixed
### Security

## [Unreleased]
### Added
### Changed
### Removed
### Deprecated
### Fixed
### Security

## [0.9.1] - 2019-11-25
### Added
- New ZenKeyButtonView provides carrier endorsement UI; now preferred over ZenKeyAuthorizeButton.
- PKCE: auto-generated codeChallenge and method are included in auth code request.
- PKCE: codeVerifier returned in authenticatedResponse for use in token requests.
- SDK version parameter included in API requests.
- Presented ViewControllers use .fullScreen modalPresentationStyle.
### Changed
- ACR values passed to API are now a1, a2, a3 instead of aal1, aal2, aal3. API and ZenKey app update required.
- Updated to iOS 13 SDK, Xcode 11.
### Removed
- [breaking] Depreciated scopes: authorize, register, secondFactor, authenticate, birthdate, isAdult, picture, address, location, events, offlineAccess, score, match.
- base64url encoding of the context parameter in auth code request. ZenKey app update required.
- ACR value no longer defaults to a1; a request may contain no ACR parameter.

## [0.9.0] - 2019-10-21
### Added
- First public release
