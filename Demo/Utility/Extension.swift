

import UIKit
import CoreLocation
import AVKit


class ImageCache {
    private var memoryCache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private var diskCacheURL: URL
    
    init() {
        // Specify a folder path for disk cache
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache")
        
        // Create the directory if it doesn't exist
        if !fileManager.fileExists(atPath: diskCacheURL.path) {
            try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func image(for url: URL) -> UIImage? {
        // Check memory cache
        if let image = memoryCache.object(forKey: url as NSURL) {
            return image
        }
        let str = String(format: "%@", url as CVarArg)
        let nameStr = str.components(separatedBy: "/images/")
        // Check disk cache
        if(nameStr.count > 1)
        {
            diskCacheURL = diskCacheURL.appendingPathComponent(nameStr[1])
        }
        let fileURL = diskCacheURL.appendingPathComponent(url.lastPathComponent)
        if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            // Store image in memory cache for future use
            memoryCache.setObject(image, forKey: url as NSURL)
            return image
        }
        
        return nil
    }

    func saveImage(_ image: UIImage, for url: URL) {
        // Save image to memory cache
        memoryCache.setObject(image, forKey: url as NSURL)
        
        // Save image to disk cache
        let fileURL = diskCacheURL.appendingPathComponent(url.lastPathComponent)
        if let data = image.jpegData(compressionQuality: 1.0) {
            try? data.write(to: fileURL)
        }
    }
}

class ImageLoader {
    private let cache = ImageCache()
    
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // Check cache for image
        if let cachedImage = cache.image(for: url) {
            completion(cachedImage)
            return
        }
        
        // Fetch image from the network
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, let image = UIImage(data: data), error == nil else {
                completion(nil)
                return
            }
            
            // Save image to cache
            self.cache.saveImage(image, for: url)
            
            // Return the loaded image
            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        task.resume()
    }
}

extension UILabel {

    // MARK: - spacingValue is spacing that you need
    func addInterlineSpacing(spacingValue: CGFloat = 2) {

        // MARK: - Check if there's any text
        guard let textString = text else { return }

        // MARK: - Create "NSMutableAttributedString" with your text
        let attributedString = NSMutableAttributedString(string: textString)

        // MARK: - Create instance of "NSMutableParagraphStyle"
        let paragraphStyle = NSMutableParagraphStyle()

        // MARK: - Actually adding spacing we need to ParagraphStyle
        paragraphStyle.lineSpacing = spacingValue

        // MARK: - Adding ParagraphStyle to your attributed String
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedString.length
        ))

        // MARK: - Assign string that you've modified to current attributed Text
        attributedText = attributedString
    }

}
extension String {
    
    func isStringEmpty() -> Bool {
        return self.trimWhiteSpace().count == 0 ? true : false
    }
    
    var isValidEmail: Bool {
        NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}").evaluate(with: self.trimWhiteSpace())
    }
    
    func isValidString() -> Bool {
        if self == "<null>" || self == "(null)" || self == "null" || self == "" {
            return false
        }
        return true
    }
    
    func isValidPassword() -> Bool {
        // least one uppercase,
        // least one digit
        // least one lowercase
        // least one symbol
        //  min 8 characters total
        //        let password = self.trimmingCharacters(in: CharacterSet.whitespaces)
        //        let passwordRegx = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&<>*~:`-]).{8,}$"
        let passwordRegx = "^(?=.*?[A-Za-z])(?=.*?[0-9]).{6,}$"
        let passwordCheck = NSPredicate(format: "SELF MATCHES %@",passwordRegx)
        return passwordCheck.evaluate(with: self)
        
    }
    
    func capitalizeOnlyFirstLetter() -> String {
        
        if self.count > 1
        {
            let arr = self.lowercased().components(separatedBy: " ")
            var finalStr = ""
            for i in 0 ..< arr.count
            {
                let subStr = NSString(string: arr[i])
                var cStr = subStr.substring(from: 0)
                if i == 0
                {
                    cStr = subStr.substring(from: 0).capitalized
                }
                finalStr = finalStr + " " + cStr
            }
            
            return  finalStr
        }
        else
        {
            return self.capitalized
        }
    }
    
    var isNumber: Bool {
        return self.range(
            of: "^[0-9]*$", // 1
            options: .regularExpression) != nil
    }
    
    func toDecimalWithTwoDecimal() -> String {
        
        if let fl = Float(self)
        {
            return String(NSString(format: "%.2f", fl))
        }
        return "0.00"
    }
    
    func toHexaDecimalToDecimal() -> String {
        
        if let value = UInt8(self, radix: 16) {
            return "\(value)"
        }
        return "0.00"
    }
    func isValidUrl () -> Bool {
        
        let urlRegEx = "^(https?://)?(www\\.)?([-a-z0-9]{1,63}\\.)*?[a-z0-9][-a-z0-9]{0,61}[a-z0-9]\\.[a-z]{2,6}(/[-\\w@\\+\\.~#\\?&/=%]*)?$"
        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        let result = urlTest.evaluate(with: self.lowercased())
        return result
    }
    
    
    mutating func removeSubString(subString: String) -> String {
        if self.contains(subString) {
            guard let stringRange = self.range(of: subString) else { return self }
            return self.replacingCharacters(in: stringRange, with: "")
        }
        return self
    }
    
    
    func trimWhiteSpace() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
    static func className(_ aClass: AnyClass) -> String {
        return NSStringFromClass(aClass).components(separatedBy: ".").last!
    }
    
    func JSONToDict() -> NSDictionary
    {
        let jsonData = self.data(using: .utf8)!
        if let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
        {
            return dictionary as! NSDictionary
        }
        return NSDictionary()
    }
    
    func JSONToDictArr() -> [NSDictionary]
    {
        let jsonData = self.data(using: .utf8)!
        if let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
        {
            return dictionary as! [NSDictionary]
        }
        return [NSDictionary]()
    }
    
    
    var isBackspace: Bool {
        let char = self.cString(using: String.Encoding.utf8)!
        return strcmp(char, "\\b") == -92
    }
    
    func getDateFromStringWith(format:String) -> Date? {
        
        let dateFmt:DateFormatter? = DateFormatter()
        dateFmt?.timeZone = TimeZone(abbreviation: "GMT+0:00")
        dateFmt?.dateFormat =  format
        // Get NSDate for the given string
        return dateFmt?.date(from: self)
    }
    
    func toLocalTimeMethod3(format:String) -> Date?
    {
        
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale   = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = format
        let convertedDate = dateFormatter.date(from: self)
        return convertedDate
    }
    
    
    
    
    func capitalizeFirstLetter() -> String {
        
        if self.count > 1
        {
            let arr = self.components(separatedBy: " ")
            var finalStr = ""
            for str in arr
            {
                let subStr = NSString(string: str)
                let cStr = subStr.substring(from: 0).capitalized
                finalStr = finalStr + " " + cStr
            }
            
            return  finalStr
        }
        else
        {
            return self.capitalized
        }
    }
    mutating func insert(string:String,ind:Int) {
        self.insert(contentsOf: string, at:self.index(self.startIndex, offsetBy: ind) )
    }
    func index(of pattern: String) -> Index? {
        // 1
        for i in indices {
            
            // 2
            var j = i
            var found = true
            for p in pattern.lowercased().indices {
                guard j != endIndex && self.lowercased()[j] == pattern.lowercased()[p] else { found = false; break }
                j = index(after: j)
            }
            if found {
                return i
            }
        }
        return nil
    }
    
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }
    
    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        return String(self[start...])
    }
    
    func imageFromBase64() -> UIImage? {
        if let url = URL(string: self), let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
    
}

extension StringProtocol {
    func nsRange(of string: Self, options: String.CompareOptions = [], range: Range<Index>? = nil, locale: Locale? = nil) -> NSRange? {
        guard let range = self.range(of: string, options: options, range: range ?? startIndex..<endIndex, locale: locale ?? .current) else { return nil }
        return .init(range, in: self)
    }
    func nsRanges(of string: Self, options: String.CompareOptions = [], range: Range<Index>? = nil, locale: Locale? = nil) -> [NSRange] {
        var start = range?.lowerBound ?? startIndex
        let end = range?.upperBound ?? endIndex
        var ranges: [NSRange] = []
        while start < end, let range = self.range(of: string, options: options, range: start..<end, locale: locale ?? .current) {
            ranges.append(.init(range, in: self))
            start = range.upperBound
        }
        return ranges
    }
}

extension Date {
    
    // Convert local time to UTC (or GMT)
    func toUTCTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
    // Convert UTC (or GMT) to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
    func toLocalTimeMethod2() -> Date {
        var lDT = Date().toLocalTime()
        lDT = Calendar.current.date(bySetting: .year, value: self.getMonthDateYear(.year), of: self) ?? Date()
        lDT =  Calendar.current.date(bySetting: .month, value: self.getMonthDateYear(.month), of: self) ?? Date()
        lDT =  Calendar.current.date(bySetting: .day, value: self.getMonthDateYear(.day), of: self) ?? Date()
        lDT =  Calendar.current.date(bySetting: .hour, value: self.getMonthDateYear(.hour), of: self) ?? Date()
        lDT =  Calendar.current.date(bySetting: .minute, value: self.getMonthDateYear(.minute), of: self) ?? Date()
        return lDT
    }
    
    func setTime(hour: Int, min: Int, sec: Int, timeZoneAbbrev: String = "UTC") -> Date? {
        let x: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let cal = Calendar.current
        var components = cal.dateComponents(x, from: self)
        
        components.timeZone = TimeZone(abbreviation: timeZoneAbbrev)
        components.hour = hour
        components.minute = min
        components.second = sec
        
        return cal.date(from: components)
    }
    
    
    func GetDateDiffrence() -> String {
        
        
        let startDate = Date()
        let endDate = self
        var timeAgo = ""
        
        var month = 0
        var weeks = 0
        var days = 0
        //        var hours = 0
        //        var min = 0
        //        var sec = 0
        //
        month =  Calendar.current.dateComponents([.month], from: endDate, to: startDate).month ?? 0
        weeks =  Calendar.current.dateComponents([.weekOfMonth], from: endDate, to: startDate).weekOfMonth ?? 0
        days =  Calendar.current.dateComponents([.day], from: endDate, to: startDate).day ?? 0
        //        hours = Calendar.current.dateComponents([.hour], from: endDate, to: startDate).hour ?? 0
        //        min =  Calendar.current.dateComponents([.minute], from: endDate, to: startDate).minute ?? 0
        //        sec =  Calendar.current.dateComponents([.second], from: endDate, to: startDate).second ?? 0
        
        
        
        
        if days == 0
        {
            timeAgo = "Today"
            if Calendar.current.isDate(Date(), inSameDayAs:self)
            {
                timeAgo = "Today"
            }
            else
            {
                timeAgo = "Yesterday"
            }
        }
        else if (days == 1) {
            timeAgo = "Yesterday"
        } else {
            timeAgo = "\(days) days ago"
        }
        
        
        if(weeks > 0){
            if (weeks > 1) {
                timeAgo = "\(weeks) weeks ago"
            } else {
                timeAgo = "\(weeks) week ago"
            }
        }
        if(month > 0){
            if (month > 1) {
                timeAgo = "\(month) months ago"
            } else {
                timeAgo = "\(month) month ago"
            }
        }
        return timeAgo;
    }
    
}

func fromIntToColor(red:Int,green:Int,blue:Int,alpha:CGFloat) ->UIColor
{
    return UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: alpha)
}


extension UITextField {
    
    func setFontSize (size:Int) {
        self.font =  UIFont(name: self.font!.fontName, size:CGFloat(size))!
    }
    
    
    func setLeftViewIcon(icon: UIImage) {
        //        let btnView = UIButton(frame: CGRect(x: 0, y: 0, width: ((self.frame.height) * 0.50), height: ((self.frame.height) * 0.50)))
        let btnView = UIButton(frame: CGRect(x: 0, y: 0, width: ((self.frame.height) * 1), height: ((self.frame.height) * 1)))
        btnView.setImage(icon, for: .normal)
        btnView.imageEdgeInsets = UIEdgeInsets(top: 13, left: 5, bottom: 5, right: 3)
        btnView.imageView?.contentMode = .scaleAspectFit
        self.leftViewMode = .always
        self.leftView = btnView
    }
    
    func setLeftViewIconWithTopPadding(icon: UIImage,topPadding:Int,heightScale:CGFloat) {
        //        let btnView = UIButton(frame: CGRect(x: 0, y: 0, width: ((self.frame.height) * 0.50), height: ((self.frame.height) * 0.50)))
        let btnView = UIButton(frame: CGRect(x: 0, y: 0, width: ((self.frame.height) * heightScale), height: ((self.frame.height) * heightScale)))
        btnView.setImage(icon, for: .normal)
        btnView.imageEdgeInsets = UIEdgeInsets(top: CGFloat(topPadding), left: CGFloat(topPadding), bottom: CGFloat(topPadding), right: 3)
        btnView.imageView?.contentMode = .scaleAspectFit
        self.leftViewMode = .always
        self.leftView = btnView
    }
    
    
    
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
    
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:[NSAttributedString.Key.foregroundColor: newValue!])
        }
    }
}


extension UIButton {
    func setFontSize (size:Int) {
        self.titleLabel?.font = UIFont(name: self.titleLabel!.font!.fontName, size:CGFloat(size))!
    }
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animation.duration = 0.6
        animation.values = [0.0 , -10.0, 00.0, -10.0, 0.0]
//        layer.add(animation, forKey: "shake")
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
            self.transform = CGAffineTransform(scaleX: 0.9 , y: 0.9)

        }, completion: { _ in
            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })

       }
    
}
extension UILabel {
    func setFontSize (size:Int) {
        self.font =  UIFont(name: self.font!.fontName, size:CGFloat(size))!
    }
    
    func setFontWithSameSize (fontName:String) {
        self.font =  UIFont(name: fontName, size:self.font.pointSize)!
    }
    
    
    func addCharactersSpacing(_ value: CGFloat = 1.5) {
        if let textString = text {
            let attrs: [NSAttributedString.Key : Any] = [.kern: value]
            attributedText = NSAttributedString(string: textString, attributes: attrs)
        }
    }
}


extension StringProtocol where Index == String.Index {
    func nsRange(from range: Range<Index>) -> NSRange {
        return NSRange(range, in: self)
    }
    
    func ranges<T: StringProtocol>(of string: T, options: String.CompareOptions = []) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        var start: Index = startIndex
        
        while let range = range(of: string, options: options, range: start..<endIndex) {
            ranges.append(range)
            start = range.upperBound
        }
        
        return ranges
    }
}

//MARK: -device type
extension UIScreen {
    
    enum SizeType: CGFloat {
        case Unknown = 0.0
        case iPhone4 = 960.0
        case iPhone5_Se = 1136.0
        case iPhone6_6s_7_8 = 1334.0
        case iPhone6_6s_7_8_Plus = 2208.0
        case iPhoneX_XS_11Pro = 2436.0
        case iPhoneXR_11 = 1792.0
        case iPhoneXS_MAX_11ProMax = 2688.0
        case iPhoneXR_12Mini = 2340.0
        case iPhoneXR_12_Pro = 2532.0
        case iPhoneXR_12_Pro_Max = 2778.0
    }
    
    var sizeType: SizeType {
        let height = nativeBounds.height
        guard let sizeType = SizeType(rawValue: height) else { return .Unknown }
        return sizeType
    }
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}

extension Float
{
    func toStingWithTwoDecimal() -> String {
        return String(NSString(format: "%.2f", self))
    }
    func toStingWithOneDecimal() -> String {
        return String(NSString(format: "%.1f", self))
    }
    func toStingWithZeroDecimal() -> String {
        return String(NSString(format: "%.0f", self))
    }
}

extension Double
{
    func toStingWithTwoDecimal() -> String {
        return String(NSString(format: "%.2f", self))
    }
    func toStingWithOneDecimal() -> String {
        return String(NSString(format: "%.1f", self))
    }
    func toStingWithZeroDecimal() -> String {
        return String(NSString(format: "%.0f", self))
    }
}


//MARK:- UIColor
extension UIColor {
    convenience init(hex: String,alpha:CGFloat) {
        let scanner = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: alpha
        )
    }
    
}

func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }
    
    if ((cString.count) != 6) {
        return UIColor.gray
    }
    
    var rgbValue:UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)
    
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}


func randomColor() -> UIColor {
    let red = {CGFloat(arc4random_uniform(255)) / 255.0}
    let green = {CGFloat(arc4random_uniform(255)) / 255.0}
    let blue = {CGFloat(arc4random_uniform(255)) / 255.0}
    return UIColor(red: red(), green: green(), blue: blue(), alpha: 1)
}


//MARK:- toster


//MARK:- Image Loader
extension UIImageView
{
//    func loadImageWithURLWithPlaceHolderImageAndHandler(url:String,placeholderImg:UIImage,completion:@escaping (_ img :UIImage,_ success:Bool) -> Void)
//    {
//        if let imgurl = URL(string: url)
//        {
//            self.sd_setImage(with: imgurl, placeholderImage: placeholderImg, options: [.refreshCached,], context:nil, progress: { (re, done, u) in
//                
//            }) { (img, err, type, u) in
//                
//                completion(img ?? UIImage(),true)
//            }
//        }
//    }
}

extension UIImage {
    
    func imageWithColor(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()
        
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)
        
        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func resize(withWidth newWidth: CGFloat) -> UIImage? {
        
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func scaleUIImageToSize(size: CGSize) -> UIImage {
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
           
    func trim() -> UIImage {
        let newRect = self.cropRect
        if let imageRef = self.cgImage!.cropping(to: newRect) {
            return UIImage(cgImage: imageRef)
        }
        return self
    }
    
    var cropRect: CGRect {
        let cgImage = self.cgImage
        let context = createARGBBitmapContextFromImage(inImage: cgImage!)
        if context == nil {
            return CGRect.zero
        }
        
        let height = CGFloat(cgImage!.height)
        let width = CGFloat(cgImage!.width)
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context?.draw(cgImage!, in: rect)
        
        //let data = UnsafePointer<CUnsignedChar>(CGBitmapContextGetData(context))
        guard let data = context?.data?.assumingMemoryBound(to: UInt8.self) else {
            return CGRect.zero
        }
        
        var lowX = width
        var lowY = height
        var highX: CGFloat = 0
        var highY: CGFloat = 0
        
        let heightInt = Int(height)
        let widthInt = Int(width)
        //Filter through data and look for non-transparent pixels.
        for y in (0 ..< heightInt) {
            let y = CGFloat(y)
            for x in (0 ..< widthInt) {
                let x = CGFloat(x)
                let pixelIndex = (width * y + x) * 4 /* 4 for A, R, G, B */
                
                if data[Int(pixelIndex)] == 0  { continue } // crop transparent
                
                if data[Int(pixelIndex+1)] > 0xE0 && data[Int(pixelIndex+2)] > 0xE0 && data[Int(pixelIndex+3)] > 0xE0 { continue } // crop white
                
                if (x < lowX) {
                    lowX = x
                }
                if (x > highX) {
                    highX = x
                }
                if (y < lowY) {
                    lowY = y
                }
                if (y > highY) {
                    highY = y
                }
                
            }
        }
        
        return CGRect(x: lowX, y: lowY, width: highX - lowX, height: highY - lowY)
    }
    
    func createARGBBitmapContextFromImage(inImage: CGImage) -> CGContext? {
        
        let width = inImage.width
        let height = inImage.height
        
        let bitmapBytesPerRow = width * 4
        let bitmapByteCount = bitmapBytesPerRow * height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitmapData = malloc(bitmapByteCount)
        if bitmapData == nil {
            return nil
        }
        
        let context = CGContext (data: bitmapData,
                                 width: width,
                                 height: height,
                                 bitsPerComponent: 8,      // bits per component
                                 bytesPerRow: bitmapBytesPerRow,
                                 space: colorSpace,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        return context
    }
        
}

func getThumbnailFrom(path: URL) -> UIImage? {
    
    do {
        let asset = AVURLAsset(url: path , options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        let timestamp = asset.duration
        print("Timestemp:   \(timestamp)")
        let cgImage = try imgGenerator.copyCGImage(at: timestamp, actualTime: nil)
        let thumbnail = UIImage(cgImage: cgImage)
        return thumbnail
    } catch let error {
        print("*** Error generating thumbnail: \(error.localizedDescription)")
        return nil
    }
}

extension Data {
    func sizeString(units: ByteCountFormatter.Units = [.useKB], countStyle: ByteCountFormatter.CountStyle = .file) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = units
        bcf.countStyle = .file
        
        
        var str = bcf.string(fromByteCount: Int64(count))
        str = str.replacingOccurrences(of: "KB", with: "")
        str = str.replacingOccurrences(of: " ", with: "")
        str = str.replacingOccurrences(of: ",", with: "")
        
        return str
    }
}

extension UIApplication {
    static func cacheDirectory() -> URL {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("unable to get system cache directory - serious problems")
        }
        
        return cacheURL
    }
    
    static func documentsDirectory() -> URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("unable to get system docs directory - serious problems")
        }
        
        return documentsURL
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    func blink() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.isRemovedOnCompletion = false
        animation.fromValue           = 1
        animation.toValue             = 0.1
        animation.duration            = 0.8
        animation.autoreverses        = true
        animation.repeatCount         = 5000
        animation.beginTime           = CACurrentMediaTime() + 0.5
        self.layer.add(animation, forKey: nil)
    }
}

extension Date
{
    func toDateString(format:String) -> String
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let myString = formatter.string(from: self) // string purpose I add here
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = format//"yyyy-MM-dd"
        return formatter.string(from: yourDate!)
    }
    
    func toDateStringUTC(format:String) -> String
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        let myString = formatter.string(from: self) // string purpose I add here
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = format//"yyyy-MM-dd"
        return formatter.string(from: yourDate!)
    }
    
    func toTimeString(format:String) -> String
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let myString = formatter.string(from: self) // string purpose I add here
        print(myString)
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = format//"yyyy-MM-dd"
        return formatter.string(from: yourDate!)
    }
    
    func getCurrentDateWithFormat(format:String) -> String {
        
        let dateFormatter = DateFormatter()
        // dateFormatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
        dateFormatter.dateFormat = format
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: self)
    }
    
    
    func currentTimeBetweenTime(t1:String,t2:String) -> Bool
    {
        let curDTStr = self.toDateString(format: "HH") + ":" + self.toDateString(format: "mm") + ":" + self.toDateString(format: "ss")
        
        guard let toDate = t1.getDateFromStringWith(format: "HH:mm:ss"),
              let fromDate = t2.getDateFromStringWith(format: "HH:mm:ss"),
              let curDate = curDTStr.getDateFromStringWith(format: "HH:mm:ss") else {return false}
        
        var range:ClosedRange<Date>!
        
        if toDate > fromDate
        {
            range = fromDate...toDate
        }
        else
        {
            range = toDate...fromDate
        }
        
        if range.contains(curDate)
        {
            return true
        }
        else
        {
            return false
        }
        
        //        if now >= eight_today &&
        //          now <= four_thirty_today
        //        {
        //          return true
        //        }
        //        else
        //        {
        //            return false
        //        }
    }
    
    
    func isCurrentBetween(_ date1: Date, and date2: Date) -> Bool {
        return (min(date1, date2) ... max(date1, date2)).contains(self)
    }
    func add(years: Int = 0, months: Int = 0, days: Int = 0, hours: Int = 0, minutes: Int = 0, seconds: Int = 0) -> Date? {
        let components = DateComponents(year: years, month: months, day: days, hour: hours, minute: minutes, second: seconds)
        return Calendar.current.date(byAdding: components, to: self)
    }
    
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the amount of nanoseconds from another date
    func nanoseconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.nanosecond], from: date, to: self).nanosecond ?? 0
    }
    
    func getMonthDateYear(_ component: Calendar.Component) -> Int {
        return Calendar.current.component(component, from: self)
    }
    
    
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        if nanoseconds(from: date) > 0 { return "\(nanoseconds(from: date))ns" }
        return ""
    }
    
    func timeAgoDisplay() -> String
    {
        
        if Calendar.current.isDate(self, inSameDayAs: Date())
        {
            return self.getCurrentDateWithFormat(format: "HH:mm")
        }
        else if Calendar.current.isDateInYesterday(self)
        {
            return "Yesterday"
        }
        else
        {
            for i in 2 ... 6
            {
                if let dt = Date().add(years: 0, months: 0, days: -i, hours: 0, minutes: 0, seconds: 0)
                {
                    if Calendar.current.isDate(dt, inSameDayAs: self)
                    {
                        return self.getCurrentDateWithFormat(format: "EEEE")
                    }
                }
                
            }
            return self.getCurrentDateWithFormat(format: "dd/MM/yyyy")
        }
        
    }
    
    func timeAgoDisplayForTableSectionLikeWhatsApp() -> String
    {
        
        if Calendar.current.isDate(self, inSameDayAs: Date())
        {
            return "Today"
        }
        else if Calendar.current.isDateInYesterday(self)
        {
            return "Yesterday"
        }
        else
        {
            for i in 2 ... 6
            {
                if let dt = Date().add(years: 0, months: 0, days: -i, hours: 0, minutes: 0, seconds: 0)
                {
                    if Calendar.current.isDate(dt, inSameDayAs: self)
                    {
                        return self.getCurrentDateWithFormat(format: "EEEE")
                    }
                }
                
            }
            return self.getCurrentDateWithFormat(format: "dd/MM/yyyy")
        }
        
    }
    
    func getLast6Month() -> Date? {
        return Calendar.current.date(byAdding: .month, value: -6, to: self)
    }
    
    func getLast3Month() -> Date? {
        return Calendar.current.date(byAdding: .month, value: -3, to: self)
    }
    
    func getYesterday() -> Date? {
        return Calendar.current.date(byAdding: .day, value: -1, to: self)
    }
    
    func getLast7Day() -> Date? {
        return Calendar.current.date(byAdding: .day, value: -7, to: self)
    }
    func getLast30Day() -> Date? {
        return Calendar.current.date(byAdding: .day, value: -30, to: self)
    }
    
    func getPreviousMonth() -> Date? {
        return Calendar.current.date(byAdding: .month, value: -1, to: self)
    }
    
    //Current Week
    var startOfWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return gregorian.date(byAdding: .day, value: 0, to: sunday)
    }
    
    var endOfWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return gregorian.date(byAdding: .day, value: 6, to: sunday)
    }
    
    //Next Week
    var startOfNextWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return gregorian.date(byAdding: .day, value: 7, to: sunday)
    }
    
    var endOfNextWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return gregorian.date(byAdding: .day, value: 13, to: sunday)
    }
    
    
    
    
    // This Month Start
    func getThisMonthStart() -> Date? {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components)!
    }
    
    func getThisMonthEnd() -> Date? {
        let components:NSDateComponents = Calendar.current.dateComponents([.year, .month], from: self) as NSDateComponents
        components.month += 1
        components.day = 1
        components.day -= 1
        return Calendar.current.date(from: components as DateComponents)!
    }
    
    
    
    
    
    //next Month Start
    func getNextMonthStart() -> Date? {
        let components:NSDateComponents = Calendar.current.dateComponents([.year, .month], from: self) as NSDateComponents
        components.month += 1
        return Calendar.current.date(from: components as DateComponents)!
    }
    
    //next Month End
    func getNextMonthEnd() -> Date? {
        let components:NSDateComponents = Calendar.current.dateComponents([.year, .month], from: self) as NSDateComponents
        components.month += 2
        components.day = 1
        components.day -= 1
        
        return Calendar.current.date(from: components as DateComponents)!
    }
    
    //Last Month Start
    func getLastMonthStart() -> Date? {
        let components:NSDateComponents = Calendar.current.dateComponents([.year, .month], from: self) as NSDateComponents
        components.month -= 1
        return Calendar.current.date(from: components as DateComponents)!
    }
    
    //Last Month End
    func getLastMonthEnd() -> Date? {
        let components:NSDateComponents = Calendar.current.dateComponents([.year, .month], from: self) as NSDateComponents
        components.day = 1
        components.day -= 1
        return Calendar.current.date(from: components as DateComponents)!
    }
    
    
    
    
}

public extension UITableView {
    
    func registerCellClass(_ cellClass: AnyClass) {
        let identifier = String.className(cellClass)
        self.register(cellClass, forCellReuseIdentifier: identifier)
    }
    
    func registerCellNib(_ cellClass: AnyClass) {
        let identifier = String.className(cellClass)
        let nib = UINib(nibName: identifier, bundle: nil)
        self.register(nib, forCellReuseIdentifier: identifier)
    }
    
    func registerHeaderFooterViewClass(_ viewClass: AnyClass) {
        let identifier = String.className(viewClass)
        self.register(viewClass, forHeaderFooterViewReuseIdentifier: identifier)
    }
    
    func registerHeaderFooterViewNib(_ viewClass: AnyClass) {
        let identifier = String.className(viewClass)
        let nib = UINib(nibName: identifier, bundle: nil)
        self.register(nib, forHeaderFooterViewReuseIdentifier: identifier)
    }
}

public extension UICollectionView {
    
    func registerCellClass(_ cellClass: AnyClass) {
        let identifier = String.className(cellClass)
        self.register(cellClass, forCellWithReuseIdentifier: identifier)
    }
    
    func registerCellNib(_ cellClass: AnyClass) {
        let identifier = String.className(cellClass)
        let nib = UINib(nibName: identifier, bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: identifier)
    }
    
    func registerHeaderFooterViewClass(_ viewClass: AnyClass) {
        let identifier = String.className(viewClass)
        self.register(viewClass, forCellWithReuseIdentifier: identifier)
    }
    
    func registerHeaderFooterViewNib(_ viewClass: AnyClass) {
        let identifier = String.className(viewClass)
        let nib = UINib(nibName: identifier, bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: identifier)
    }
}

extension Notification.Name
{
    static let HideBottomTabbar = Notification.Name(rawValue: "HideBottomTabbar")
    static let ShowBottomTabbar = Notification.Name(rawValue: "ShowBottomTabbar")
    static let TabBAR0 = Notification.Name(rawValue: "TabBAR0")
    static let onPushReceive = Notification.Name(rawValue: "onPushReceive")
    static let scrollToTopProfile = Notification.Name(rawValue: "scrollToTopProfile")
    static let scrollToTopHome = Notification.Name(rawValue: "scrollToTopHome")
    static let WHITEBottomTabbar = Notification.Name(rawValue: "WHITEBottomTabbar")
    static let WHITETEXTBottomTabbar = Notification.Name(rawValue: "WHITETEXTBottomTabbar")
    static let BLACKTEXTBottomTabbar = Notification.Name(rawValue: "BLACKTEXTBottomTabbar")
    static let CLEARBottomTabbar = Notification.Name(rawValue: "CLEARBottomTabbar")
    static let WHITETEXTTopNAVbar = Notification.Name(rawValue: "WHITETEXTTopNAVbar")
    static let BLACKTEXTTopNAVbar = Notification.Name(rawValue: "BLACKTEXTTopNAVbar")
    static let HideTopNavbar = Notification.Name(rawValue: "HideTopNavbar")
    static let ShowTopnavbar = Notification.Name(rawValue: "ShowTopnavbar")
    static let SCANTABbar = Notification.Name(rawValue: "SCANTABbar")
    static let SHOPTABbar = Notification.Name(rawValue: "SHOPTABbar")
    static let PaymentDone = Notification.Name(rawValue: "PaymentDone")
}

func randomNumberLarge() -> Int {
    return Int.random(in: 0...100000000000000)
}

extension String {
    
    //MARK:- Convert UTC To Local Date by passing date formats value
    func UTCToLocal(incomingFormat: String, outGoingFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = incomingFormat
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let dt = dateFormatter.date(from: self)
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = outGoingFormat
        
        return dateFormatter.string(from: dt ?? Date())
    }
    
    func localToUTC(incomingFormat: String, outGoingFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = incomingFormat
        dateFormatter.calendar = NSCalendar.current
        dateFormatter.timeZone = TimeZone.current
        
        let dt = dateFormatter.date(from: self)
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = outGoingFormat
        
        return dateFormatter.string(from: dt ?? Date())
    }
}

extension UIViewController {
    
    func pop(numberOfTimes: Int) {
        guard let navigationController = navigationController else {
            return
        }
        let viewControllers = navigationController.viewControllers
        let index = numberOfTimes + 1
        if viewControllers.count >= index {
            navigationController.popToViewController(viewControllers[viewControllers.count - index], animated: true)
        }
    }
}


extension UIViewController {
    
    func findSpecificVC(className:AnyClass) -> Bool {
        guard let navigationController = navigationController else {
            return false
        }
        let viewControllers = navigationController.viewControllers
        
        for viewController in viewControllers {
            // some process
            if viewController.isKind(of: className) {
                return true
            }
        }
        return false
    }
}

extension UIApplication {
    
    var screenshot: UIImage? {
        UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        for window in windows {
            window.layer.render(in: context)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIView {
    
    func takeScreenshot() -> UIImage {
        
        // Begin context
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        
        // Draw view in that context
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        
        // And finally, get image
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if (image != nil)
        {
            return image!
        }
        return UIImage()
    }
}


extension NSDictionary
{
    func toJsonString() -> String
    {
        let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [])
        if let jsonString = String(data: jsonData!, encoding: .utf8)
        {
            return jsonString
        }
        return ""
    }
}

func paramToJSON(param:[String:Any]) -> String
{
    if let theJSONData = try?  JSONSerialization.data(withJSONObject: param,options: .prettyPrinted),let theJSONText = String(data: theJSONData,encoding: String.Encoding.ascii) {
        return theJSONText
    }
    return ""
}

extension Collection where Iterator.Element == [String:AnyObject] {
    func toJSONString(options: JSONSerialization.WritingOptions = .prettyPrinted) -> String {
        if let arr = self as? [[String:AnyObject]],
           let dat = try? JSONSerialization.data(withJSONObject: arr, options: options),
           let str = String(data: dat, encoding: String.Encoding.utf8) {
            return str
        }
        return "[]"
    }
}



func arrayToCommaSepatedString(arr:[Any]) -> String
{
    var str = ""
    for st in arr
    {
        str = str + "\(st)" + ","
    }
    
    if str != ""
    {
        str.removeLast()
    }
    return str
}



extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return result
    }
}


extension Dictionary where Value: Equatable {
    func containsValue(value : Value) -> Bool {
        return self.contains { $0.1 == value }
    }
}


//MARK:- conversion

extension Int {
    func toString() -> String {
        return "\(self)"
    }
    func toCGFloat() -> CGFloat {
        return CGFloat(self)
    }
    var ordinal: String? {
        
        let ordinalFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .ordinal
            return formatter
        }()
        return ordinalFormatter.string(from: NSNumber(value: self))
    }
    
    
    func secondToTimeMinString() -> String
    {
        let hr = self / 3600
        let min = (self % 3600) / 60
        let sec = (self % 3600) % 60
        
        if hr > 0 {
            return "\(String(format: "%02d", hr)):\(String(format: "%02d", min)):\(String(format: "%02d", sec)) hour"
        }
        else
        {
            return "\(String(format: "%02d", min)):\(String(format: "%02d", sec)) min"
        }
    }
    
    func secondToTimeMin() -> String
    {
        let hr = self / 3600
        let min = (self % 3600) / 60
        let sec = (self % 3600) % 60
        
        if hr > 0 {
            return "\(String(format: "%02d", hr)):\(String(format: "%02d", min)):\(String(format: "%02d", sec))"
        }
        else
        {
            return "\(String(format: "%02d", min)):\(String(format: "%02d", sec))"
        }
    }
    
}

extension CGFloat {
    func toString() -> String {
        return "\(self)"
    }
}
extension String {
    
    func toInt() -> Int {
        if let val = Int(self) {
            return val
        } else {
            return 0
        }
    }
    
    func toDouble() -> Double {
        if let val = Double(self) {
            return val
        } else {
            return 0
        }
    }
    
    func toCGFloat() -> CGFloat {
        guard let doubleValue = Double(self) else {
            return 0
        }
        return CGFloat(doubleValue)
    }
    
}
func toAnyString(val:Any) -> String {
    return "\(val)"
}

func toAnyDouble(val:Any) -> Double {
    
    if let val = Double("\(val)") {
        return val
    } else {
        return 0
    }
}

func toAnyFloat(val:Any) -> Float {
    
    if let val = Float("\(val)") {
        return val
    } else {
        return 0
    }
}


func toAnyInt(val:Any) -> Int {
    
    if let val = Int("\(val)") {
        return val
    } else {
        return 0
    }
}



extension String {
    
    // formatting text for currency textField
    func currencyInputFormatting() -> String {
        
        var number: NSNumber!
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        
        var amountWithPrefix = self
        
        // remove from String: "$", ".", ","
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count), withTemplate: "")
        
        let double = (amountWithPrefix as NSString).doubleValue
        number = NSNumber(value: double)
        
        // if first number is 0 or all numbers were deleted
        guard number != 0 as NSNumber else {
            return ""
        }
        
        return formatter.string(from: number)!
    }
}
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}


extension UILabel {
    
    func setLineSpacing(lineSpacing: CGFloat = 0.0, lineHeightMultiple: CGFloat = 0.0) {
        
        guard let labelText = self.text else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        
        let attributedString:NSMutableAttributedString
        if let labelattributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelattributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }
        
        // (Swift 4.2 and above) Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        
        
        // (Swift 4.1 and 4.0) Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        
        self.attributedText = attributedString
    }
    
    
    func makeOutLine(oulineColor: UIColor, foregroundColor: UIColor)
    {
        let strokeTextAttributes = [
            NSAttributedString.Key.strokeColor : oulineColor,
            NSAttributedString.Key.foregroundColor : foregroundColor,
            NSAttributedString.Key.strokeWidth : -4.0,
            NSAttributedString.Key.font : self.font ?? UIFont.systemFont(ofSize: 14)
        ] as [NSAttributedString.Key : Any]
        self.attributedText = NSMutableAttributedString(string: self.text ?? "", attributes: strokeTextAttributes)
    }
    
    func underline() {
        if let textString = self.text {
            let attributedString = NSMutableAttributedString(string: textString)
            attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: attributedString.length))
            attributedText = attributedString
        }
    }
}


//MARK:- Loader




extension UIStoryboard {
    static let Main: UIStoryboard = {
        return UIStoryboard.init(name: "Main", bundle: nil)
    }()
}

func fontList()
{
    for family in UIFont.familyNames {
        
        let sName: String = family as String
        print("family: \(sName)")
        
        for name in UIFont.fontNames(forFamilyName: sName) {
            print("name: \(name as String)")
        }
    }
}


extension UIFont {
    var bold: UIFont { return withWeight(.bold) }
    var semibold: UIFont { return withWeight(.semibold) }
    var regular: UIFont { return withWeight(.regular) }
    
    private func withWeight(_ weight: UIFont.Weight) -> UIFont {
        var attributes = fontDescriptor.fontAttributes
        var traits = (attributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
        
        traits[.weight] = weight
        
        attributes[.name] = nil
        attributes[.traits] = traits
        attributes[.family] = familyName
        
        let descriptor = UIFontDescriptor(fontAttributes: attributes)
        
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

extension UICollectionView {
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
  
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel;
    }
    
    func restore() {
        self.backgroundView = nil
    }
}

extension String {
    var digits: String { return filter { $0.isWholeNumber } }
    var decimal: Decimal { return Decimal(string: digits) ?? 0 }
}
extension Decimal {
    var number: NSDecimalNumber { return NSDecimalNumber(decimal: self) }
}

extension LosslessStringConvertible {
    var string: String { return .init(self) }
}

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}



func getAddressByAppleFromLatLong(loc:CLLocationCoordinate2D,handler: @escaping (String) -> Void)
{
    var address: String = ""
    let geoCoder = CLGeocoder()
    let location = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
    //selectedLat and selectedLon are double values set by the app in a previous process
    
    geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
        
        // Place details
        var placeMark: CLPlacemark?
        placeMark = placemarks?[0]
        
        
        
        // Location name
        if let locationName = placeMark?.name {
            address += locationName + ", "
        }
        
        // Street address
        if let street = placeMark?.thoroughfare {
            address += street + ", "
        }
        
        // City
        if let city = placeMark?.locality {
            address += city + ", "
        }
        
        // City
        if let city = placeMark?.administrativeArea {
            address += city + ", "
        }
        
        //        // Zip code
        //        if let zip = placeMark?.addressDictionary?["ZIP"] as? String {
        //            address += zip + ", "
        //        }
        
        // Country
        if let country = placeMark?.country {
            address += country
        }
        // Passing address back
        handler(address)
    })
}

extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.usesSignificantDigits = false
        formatter.numberStyle = .decimal
        return formatter
    }()
}
extension Int{
    var formattedWithCommaSeparator: String {
        return Formatter.withSeparator.string(for: self) ?? ""
    }
}

func string (_ dict:NSDictionary, _ key:String) -> String {
    if let title = dict.value(forKeyPath: key) {
        return "\(title)"
    } else {
        return ""
    }
}

func number (_ dict:NSDictionary, _ key:String) -> NSNumber {
    if let title = dict.value(forKeyPath: key) as? NSNumber {
        return title
    } else if let title = dict.value(forKeyPath: key) as? String {
        
        if let title1 = Int(title) as Int? {
            return NSNumber(value: title1)
        } else if let title1 = Float(title) as Float? {
            return NSNumber(value: title1)
        } else if let title1 = Double(title) as Double? {
            return NSNumber(value: title1)
        } else if let title1 = Bool(title) as Bool? {
            return NSNumber(value: title1)
        }
        
        return 0
    } else {
        return 0
    }
}

extension String {
    
    func width(withFont font: UIFont) -> CGFloat {
        return ceil(self.size(withAttributes: [.font: font]).width)
    }
    
}

extension UIViewController {
    
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unregisterFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification){
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let newHeight = view.convert(keyboardFrame.cgRectValue, from: nil).size.height - view.layoutMargins.bottom
        keyboardVisibleHeightWillChange(newHeight: newHeight)
    }
    
    @objc private func keyboardWillHide(notification: NSNotification){
        keyboardVisibleHeightWillChange(newHeight: 0)
    }
    
    @objc func keyboardVisibleHeightWillChange(newHeight: CGFloat) {}
}

public extension UIDevice {
    //https://gist.github.com/adamawolf/3048717
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()
}



class ZeroPaddingButton: UIButton {
    override var intrinsicContentSize: CGSize {
        return titleLabel?.intrinsicContentSize ?? super.intrinsicContentSize
    }
}
