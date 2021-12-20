/*
 * Copyright (C) 2016 nohana, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit

class RootViewController: UIViewController {
    
    private let nohanaImagePickerController: NohanaImagePickerController
    
    init?(coder: NSCoder, nohanaImagePickerController: NohanaImagePickerController) {
        self.nohanaImagePickerController = nohanaImagePickerController
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - IBAction
    @IBAction func didTapDone(_ sender: AnyObject) {
        let pickedPhotoKitAssets = nohanaImagePickerController.pickedAssetList.map { ($0 as! PhotoKitAsset).originalAsset }
        nohanaImagePickerController.delegate?.nohanaImagePicker(nohanaImagePickerController, didFinishPickingPhotoKitAssets: pickedPhotoKitAssets )
    }
    
    @IBAction func didTapClose(_ sender: AnyObject) {
        dismiss(animated: true)
    }

}
