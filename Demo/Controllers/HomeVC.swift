//
//  HomeVC.swift
//  Demo
//
//  Created by Jeegnesh Solanki on 02/05/24.
//
import UIKit

class HomeVC: UIViewController, UIAlertViewDelegate {
   
    
    @IBOutlet weak var tblHome: UITableView!
    
    var start = 0
    private let viewModel = HomeViewModel()
    var arrSection : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        initViewModel()
//        CollHome.register(UINib(nibName: "WeatherCell", bundle: nil), forCellWithReuseIdentifier: "DataCell")

    }

    func initViewModel()
    {
        viewModel.HomeDataDelegate = self
        let connectivityChecker = InternetConnectivityChecker()

        // Set up the observer for connectivity changes
       

        // Check the current internet connectivity status
        if connectivityChecker.isInternetAvailable() {
            print("Internet is currently available.")
           

        } else {
            print("Internet is currently not available.")
        }
       
        connectivityChecker.connectivityChanged = { [self] isConnected in
            if isConnected {
                print("Internet is available.")
                self.viewModel.fetchData(strUrl: String(format: "_start=%d&_end=10" , start))
            } else {
                print("Internet is not available.")
                    showInternetAlert()
                
            }
        }
    }
    func showInternetAlert()
    {
        let alert = UIAlertController(title: "ERROR", message: "Please check internet connection.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
                case .default:
                print("default")
                
                case .cancel:
                print("cancel")
                
                case .destructive:
                print("destructive")
                
            @unknown default:
                print("default")
            }
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }

    }
}

extension HomeVC : HomeDataServices{
    func reloadData() {
        tblHome.reloadData()
    }

}
extension HomeVC:UITableViewDelegate , UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.ListData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DataCell") as! DataCell
                cell.lblTitle.text = viewModel.ListData[indexPath.row].title
                cell.lblBody.text = viewModel.ListData[indexPath.row].body

        return cell
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        print(indexPath.row)
        if(indexPath.row == viewModel.ListData.count - 2)
        {
            print("LAST")
            if(start < 100)
            {
                start = start + 10
                self.viewModel.fetchData(strUrl: String(format: "_start=%d&_end=%d" , start , start + 10))
            }
        }
    }
    

}
extension HomeVC : UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //NSLog("Table view scroll detected at offset: %f", scrollView.contentOffset.y)
    }
}
//extension  UICollectionViewDelegate , UICollectionViewDataSource ,UICollectionViewDelegateFlowLayout{
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return viewModel.ListData.count //arrFinalWeather.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        var cell = collectionView.dequeueReusableCell(withReuseIdentifier:  "DataCell", for: indexPath ) as! DataCell
////                cell = DataCell()
////            cell = collectionView.dequeueReusableCell(withReuseIdentifier:  "DataCell", for: indexPath ) as! DataCell
//        cell.lblTitle.text = viewModel.ListData[indexPath.row].title
//        cell.lblBody.text = viewModel.ListData[indexPath.row].body
//   
//        //cell.imgIcon.image = img
//            return cell
//    }
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//     
//    }
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout:UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
//    {
//
//        let screenWidth = CollHome.frame.size.width
//        return CGSize(width: screenWidth - 80, height: calculateHeight(inString: viewModel.ListData[indexPath.row].title ?? "") + calculateHeight(inString: viewModel.ListData[indexPath.row].body ?? "") + 40 );
//        //return CGSize(width: (screenWidth/3)-7, height: (screenWidth/3));
//
//        
//    }
//    func calculateHeight(inString:String) -> CGFloat
//           {
//               let messageString = inString
//               let attributes : [NSAttributedString.Key : Any] = [NSAttributedString.Key(rawValue:
//       NSAttributedString.Key.font.rawValue) : UIFont.boldSystemFont(ofSize:
//       20.0)]
//
//               let attributedString : NSAttributedString = NSAttributedString(string: messageString, attributes: attributes)
//               let rect : CGRect = attributedString.boundingRect(with: CGSize(width: CollHome.frame.size.width - 20, height: CGFloat.greatestFiniteMagnitude),
//       options: .usesLineFragmentOrigin, context: nil)
//
//               let requredSize:CGRect = rect
//               return requredSize.height
//           }
// 
//}
