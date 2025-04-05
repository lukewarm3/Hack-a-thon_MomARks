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

#import <ARCoreGARSession/GARFutureState.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @section future_concept Futures in ARCore
 *
 * Futures represent the eventual completion of an asynchronous
 * operation. A future has one of three states, `GARFutureState`, which can
 * be obtained with `GARFuture.state`:
 *
 * - `#GARFutureStatePending` - The operation is still pending. The result of
 *   the operation isn't available yet and any associated callback hasn't yet
 *   been invoked.
 * - `#GARFutureStateDone` - The operation is complete, and a result is
 *   available.
 * - `#GARFutureStateCancelled` - The operation has been cancelled.
 *
 * A `GARFuture` starts in the `#GARFutureStatePending` state and
 * transitions to `#GARFutureStateDone` upon completion. If the
 * future is cancelled using `GARFuture#cancel`, then its state may become
 * `#GARFutureStateCancelled` (see @ref future_cancellation "cancelling a future"
 * for caveats).
 *
 * @section future_results Obtaining results from a Future
 *
 * There are two ways of obtaining results from a `GARFuture`:
 *
 * @subsection future_polling Polling a Future
 *
 * When the `GARFuture` is created, its `GARFutureState` is set to `#GARFutureStatePending`.
 * You may poll the future using `GARFuture#state` to query the state of the
 * asynchronous operation. When its state is `#GARFutureStateDone`, you can obtain
 * the operation's result.
 *
 * @subsection future_callback Using a completion handler to obtain Future results
 *
 * The operation's result can be reported via a `completionHandler`. When providing a
 * `completionHandler`, ARCore will invoke the given block when the operation is
 * complete, unless the future has been cancelled using `GARFuture#cancel`.
 * This `completionHandler` will be called on the Main thread.
 *
 * @section future_cancellation Cancelling a Future
 *
 * You can try to cancel a `GARFuture` by calling `GARFuture#cancel`.
 * Due to multi-threading, it is possible that the cancel operation is not
 * successful. The return value indicates if the cancellation
 * was successful.
 *
 * If the cancellation is successful, then any
 * @ref future_callback "associated completion handler" will never be called.
 */
@interface GARFuture : NSObject

/** The current future state. */
@property(nonatomic, readonly) GARFutureState state;

/**
 * Cancels the async operation if it's still pending. If the operation was cancelled by this
 * invocation, this method returns true and the callback (if any) will never be invoked.
 */
- (BOOL)cancel;

/// @cond
/** GARFuture subclass instances are created by `GARSession`. */
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
/// @endcond

@end

NS_ASSUME_NONNULL_END
