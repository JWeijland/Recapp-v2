// FeedStore.swift – Shared observable store for feed posts

import SwiftUI
import Combine

class FeedStore: ObservableObject {
    static let shared = FeedStore()

    @Published var userPostedPosts: [FeedPost] = []
    @Published var cloudPosts: [FeedPost] = []

    var allPosts: [FeedPost] { userPostedPosts + cloudPosts }

    func addPost(_ post: FeedPost) {
        DispatchQueue.main.async { self.userPostedPosts.insert(post, at: 0) }
    }

    func setCloudPosts(_ posts: [FeedPost]) {
        DispatchQueue.main.async { self.cloudPosts = posts }
    }
}
