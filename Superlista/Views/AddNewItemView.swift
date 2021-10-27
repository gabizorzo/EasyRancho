import SwiftUI
import Foundation

struct AddNewItemView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var listsViewModel: DataService
    
    var list: ListModel
    
    @Binding var hasChangedItems: Bool
    
    @State var searchText: String
    
    let products = ProductListViewModel().productsOrdered
    
    var body: some View {
        GeometryReader { geometry in
            MainScreen(customView: AnyView(
                VStack {
                    
                    ProductListView(list: list, filter: $searchText, hasChangedItems: $hasChangedItems)
                    
                    Button(action: prontoButtonPressed, label: {
                        Text("ProntoNovosItens")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(height: geometry.size.height * 0.06)
                            .frame(width: geometry.size.height * 0.25)
                            .background(Color("Button"))
                            .cornerRadius(30)
                    })
                    .padding(.bottom, geometry.size.height * 0.12)
                    .padding(.top, geometry.size.height * (0.01))
                    
                }
                
            ))
            .toolbar {
                ToolbarItem(placement: .principal){
                    SearchBar(text: $searchText)
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.3)
                }
            }
        }
    }
    
    func prontoButtonPressed() {
        presentationMode.wrappedValue.dismiss()
    }
}
