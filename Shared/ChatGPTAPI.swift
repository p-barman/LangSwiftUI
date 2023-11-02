import Foundation


//class ChatUAPI {
//    private let apiKey: String
//    private let urlSession = URLSession.shared
//    private var urlRequest: URLRequest {
////        let url = URL(string: "http://api.openai.com/v1/chat/completions")!
////        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = "POST"
//        headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
//        return urlRequest
//    }
//    
//    private let basePrompt = "You are a helpful assistant"
//    
//    let dateFormatter: DateFormatter = {
//        let df = DateFormatter()
//        df.dateFormat = "YYYY-MM-dd"
//        return df
//    }()
//    
//    private let jsonDecoder: JSONDecoder = {
//        let jsonDecoder = JSONDecoder()
//        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
//        return jsonDecoder
//    }()
//    
//    private var headers: [String: String] {
//        [
//            "Content-Type": "application/json",
//            "Authorization": "Bearer \(apiKey)"
//        ]
//    }
//    
//    init(apiKey: String) {
//        self.apiKey = "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"
//    }
//    
//    private func generateChatGPTPrompt(from text: String) -> String {
//        return basePrompt + "User: \(text)\n\nChatGPT:"
//    }
//    
//    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
//        let jsonBody: [String:Any] = [
//            "model": "gpt-3.5-turbo",
//            "temperature": 0.5,
//            "max_tokens": 1024,
//            "prompt": generateChatGPTPrompt(from: text),
//            "stop": [
//                "\n\n\n",
//                ""
//            ],
//            "stream": stream
//        ]
//        return try JSONSerialization.data(withJSONObject: jsonBody)
//    }
//    
//    
//    enum ChatAPIError: Error {
//        case invalidResponse
//        case badResponse(statusCode: Int)
//    }
//    
//    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
//        var urlRequest = self.urlRequest
//        urlRequest.httpBody = try jsonBody(text: text)
//        
//        // You might need to replace this line if `bytes(for:)` is not a valid method in your URLSession extension or framework.
//        let (result, response) = try await urlSession.bytes(for: urlRequest)
//        try Task.checkCancellation()
//        
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw ChatAPIError.invalidResponse // Here's one of the errors that gets thrown as a string
//        }
//        
//        guard 200...299 ~= httpResponse.statusCode else {
//            throw ChatAPIError.badResponse(statusCode: httpResponse.statusCode) // Here's another one
//        }
//        
//        return AsyncThrowingStream<String, Error> { continuation in
//            Task(priority: .userInitiated) {
//                do {
//                    for try await line in result.lines {
//                        if line.hasPrefix("data: "),
//                           let data = line.dropFirst(6).data(using: .utf8),
//                           let response = try? self.jsonDecoder.decode(CompletionResponse.self, from: data),
//                           let text = response.choices.first?.text {
//                            continuation.yield(text)
//                        }
//                    }
//                    continuation.finish()
//                } catch {
//                    continuation.finish(throwing: error)
//                }
//            }
//        }
//    }
//}
//    

extension String: Error {}

struct CompletionResponse: Decodable {
    let choices: [Choice]
}
struct Choice: Decodable {
    let text: String
}

