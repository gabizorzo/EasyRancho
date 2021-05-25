//
//  TestView.swift
//  Superlista
//
//  Created by Thaís Fernandes on 06/05/21.
//

import SwiftUI

struct ListView: View {
    @EnvironmentObject var listsViewModel: ListsViewModel
    
    @State var listId: String?
    
    func getList() -> ListModel? {
        if let listId = listId,
           let list = listsViewModel.list.first(where: { $0.id == listId }) {
            return list
        }
        
        return nil
    }
    
    @State var canEditTitle: Bool = true
    @State var isFavorite: Bool = false
    
    
    @State var listaTitulo: String = ""
    
    var body: some View {
            MainScreen(customView: AnyView(
                VStack (spacing: 20) {
                    ListHeader(list: getList(), listId: $listId)
                    
                    if let list = getList() {
                        NavigationLink(destination: AddNewItemView(list: list, searchText: "")){
                            FakeSearchBar()
                                .padding(.horizontal, 20)
                        }
                        
                        if !listsViewModel.isGrid {
                            ListPerItemsView(list: list)
                                .padding(.horizontal)
                                .padding(.bottom, 30)
                        } else {
                            ListPerCategoryView(list: list)
                                .padding(.horizontal)
                                .padding(.bottom, 30)
                        }
                        
                    } else {
                        Spacer()
                    }
                }
            ), topPadding: -30)
        
    }
}
