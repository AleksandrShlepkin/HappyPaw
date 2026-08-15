import Foundation

nonisolated protocol GoogleURLSession: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: GoogleURLSession {}

nonisolated struct GoogleAPIClient: Sendable {
    private let session: any GoogleURLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let maximumRetryCount: Int

    init(
        session: any GoogleURLSession = URLSession.shared,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init(),
        maximumRetryCount: Int = 2
    ) {
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
        self.maximumRetryCount = maximumRetryCount
    }

    func send<Response: Decodable>(
        _ request: GoogleAPIRequest,
        accessToken: String,
        responseType: Response.Type = Response.self
    ) async throws -> Response {
        let data = try await perform(request, accessToken: accessToken)

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw GoogleServiceError.api("Unable to decode Google response: \(error.localizedDescription)")
        }
    }

    func perform(_ request: GoogleAPIRequest, accessToken: String) async throws -> Data {
        var attempt = 0

        while true {
            do {
                let (data, response) = try await session.data(for: makeURLRequest(request, accessToken: accessToken))
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw GoogleServiceError.network("Google returned an invalid response")
                }

                guard (200 ... 299).contains(httpResponse.statusCode) else {
                    let error = decodeError(data, statusCode: httpResponse.statusCode)
                    guard shouldRetry(statusCode: httpResponse.statusCode, attempt: attempt) else {
                        throw error
                    }
                    attempt += 1
                    try await backoff(after: attempt)
                    continue
                }

                return data
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as GoogleServiceError {
                throw error
            } catch let error as URLError {
                guard shouldRetryNetworkError(error, attempt: attempt) else {
                    throw GoogleServiceError.network(error.localizedDescription)
                }
                attempt += 1
                try await backoff(after: attempt)
            } catch {
                throw GoogleServiceError.network(error.localizedDescription)
            }
        }
    }

    private func makeURLRequest(_ request: GoogleAPIRequest, accessToken: String) -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = request.body {
            urlRequest.httpBody = body
            urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }

        return urlRequest
    }

    private func decodeError(_ data: Data, statusCode: Int) -> GoogleServiceError {
        let message = (try? decoder.decode(GoogleAPIErrorResponse.self, from: data).error.message)
            ?? HTTPURLResponse.localizedString(forStatusCode: statusCode)

        switch statusCode {
        case 401:
            return .authorizationExpired
        case 403:
            return .authorization(message)
        case 400 ... 499:
            return .api(message)
        case 500 ... 599:
            return .network(message)
        default:
            return .unknown(message)
        }
    }

    private func shouldRetry(statusCode: Int, attempt: Int) -> Bool {
        attempt < maximumRetryCount && (statusCode == 429 || (500 ... 599).contains(statusCode))
    }

    private func shouldRetryNetworkError(_ error: URLError, attempt: Int) -> Bool {
        attempt < maximumRetryCount && [
            .timedOut, .cannotFindHost, .cannotConnectToHost,
            .networkConnectionLost, .notConnectedToInternet
        ].contains(error.code)
    }

    private func backoff(after attempt: Int) async throws {
        let delay = UInt64(attempt) * 500_000_000
        try await Task.sleep(nanoseconds: delay)
    }
}

nonisolated struct GoogleAPIRequest: Sendable {
    let url: URL
    let method: GoogleHTTPMethod
    let body: Data?

    init(url: URL, method: GoogleHTTPMethod, body: Data? = nil) {
        self.url = url
        self.method = method
        self.body = body
    }
}

nonisolated enum GoogleHTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}

nonisolated private struct GoogleAPIErrorResponse: Decodable {
    let error: ErrorBody

    nonisolated struct ErrorBody: Decodable {
        let message: String
    }
}
