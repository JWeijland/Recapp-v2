// SupabaseManager.swift – Backend connectivity via Supabase REST API
//
// SETUP (one-time):
//   1. Go to supabase.com → create a new project
//   2. In your Supabase dashboard: Settings → API
//   3. Copy "Project URL" → replace YOUR_PROJECT_URL below
//   4. Copy "anon public" key → replace YOUR_ANON_KEY below
//   5. In Supabase: SQL Editor → run the schema in SchemaSQL.txt

import Foundation
import Combine

// MARK: – Config (fill in after creating Supabase project)

enum SupabaseConfig {
    static let projectURL = "https://flcbzrsenrfxnptugplg.supabase.co"
    static let anonKey    = "sb_publishable_v2TT4M0rICLisQS_i_Dzeg_NQXo2Eas"
    static var isConfigured: Bool {
        !projectURL.contains("YOUR_PROJECT") && !anonKey.contains("YOUR_ANON")
    }
}

// MARK: – Models

struct SupabaseUser: Codable, Equatable {
    let id:    String
    let email: String?
}

struct AuthResponse: Codable {
    let accessToken:  String
    let refreshToken: String
    let user:         SupabaseUser?
    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct SupabaseError: Codable, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: – Night row models

struct NightRow: Codable {
    let userId:        String
    let title:         String
    let dateIso:       String
    let startTime:     String
    let endTime:       String
    let totalSteps:    Int
    let totalDuration: String
    let stopsCount:    Int
    let authorName:    String
    let data:          NightData

    enum CodingKeys: String, CodingKey {
        case title, data
        case userId        = "user_id"
        case dateIso       = "date_iso"
        case startTime     = "start_time"
        case endTime       = "end_time"
        case totalSteps    = "total_steps"
        case totalDuration = "total_duration"
        case stopsCount    = "stops_count"
        case authorName    = "author_name"
    }
}

struct NightRowResponse: Codable {
    let id:         String
    let userId:     String
    let title:      String
    let totalSteps: Int
    let stopsCount: Int
    let authorName: String?
    let data:       NightData
    let createdAt:  String?

    enum CodingKeys: String, CodingKey {
        case id, title, data
        case userId     = "user_id"
        case totalSteps = "total_steps"
        case stopsCount = "stops_count"
        case authorName = "author_name"
        case createdAt  = "created_at"
    }

    var nightData: NightData { data }
}

// MARK: – Manager

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    @Published var currentUser: SupabaseUser? = nil
    @Published var accessToken: String?       = nil

    private init() { loadSession() }

    var isLoggedIn: Bool { currentUser != nil }

    // MARK: Auth

    func signUp(email: String, password: String) async throws {
        let body = ["email": email, "password": password]
        let resp: AuthResponse = try await post("/auth/v1/signup", body: body, requiresAuth: false)
        setSession(resp)
    }

    func signIn(email: String, password: String) async throws {
        let body = ["email": email, "password": password]
        let resp: AuthResponse = try await post("/auth/v1/token?grant_type=password",
                                                body: body, requiresAuth: false)
        setSession(resp)
    }

    func signInWithApple(identityToken: String) async throws {
        let body: [String: String] = ["provider": "apple", "id_token": identityToken]
        let resp: AuthResponse = try await post(
            "/auth/v1/token?grant_type=id_token",
            body: body,
            requiresAuth: false
        )
        setSession(resp)
    }

    func signOut() {
        accessToken = nil
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "sb_token")
        UserDefaults.standard.removeObject(forKey: "sb_uid")
        UserDefaults.standard.removeObject(forKey: "sb_email")
    }

    // MARK: REST helpers

    func get<T: Decodable>(_ path: String) async throws -> T {
        let req = buildRequest(path, method: "GET")
        return try await execute(req)
    }

    func post<T: Decodable>(_ path: String, body: some Encodable, requiresAuth: Bool = true) async throws -> T {
        var req = buildRequest(path, method: "POST", requiresAuth: requiresAuth)
        req.httpBody = try JSONEncoder().encode(body)
        return try await execute(req)
    }

    func delete(_ path: String) async throws {
        let req = buildRequest(path, method: "DELETE")
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: Nights

    func saveNight(_ night: NightData) async throws {
        guard isLoggedIn, let uid = currentUser?.id else { return }
        let name = currentUser?.email?.components(separatedBy: "@").first ?? "Recap User"
        let row = NightRow(
            userId: uid, title: night.title,
            dateIso: night.dateISO, startTime: night.startTime, endTime: night.endTime,
            totalSteps: night.totalSteps, totalDuration: night.totalDuration,
            stopsCount: night.totalStopsCount, authorName: name, data: night
        )
        try await insertVoid("/rest/v1/nights", body: row)
    }

    func fetchMyNights() async throws -> [NightData] {
        guard isLoggedIn, let uid = currentUser?.id else { return [] }
        let rows: [NightRowResponse] = try await get(
            "/rest/v1/nights?user_id=eq.\(uid)&order=created_at.desc&limit=50"
        )
        return rows.map(\.nightData)
    }

    func fetchFeedNights(limit: Int = 20) async throws -> [NightRowResponse] {
        return try await get("/rest/v1/nights?order=created_at.desc&limit=\(limit)")
    }

    // MARK: Private

    private func insertVoid(_ path: String, body: some Encodable) async throws {
        var req = buildRequest(path, method: "POST")
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            if let err = try? JSONDecoder().decode(SupabaseError.self, from: data) { throw err }
            throw URLError(.badServerResponse)
        }
    }

    private func buildRequest(_ path: String, method: String, requiresAuth: Bool = true) -> URLRequest {
        var req = URLRequest(url: URL(string: SupabaseConfig.projectURL + path)!)
        req.httpMethod = method
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        if requiresAuth, let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func execute<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            if let err = try? JSONDecoder().decode(SupabaseError.self, from: data) { throw err }
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func setSession(_ resp: AuthResponse) {
        accessToken = resp.accessToken
        currentUser = resp.user
        saveSession()
    }

    private func saveSession() {
        UserDefaults.standard.set(accessToken,        forKey: "sb_token")
        UserDefaults.standard.set(currentUser?.id,    forKey: "sb_uid")
        UserDefaults.standard.set(currentUser?.email, forKey: "sb_email")
    }

    private func loadSession() {
        accessToken = UserDefaults.standard.string(forKey: "sb_token")
        if let uid = UserDefaults.standard.string(forKey: "sb_uid") {
            let email = UserDefaults.standard.string(forKey: "sb_email")
            currentUser = SupabaseUser(id: uid, email: email)
        }
    }
}
