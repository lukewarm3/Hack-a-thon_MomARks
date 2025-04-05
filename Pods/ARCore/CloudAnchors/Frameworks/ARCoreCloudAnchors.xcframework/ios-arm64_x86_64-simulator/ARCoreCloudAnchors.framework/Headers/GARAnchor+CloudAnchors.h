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

#import <ARCoreCloudAnchors/GARCloudAnchorState.h>
#import <ARCoreGARSession/GARAnchor.h>

NS_ASSUME_NONNULL_BEGIN

/** Category adding Cloud Anchor functionality to `GARAnchor`. */
__attribute__((deprecated("The properties in this category are not used with async APIs.")))
@interface GARAnchor (CloudAnchors)

/**
 * Cloud Anchor identifier, if applicable. This will be `nil` unless the cloud state of the anchor
 * is `#GARCloudAnchorStateSuccess`.
 */
@property(nonatomic, readonly, nullable) NSString *cloudIdentifier
    __attribute__((deprecated("When hosting an anchor using an async method, get the ID using "
                              "the callback or future object instead. This will always be nil, "
                              "except for anchors created through deprecated methods.")));

/**
 * The Cloud Anchor state, if applicable. Indicates the state of the hosting or resolving operation
 * on this anchor, if any.
 */
@property(nonatomic, readonly) GARCloudAnchorState cloudState
    __attribute__((deprecated("When hosting or resolving an anchor using an async method, get the "
                              "result status from the callback or future object instead. This will "
                              "always be GARCloudAnchorStateNone, except for anchors created "
                              "through deprecated methods.")));

@end

NS_ASSUME_NONNULL_END
