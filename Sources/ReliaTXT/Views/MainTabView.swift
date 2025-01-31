import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                TicketListView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Tickets", systemImage: "list.bullet")
            }
            .tag(0)
            
            NavigationView {
                ProfileView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(1)
        }
        .environmentObject(authViewModel)
    }
}
