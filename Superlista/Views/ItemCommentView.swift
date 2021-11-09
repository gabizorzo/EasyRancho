import SwiftUI

struct ItemCommentView: View {
    @EnvironmentObject var dataService: DataService
    
    @State var isCommenting: Bool = false
    @State var comment: String = ""
    
    let purpleColor = Color("Background")

    var item: ItemModel
    var list: ListModel
    
    var body: some View {
        ZStack{
            Color("PrimaryBackground")
                .ignoresSafeArea()
            
            VStack (alignment: .leading, spacing: 0) {
                
                HStack(alignment: .center) {
                    
                    Image(systemName: item.isCompleted ? "checkmark.circle" : "circle")
                        .foregroundColor(item.isCompleted ? Color(UIColor.secondaryLabel) : Color.primary)
                        .font(.system(size: 18, weight: .light))
                        .onTapGesture {
                            dataService.toggleCompletion(of: item, from: list)
                        }
                    
                    Text(item.product.name)
                        .strikethrough(item.isCompleted)
                        .foregroundColor(item.isCompleted ? Color(UIColor.secondaryLabel) : Color.primary)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    
                    if !isCommenting{
                        Image(systemName: "text.bubble")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color("Comment"))
                            .onTapGesture {
                                isCommenting = true
                            }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Image(systemName: "minus")
                            .resizable()
                            .frame(width: 17, height: ((item.quantity ?? 1) > 1) ? 2 : 1.5)
                            .foregroundColor(((item.quantity ?? 1) > 1) ? Color("Comment") : Color(UIColor.secondaryLabel))
                    }
                    .frame(width: 17, height: 17)
                    .onTapGesture {
                        dataService.removeQuantity(of: item, from: list)
                    }
                    .accessibilityLabel(Text("Remove"))
                    .accessibility(hint: Text("RemoveOneItem"))

                    
                    Text("\(item.quantity ?? 1)")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primary)
                        .accessibilityLabel(Text("\(item.quantity ?? 1) items"))
                    
                    
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 17, height: 17)
                        .foregroundColor(Color("Comment"))
                        .onTapGesture {
                            dataService.addQuantity(of: item, from: list)
                        }
                        .accessibilityLabel(Text("Add"))
                        .accessibility(hint: Text("AddOneItem"))
                    
                }
                
                if isCommenting {
                    HStack {
                        ZStack(alignment: .leading){
                            if (comment == "") {
                                Text("ItemCommentViewPlaceholder")
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                    .font(.system(size: 13))
                                    .padding(.leading, 30)
                            }
                            
                            TextField(comment , text: $comment)
                                .font(.system(size: 13))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.leading, 28)
                        }
                        
                        Spacer()
                        
                        Text("ItemCommentViewButtonLabel")
                            .foregroundColor(Color.primary)
                            .font(.subheadline)
                            .onTapGesture {
                                dataService.addComment(comment, to: item, from: list)
                                isCommenting = false
                            }
                    }
                } else if item.comment != "" {
                    Text(item.comment ?? "")
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.leading, 30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("PrimaryBackground"))
            .onAppear {
                self.comment = item.comment ?? ""
            }
            .padding(.vertical, 5)
        }
    }
}
