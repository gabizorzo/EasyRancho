import Foundation
import CloudKit
import SwiftUI
import Combine

class DataService: ObservableObject {
    
    @Published var user: UserModel? {
        didSet {
            UDService().saveUserOnUD(user: user)
        }
    }
    
    @Published var lists: [ListModel] = [] {
        didSet {
            UDService().saveListsOnUD(lists: lists)
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
        let listas = UDService().getUDLists()
        self.lists = listas
        
        self.user = UDService().getUDUser()
        
        //if online
        self.userSubscription = CKService.currentModel.userSubject.compactMap({ $0 }).receive(on: DispatchQueue.main).sink { ckUserModel in
            var localLists = UDService().getUDLists()
            
            ckUserModel.sharedWithMe?.forEach { list in
                let localList = ListModelConverter().convertCloudListToLocal(withList: list)
                
                let ids = localLists.map(\.id)
                
                if let index = ids.firstIndex(of: list.id.recordName) {
                    localLists[index] = localList
                }
                else {
                    localLists.append(localList)
                }
            }
            
            
            ckUserModel.myLists?.forEach { list in
                let localList = ListModelConverter().convertCloudListToLocal(withList: list)
                
                let ids = localLists.map(\.id)
                
                if let index = ids.firstIndex(of: list.id.recordName) {
                    localLists[index] = localList
                }
                else {
                    localLists.append(localList)
                }
            }
            
            self.lists = localLists
            
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
                    guard let user = self.user else { return }
                    CloudIntegration.actions.deleteList(list: listModel, userID: user.id)
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
    
    func removeCollab(of list: ListModel, owner: OwnerModel) {
        guard let index = list.sharedWith?.firstIndex(where: { owner.id == $0.id }) else { return }
        guard var sharedWith = list.sharedWith else { return }
        sharedWith.remove(at: index)
        
        if let index = lists.firstIndex(where: { $0.id == list.id }) {
            lists[index].sharedWith = sharedWith
        }
        
        networkMonitor.startMonitoring { path in
            if path.status == .satisfied {
                CloudIntegration.actions.removeCollab(of: list, ownerID: owner.id) 
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

    func removeQuantity(of item: ItemModel, from listModel: ListModel) {
        if let index = lists.firstIndex(where: { $0.id == listModel.id }) {
            let listWithNewItemQuantity = listModel.removeQuantity(of: item)
            
            lists[index] = listWithNewItemQuantity
            
            CloudIntegration.actions.updateCkListItems(updatedList: listWithNewItemQuantity)
        }
    }
    
    func addQuantity(of item: ItemModel, from listModel: ListModel) {
        if let index = lists.firstIndex(where: { $0.id == listModel.id }) {
            let listWithNewItemQuantity = listModel.addQuantity(of: item)
            
            lists[index] = listWithNewItemQuantity
            
            CloudIntegration.actions.updateCkListItems(updatedList: listWithNewItemQuantity)
        }
    }
    
    // MARK: - Duplicate Shared List
    func duplicateList(of list: ListModel) {
        guard let user = user, let name = user.name else { return }
        let owner = OwnerModel(id: user.id, name: name)
        let newList = ListModel(title: list.title, items: list.items, owner: owner, sharedWith: list.sharedWith ?? [])
        addList(newList)
    }

    func updateCustomProducts(withName productName: String, for category: String) -> Bool {
        if let user = user,
           let userCustomProducts = user.customProducts {
            let id: Int = getRandomUniqueID(blacklist: userCustomProducts.map({ $0.id }))
            let userNewProduct: ProductModel = ProductModel(id: id, name: productName, category: category)
            
            if !userCustomProducts.map({ $0.name.lowercased() }).contains(userNewProduct.name.lowercased()) &&
                !products.map({ $0.name.lowercased() }).contains(userNewProduct.name.lowercased()) {
                
                user.customProducts?.append(userNewProduct)
                
                networkMonitor.startMonitoring { path in
                    if path.status == .satisfied {
                        CloudIntegration.actions.updateUserCustomProducts(withProduct: userNewProduct)
                    }
                }
                return true
            }
        }
        return false
    }
    
    // MARK: - Add Collab Shared List
    func addCollabList(of list: CKListModel) {
        var sharedWith = list.sharedWith
        
        guard let ckUser = CKService.currentModel.user, let ckUserName = ckUser.name else { return }
        let user = CKOwnerModel(id: ckUser.id, name: ckUserName)
        
        sharedWith.append(user)
        
        CloudIntegration.actions.addCollabList(of: list)
        
        //Início da gambiarra
        list.sharedWith = sharedWith
        let localList = ListModelConverter().convertCloudListToLocal(withList: list)
        lists.append(localList)
        //Fim da gambiarra
    }
    
    func updateCKListItems(of list: ListModel) {
        CloudIntegration.actions.updateCkListItems(updatedList: list)
    }
    
    
    // MARK: - Check if user is Owner
    func isOwner(of list: ListModel, userID: String) -> Bool {
        return userID == list.owner.id
    }
}
