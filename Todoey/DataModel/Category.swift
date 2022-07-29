//
//  Category.swift
//  Todoey
//
//  Created by user208023 on 7/26/22.
//  Copyright © 2022 App Brewery. All rights reserved.
//

import Foundation
import RealmSwift

class Category: Object {
    @Persisted var name: String  = ""
    @Persisted var color: String = ""
    @Persisted var items = List<Item>()
}
