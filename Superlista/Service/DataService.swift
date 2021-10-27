import Foundation
import CloudKit
import SwiftUI
import Combine

class DataService: ObservableObject {
    
    @Published var user: UserModel? {
        didSet {
            UDService().saveUserOnUD(user: user)

            print("\nUSUARIO UD: ", UDService().getUDUser()?.name ?? "")
            
            print("\nUSUARIO CK: ", CKService.currentModel.user?.name ?? "")
            
            print("\n")
        }
    }
    
    @Published var lists: [ListModel] = [] {
        didSet {
            UDService().saveListsOnUD(lists: lists)
            
            let ud = UDService().getUDLists()
            let ck = CKService.currentModel.user?.myLists
            
            if ud.count > 0 {
                print("\nLists on UD:")
                
                ud.forEach { list in
                    print("\(list.id); \(list.title); \(list.owner.name ?? "")")
                }
            }
            
            if let ckList = ck, ckList.count > 0 {
                print("\nLists on CK:")
                
                ckList.forEach { list in
                    print("\(list.id.recordName); \(list.name ?? ""); \(list.owner?.name ?? "")")
                }
            }
            
        }
    }
    
    @Published var currentList: ListModel?
    
    let products = ProductListViewModel().productsOrdered
    
    let networkMonitor = NetworkMonitor.shared
    
    var userSubscription: AnyCancellable?
    
    init() {
        getDataIntegration()
    }
    
    func getDataIntegration() {
        self.lists = UDService().getUDLists()
        self.user = UDService().getUDUser()
        
        //if online
        self.userSubscription = CKService.currentModel.userSubject.compactMap({ $0 }).receive(on: DispatchQueue.main).sink { ckUserModel in
            
            var userDefaults = UDService().getUDLists()
            
            ckUserModel.myLists?.forEach { list in
                if !userDefaults.contains(where: { $0.id == list.id.recordName }) {
                    
                    let localList = ListModelConverter().convertCloudListToLocal(withList: list)
                    
                    userDefaults.append(localList)
                }
            }
            
            self.lists = userDefaults
            self.user = UserModelConverter().convertCloudUserToLocal(withUser: ckUserModel)
        }
    }
    
    // MARK: - CRUD user
    func updateUserImageAndName(picture: UIImage, newUsername: String) {
        if let currentUser = self.user {
            self.user = UserModel(id: currentUser.id, name: newUsername, customProducts: currentUser.customProducts, myLists: currentUser.myLists, sharedWithMe: currentUser.sharedWithMe)
        }
        
        networkMonitor.startMonitoring { path in
            if path.status == .satisfied {
                CKService.currentModel.updateUserImageAndName(image: picture, name: newUsername) { result in }
            }
        }
    }
    
    func updateUserName(newUsername: String) {
        if let currentUser = self.user {
            self.user = UserModel(id: currentUser.id, name: newUsername, customProducts: currentUser.customProducts, myLists: currentUser.myLists, sharedWithMe: currentUser.sharedWithMe)
        }
        
        networkMonitor.startMonitoring { path in
            if path.status == .satisfied {
                CKService.currentModel.updateUserName(name: newUsername) { result in }
            }
        }
    }
    
    // MARK: - CRUD lists
    func removeList(_ listModel: ListModel) {
        if let index = lists.firstIndex(where: { $0.id == listModel.id }) {
            
            lists.remove(at: index)
            
            networkMonitor.startMonitoring { path in
                if path.status == .satisfied {
                    CloudIntegration.actions.deleteList(listModel)
                }
            }
        }
    }
    
    func editListTitle(of listModel: ListModel, newTitle: String) {
        if let index = lists.firstIndex(where: { $0.id == listModel.id }) {
            lists[index] = listModel.editTitle(newTitle: newTitle)
            
            networkMonitor.startMonitoring { path in
                if path.status == .satisfied {
                    CloudIntegration.actions.updateListTitle(listModel, newTitle)
                }
            }
        }
    }
    
    func addList(_ newList: ListModel) {
        lists.append(newList)
        
        networkMonitor.startMonitoring { path in
            if path.status == .satisfied {
                CloudIntegration.actions.createList(newList)
            }
        }
    }
    
    // MARK: - CRUD List Items
    func addItem(_ item: ItemModel, to listModel: ListModel) {
        if let index = lists.firstIndex(where: { $0.id == listModel.id }) {
            
            let listWithNewItem = lists[index].addItem(item)
            
            lists[index] = listWithNewItem
            
            networkMonitor.startMonitoring { path in
                if path.status == .satisfied {
                    CloudIntegration.actions.updateCkListItems(updatedList: listWithNewItem)
                }
            }
        }
    }
    
    func removeItem(from row: IndexSet, of category: CategoryModel, of listModel: ListModel) {
        if let index = lists.firstIndex(where: { $0.id == listModel.id }) {
            let listWithoutItem = listModel.removeItem(from: row, of: category)
            
            lists[index] = listWithoutItem
            
            networkMonitor.startMonitoring { path in
                if path.status == .satisfied {
                    CloudIntegration.actions.updateCkListItems(updatedList: listWithoutItem)
                }
            }
        }
    }
    
    func removeItem(_ item: ItemModel, from listModel: ListModel) {
        if let index = lists.firstIndex(where: { $0.id == listModel.id }) {
            let listWithoutItem = listModel.removeItem(item)
            
            lists[index] = listWithoutItem
            
            networkMonitor.startMonitoring { path in
                if path.status == .satisfied {
                    CloudIntegration.actions.updateCkListItems(updatedList: listWithoutItem)
                }
            }
        }
    }
    
    func addComment(_ comment: String, to item: ItemModel, from listModel: ListModel) {
        if let index = lists.firstIndex(where: { $0.id == listModel.id }) {
            let listWithNewItemComment = listModel.addComment(comment, to: item)
            
            lists[index] = listWithNewItemComment
            
            networkMonitor.startMonitoring { path in
                if path.status == .satisfied {
                    CloudIntegration.actions.updateCkListItems(updatedList: listWithNewItemComment)
                }
            }
        }
    }
    
    func toggleCompletion(of item: ItemModel, from listModel: ListModel) {
        if let index = lists.firstIndex(where: { $0.id == listModel.id }) {
            let listWithItemNewState = listModel.toggleCompletion(of: item)
            
            lists[index] = listWithItemNewState
            
            networkMonitor.startMonitoring { path in
                if path.status == .satisfied {
                    CloudIntegration.actions.updateCkListItems(updatedList: listWithItemNewState)
                }
            }
        }
    }
}
