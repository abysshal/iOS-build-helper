# Build & Deploy Scripts for CocoaPods projects in local env or Gitlab-CI runner

@Author: [abysshal@gmail.com](mailto:abysshal@gmail.com)

@Time: 20150605

## Feature

- Build CocoaPods project in shell.
- Package app in ipa file.
- Generate resources for ITMS service.
- Deploy ITMS files to localhost.

## Installation

- Register as Apple Developer, make Private-Key and signed Certificate for develop.
- Generate provisioning profile for develop.
- Install Xcode and Command Line tools on mac.
- Add Developer account in Xcode->preference->accounts and sync the profiles.
- New Xcode project or use any exist projects, copy the `scripts` dir into the `$PROJECT_HOME`.
- Open terminal, `cd` to `$PROJECT_HOME` dir, run the shells like `scripts/xxx.sh` .

## Configuration

1. modify paramaters in `run-build.sh`:

    ```
    export PROJECT_NAME=myproject
    export OEMCONFIG_NAME=myproject
    ```

    `PROJECT_NAME` is used to locate the `.xcodeproj` or the `.xcworkspace` file in project dir and the `scheme` name to build.

    `OEMCONFIG_NAME` is used to bump `Info.plist` entries before build. `bumpinfo.sh` will read the config from `scripts/$OEMCONFIG_NAME-config/Info.plist` file if exists.

1. `cp` or `rename` `scripts/myproject-config` dir, modify the `Info.plist` in it to fit your project setting.

1. modify paramaters in `run-deploy.sh` or define those in your CI runner's Shell environment:

    ```
    #export DEPLOY_ENDPOINT=https://dl.xxx.xxx
    #export DEPLOY_LOCAL_DIR=/Users/cirunner/Sites
    ```

     `DEPLOY_LOCAL_DIR` should be set as the web document ROOT dir in `apache` or `nginx` and enable the `Indexes` option. All ITMS resources will be copied to this dir.

     `DEPLOY_ENDPOINT` is used to access the ITMS resources. Visit `DEPLOY_ENDPOINT` should be accessed to `DEPLOY_LOCAL_DIR`.


## Usage

Local build for release:

```
cd $PROJECT_HOME
scripts/run-build.sh -local -release
```

CI build & deploy for debug:

```
scripts/run-build.sh -ci -debug || exit
scripts/run-deploy.sh -ci -debug || exit
```

**Due to the Gitlab-CI log limit, xcode build & package output will be directed to log files under $PROJECT_HOME/build/logs/ in CI runner env.**

## Known issues

- [Code sign failed in non-interactive env like SSH](http://stackoverflow.com/questions/20205162/user-interaction-is-not-allowed-trying-to-sign-an-osx-app-using-codesign)
- [gitlab-ci-multi-runner always failed in some env](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/issues/33)
- [Other gitlab-ci-multi-runner issues](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/issues)

## TODO

- Add feature: uploading ITMS resources to AWS s3.
- Add document for enable SSL service on Mac OSX.

## Thanks

- [ipa-build]()
- [ipaHelper](https://github.com/MarcusSmith/ipaHelper)
