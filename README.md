<img src="./Images/logo.png" width="480" height="280" />


Multiple image picker for iOS app.

## Demo

### Select photos from multiple album

<img src="./Images/collection.gif" width="216" />


### Select photos from the moment

<img src="./Images/moment.png" width="216" />

## Usage

```
import NohanaImagePicker
class ViewController: UIViewController, NohanaImagePickerControllerDelegate {
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        let picker = NohanaImagePickerController()
        picker.delegate = self
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func nohanaImagePickerDidCancel(picker: NohanaImagePickerController) {
        print("🐷Canceled🙅")
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts :[PHAsset]) {
        print("🐷Completed🙆\n\tpickedAssets = \(pickedAssts)")
        picker.dismissViewControllerAnimated(true, completion: nil)
    }

}
```

### Customize

```
let picker = NohanaImagePickerController()

// Set the maximum number of selectable images
picker.maximumNumberOfSelection = 21

// Set the cell size
picker.numberOfColumnsInPortrait = 2
picker.numberOfColumnsInLandscape = 3

// Show Moment
picker.shouldShowMoment = true

// Show empty albums
picker.shouldShowMoment = shouldShowEmptyAlbum = true

// Hide toolbar
picker.shouldShowEmptyAlbum = true

// Disable to pick asset
picker.canPickAsset = { (asset:AssetType) -> Bool in
    return false
}

// Color
ColorConfig.backgroundColor = UIColor.redColor()
```

## Requirements

- Swift2.2
- iOS8.0 later

## Installation

### Carthage (preferable)

Use [Carthage](https://github.com/Carthage/Carthage).

- Add `github "nohana/NohanaImagePicker" ~> 0.4` to your Cartfile.
- Run `carthage update`.

### Framework with CocoaPods

Use [CocoaPods](https://cocoapods.org/).

- Add the followings to your Podfile:

    ```ruby
    use_frameworks!
    pod "NohanaImagePicker", "~> 0.4"
    ```

- Run `pod install`.


## License

This library is licensed under Apache License v2.

```
Copyright (C) 2016 nohana, Inc. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
```