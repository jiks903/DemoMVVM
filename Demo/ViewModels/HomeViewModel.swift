//
//  HomeViewModel.swift
//  Demo
//
//  Created by Jeegnesh Solanki on 02/05/24.
//

import Foundation

protocol HomeDataServices: AnyObject {
    func reloadData() // Data Binding - PROTOCOL (View and ViewModel Communication)
}

class HomeViewModel {

    var ListData: [DatamapModel] = [] {
        didSet {
            self.HomeDataDelegate?.reloadData()
        }
    }
    private let manager = APIManager()
    weak var HomeDataDelegate: HomeDataServices?

    // @MainActor -> DispatchQueue.Main.async
    @MainActor func fetchData(strUrl : String) {
        Task { // @MainActor in
            do {
                let datamapModel: [DatamapModel] = try await manager.request(url: openURL + strUrl)
                if(self.ListData.isEmpty)
                {
                    self.ListData = datamapModel
                }
                else
                {
                    
                    self.ListData.append(contentsOf: datamapModel)
                    print(self.ListData.count)
                }
            }catch {
                print(error)
            }
        }

    }

  
}
