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

#import <Foundation/Foundation.h>

#import <ARCoreCloudAnchors/GARCloudAnchorState.h>
#import <ARCoreGARSession/GARFuture.h>
#import <ARCoreGARSession/GARFutureState.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A handle to an async operation launched by a call to
 * `GARSession#hostCloudAnchor:TTLDays:completionHandler:error:`.
 * See the <a href="https://developers.google.com/ar/develop/ios/cloud-anchors/developer-guide">Cloud
 * Anchors developer guide</a> for more information.
 */
@interface GARHostCloudAnchorFuture : GARFuture

/**
 * The result identifier of the async operation, or nil if the operation isn't completed
 * successfully. This should only be used after checking that `#state` is `#GARFutureStateDone`.
 */
@property(nonatomic, nullable, readonly) NSString *resultCloudIdentifier;

/**
 * The result Cloud Anchor state of the async operation, or a default value if the operation isn't
 * complete. This should only be used after checking that `#state` is `#GARFutureStateDone`.
 */
@property(nonatomic, readonly) GARCloudAnchorState resultCloudAnchorState;

/// @cond
/** Instances are returned by `GARSession#hostCloudAnchor:TTLDays:completionHandler:error:`. */
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
/// @endcond

@end

NS_ASSUME_NONNULL_END
