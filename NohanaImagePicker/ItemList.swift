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

public protocol ItemList: Collection {
    associatedtype Item
    var title: String { get }
    func update(_ handler:(() -> Void)?)
    subscript (index: Int) -> Item { get }
}

extension ItemList {
    public func index(after i: Int) -> Int {
        return i + 1
    }
}

public protocol Asset {
    var identifier: Int { get }
    func image(targetSize: CGSize, handler: @escaping (ImageData?) -> Void)
}

public struct ImageData {
    public var image: UIImage
    public var info: Dictionary<NSObject, AnyObject>?
}
