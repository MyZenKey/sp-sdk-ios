fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios test
```
fastlane ios test
```
Runs tests
### ios generate_docs
```
fastlane ios generate_docs
```
Generates Docs
### ios post_docs
```
fastlane ios post_docs
```
Posts Docs to Slack
### ios coverage
```
fastlane ios coverage
```
Runs Code Coverage
### ios write_secrets
```
fastlane ios write_secrets
```
Write secret configs
### ios strip_secrets
```
fastlane ios strip_secrets
```
Remove secrets from configs
### ios develop
```
fastlane ios develop
```
Builds and submits a Develop release to Hockey
### ios sprint
```
fastlane ios sprint
```
Builds and submits a Sprint release to Hockey
### ios update_pods
```
fastlane ios update_pods
```
Updates the pods for all Example repos
### ios beta
```
fastlane ios beta
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
