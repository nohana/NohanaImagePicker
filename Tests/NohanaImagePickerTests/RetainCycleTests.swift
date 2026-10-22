/*
 * Copyright (C) 2026 nohana, Inc.
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

import Testing
import UIKit
@testable import NohanaImagePicker

@MainActor
struct RetainCycleTests {

    // Runs the main run loop until `condition` holds or `timeout` elapses, so pending main queue work
    // (e.g. DispatchQueue.main.async in viewDidLoad) can release its references before checking deallocation.
    private func runMainLoop(until condition: () -> Bool, timeout: TimeInterval = 2) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }

    @Test("NohanaImagePickerController is deallocated after its view is loaded", arguments: [false, true])
    func pickerIsDeallocatedAfterViewLoad(canPickDateSection: Bool) {
        weak var weakPicker: NohanaImagePickerController?
        autoreleasepool {
            let picker = NohanaImagePickerController()
            picker.canPickDateSection = canPickDateSection
            picker.loadViewIfNeeded()
            picker.view.layoutIfNeeded()
            weakPicker = picker
        }
        runMainLoop(until: { weakPicker == nil })
        #expect(weakPicker == nil)
    }

    @Test("PhotoAuthorizationLimitedCell does not retain its delegate")
    func limitedCellDoesNotRetainDelegate() {
        let cell = PhotoAuthorizationLimitedCell(frame: .zero)
        weak var weakDelegate: DelegateSpy?
        autoreleasepool {
            let delegate = DelegateSpy()
            cell.delegate = delegate
            weakDelegate = delegate
        }
        #expect(weakDelegate == nil)
    }
}

private final class DelegateSpy: PhotoAuthorizationLimitedCellDeletate {
    func didSelectAddPhotoButton(_ cell: PhotoAuthorizationLimitedCell) {}
    func didSelectAuthorizeAllPhotoButton(_ cell: PhotoAuthorizationLimitedCell) {}
}
