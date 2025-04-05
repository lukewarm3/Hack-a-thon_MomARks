/*
 * Copyright 2022 Google LLC. All Rights Reserved.
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

#import <ARCoreCloudAnchors/GARCloudAnchorMode.h>
#import <ARCoreGARSession/GARSessionConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

/** Category adding Cloud Anchor functionality to `GARSessionConfiguration`. */
@interface GARSessionConfiguration (CloudAnchors)

/**
 * Describes the desired behavior of the ARCore Cloud Anchor API. The Cloud Anchor API uses
 * feature maps to persist an anchor throughout sessions and across devices. See the
 * <a href="https://developers.google.com/ar/develop/ios/cloud-anchors/developer-guide">Cloud
 * Anchors developer guide</a> for more information.
 *
 * The default value is `#GARCloudAnchorModeDisabled`.
 * If the mode is changed, existing Cloud Anchors will have their `GARAnchor#cloudState` set to
 * `#GARCloudAnchorStateNone` and cease being updated except for tracking state changes.
 *
 * Remember to set a credential for authentication with Google Cloud before configuring, or
 * you may receive auth errors.
 */
@property(nonatomic) GARCloudAnchorMode cloudAnchorMode;

@end

NS_ASSUME_NONNULL_END
