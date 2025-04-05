/*
 * Copyright 2019 Google LLC. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

/** @defgroup GARCloudAnchorMode */

/**
 * @ingroup GARCloudAnchorMode
 * Describes the desired behavior of the ARCore Cloud Anchor API. The Cloud Anchor API uses
 * feature maps to persist an anchor throughout sessions and across devices. See the
 * <a href="https://developers.google.com/ar/develop/ios/cloud-anchors/developer-guide">Cloud
 * Anchors developer guide</a> for more information.
 *
 * <p>The default value is `#GARCloudAnchorModeDisabled`. Use
 * `GARSessionConfiguration#cloudAnchorMode` to set the desired mode.
 */
typedef NS_ENUM(NSInteger, GARCloudAnchorMode) {
  /**
   * The Cloud Anchor API is disabled. Calling `GARSession#hostCloudAnchor:TTLDays:completionHandler:error:`
   * and `GARSession#resolveCloudAnchorWithIdentifier:completionHandler:error:` will result in `#GARSessionErrorCodeIllegalState`.
   *
   * This is the default mode.
   */
  GARCloudAnchorModeDisabled = 0,

  /**
   * The Cloud Anchor API is enabled. `GARSession#hostCloudAnchor:TTLDays:completionHandler:error:`
   * and `GARSession#resolveCloudAnchorWithIdentifier:completionHandler:error:` can be used to host and resolve Cloud Anchors.
   *
   * Using this mode requires your app to configure <a href="https://developers.google.com/ar/develop/ios/cloud-anchors/developer-guide#authorization">Token authorization or API Key authorization</a>.
   *
   * Use `GARSessionConfiguration#cloudAnchorMode` to set this mode.
   */
  GARCloudAnchorModeEnabled = 1,
};
