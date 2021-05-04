//
//  Item.swift
//  Superlista
//
//  Created by Marina De Pazzi on 04/05/21.
//

import Foundation

struct Item : Hashable, Codable, Identifiable {
    var id: Int
    var name: String
    var category: String
}
