import Foundation

private final class RejectRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

struct OllamaModel: Codable, Identifiable, Hashable {
    let name: String
    var id: String { name }
}

final class OllamaClient {
    var baseURL: URL
    private let redirects = RejectRedirects()
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.connectionProxyDictionary = [:]
        configuration.timeoutIntervalForRequest = 30
        return URLSession(configuration: configuration, delegate: redirects, delegateQueue: nil)
    }()
    deinit { session.invalidateAndCancel() }
    private func checkURL() throws {
        guard TextSafety.isLocalURL(baseURL) else { throw URLError(.badURL) }
    }

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func tags() async throws -> [OllamaModel] {
        try checkURL()
        let url = baseURL.appending(path: "api/tags")
        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        struct Response: Codable { let models: [OllamaModel] }
        return try JSONDecoder().decode(Response.self, from: data).models
    }

    func suggest(text: String, mode: CorrectionMode, model: String) async throws -> CorrectionSuggestion {
        try checkURL()
        guard text.count <= 500 else { throw URLError(.dataLengthExceedsMaximum) }
        let prompt = Self.prompt(text: text, mode: mode)
        let url = baseURL.appending(path: "api/generate")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        let payload: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "format": "json",
            "think": false,
            "options": [
                "temperature": 0.1,
                "num_predict": 180
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        struct GenerateResponse: Codable { let response: String }
        let generated = try JSONDecoder().decode(GenerateResponse.self, from: data).response
        return try Self.parseSuggestion(generated)
    }

    private static func prompt(text: String, mode: CorrectionMode) -> String {
        let instruction: String
        switch mode {
        case .spelling:
            instruction = "Corrige solo ortografía, acentos, mayúsculas, puntuación y gramática. No cambies estilo ni significado."
        case .clarity:
            instruction = "Mejora claridad y fluidez sin cambiar intención. Mantén un tono natural."
        case .professional:
            instruction = "Reescribe de forma profesional, clara y breve sin sonar rígido."
        case .direct:
            instruction = "Reescribe de forma simple, directa y natural, manteniendo la voz del usuario."
        }
        return """
        Eres un asistente local de escritura. Responde SOLO JSON compacto válido, sin markdown.
        \(instruction)
        Si no hay cambio útil, usa needs_change=false y corrected igual al texto original.
        safe_auto_replace debe ser true solo para correcciones mecánicas seguras; false para cambios de estilo/tono.
        Formato exacto:
        {"needs_change":true,"corrected":"...","reason":"...","safe_auto_replace":false}
        Texto:
        \"\"\"
        \(text)
        \"\"\"
        """
    }

    private static func parseSuggestion(_ raw: String) throws -> CorrectionSuggestion {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonText: String
        if let start = trimmed.firstIndex(of: "{"), let end = trimmed.lastIndex(of: "}") {
            jsonText = String(trimmed[start...end])
        } else {
            jsonText = trimmed
        }
        let data = Data(jsonText.utf8)
        return try JSONDecoder().decode(CorrectionSuggestion.self, from: data)
    }
}
