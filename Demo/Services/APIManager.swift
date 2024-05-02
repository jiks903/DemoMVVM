//
//  APIManager.swift
//  Demo
//
//  Created by Jeegnesh Solanki on 02/05/24.
//

import Foundation
import SystemConfiguration
import UIKit

typealias Handler<T> = (Result<T, DataError>) -> Void

enum DataError: Error {
    case invalidResponse
    case invalidURL
    case invalidData
    case network(Error?)
}


class APIManager {
    
    func request<T: Decodable>(url: String) async throws ->  T {
        guard let url = URL(string: url) else {
            throw DataError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DataError.invalidResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    
    

    
}
