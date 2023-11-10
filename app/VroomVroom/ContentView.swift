//
//  ContentView.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 10/11/23.
//

import SwiftUI
import APIClient

struct ContentView: View {
  var body: some View {
    TabView {
      HomeView()
        .tabItem {
          Label("Home", image: "home")
        }

      CategoriesView()
        .tabItem {
          Label("Categories", image: "home")
        }
    }
  }
}

struct HomeView: View {
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Home!")
    }
    .padding()
  }
}

struct CategoriesView: View {
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Categories!")
    }
    .padding()
  }
}
