import Photos
import FBSDKShareKit



public class ShareUtil{

    private var facebookDialog: ShareDialog?

    public let SUCCESS: String = "SUCCESS"
    public let ERROR_APP_NOT_AVAILABLE: String = "ERROR_APP_NOT_AVAILABLE"
    public let ERROR_FEATURE_NOT_AVAILABLE_FOR_THIS_VERSON: String = "ERROR_FEATURE_NOT_AVAILABLE_FOR_THIS_VERSON"
    public let ERROR: String = "ERROR"
    public let NOT_IMPLEMENTED: String = "NOT_IMPLEMENTED"

    let argAttributionURL: String  = "attributionURL";
    let argImagePaths: String  = "imagePaths";
    let argImagePath: String  = "imagePath";
    let argbackgroundImage: String  = "backgroundImage";
    let argMessage: String  = "message";
    let argTitle: String  = "title";
    let argstickerImage: String  = "stickerImage";
    let argAppId: String  = "appId";
    let argBackgroundTopColor: String  = "backgroundTopColor";
    let argBackgroundBottomColor: String  = "backgroundBottomColor";
    let argImages: String  = "images";
    let argVideoFile: String  = "videoFile";


    
    public func getInstalledApps(result: @escaping FlutterResult){
        let apps = [["instagram","instagram"],["facebook-stories","facebook_stories"],["fbauth2","facebook"],["whatsapp","whatsapp"],["tg","telegram"],["fb-messenger","messenger"],["tiktok","snssdk1233"],["instagram-stories","instagram_stories"],["twitter","twitter"],["sms","message"]]
        var output:[String: Bool] = [:]
        for app in apps {
            if(UIApplication.shared.canOpenURL(URL(string:(app[0])+"://")!)){
                output[app[1]] = true
            }else{
                output[app[1]] = false
            }
        }
        result(output)
    }

    public func canOpenUrl(appName:String) -> Bool{
         return UIApplication.shared.canOpenURL(URL(string:appName+"://")!)
    }



    public func shareToInstagramFeed(args : [String: Any?],result: @escaping FlutterResult) {
        guard let filePath = args[argImagePath] as? String else {
            result(ERROR)
            return
        }
        guard FileManager.default.fileExists(atPath: filePath) else {
            result(ERROR)
            return
        }
        guard canOpenUrl(appName: "instagram") else {
            result(ERROR_APP_NOT_AVAILABLE)
            return
        }

        saveToPhotoLibraryAndOpenInstagram(
            filePath: filePath,
            isImage: isImage(filePath: filePath),
            result: result
        )
    }

    func isImage(filePath:String)->Bool{
        UIImage(contentsOfFile: filePath) != nil
    }


    private func saveToPhotoLibraryAndOpenInstagram(
        filePath: String,
        isImage: Bool,
        result: @escaping FlutterResult
    ) {
        getLibraryPermissionIfNecessary { granted in
            guard granted else {
                self.complete(result, with: self.ERROR)
                return
            }

            let fileURL = URL(fileURLWithPath: filePath)
            var localIdentifier: String?
            PHPhotoLibrary.shared().performChanges({
                let request: PHAssetChangeRequest?
                if isImage {
                    request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
                } else {
                    request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                }
                localIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
            }, completionHandler: { success, error in
                guard success, error == nil, let localIdentifier = localIdentifier else {
                    self.complete(result, with: self.ERROR)
                    return
                }
                self.openInstagramFeed(localIdentifier: localIdentifier, result: result)
            })
        }
    }

    private func openInstagramFeed(
        localIdentifier: String,
        result: @escaping FlutterResult
    ) {
        var components = URLComponents()
        components.scheme = "instagram"
        components.host = "library"
        components.queryItems = [
            URLQueryItem(name: "LocalIdentifier", value: localIdentifier)
        ]
        guard let url = components.url else {
            complete(result, with: ERROR)
            return
        }

        DispatchQueue.main.async {
            guard UIApplication.shared.canOpenURL(url) else {
                result(self.ERROR_APP_NOT_AVAILABLE)
                return
            }
            UIApplication.shared.open(url, options: [:]) { opened in
                result(opened ? self.SUCCESS : self.ERROR)
            }
        }
    }

    private func complete(_ result: @escaping FlutterResult, with value: String) {
        DispatchQueue.main.async {
            result(value)
        }
    }

    func getLibraryPermissionIfNecessary(completionHandler: @escaping  (Bool) -> Void) {
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if status == .authorized || status == .limited {
                completionHandler(true)
                return
            }
            guard status == .notDetermined else {
                completionHandler(false)
                return
            }
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                completionHandler(newStatus == .authorized || newStatus == .limited)
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .authorized {
                completionHandler(true)
                return
            }
            guard status == .notDetermined else {
                completionHandler(false)
                return
            }
            PHPhotoLibrary.requestAuthorization { newStatus in
                completionHandler(newStatus == .authorized)
            }
        }
    }


    public func shareToSystem(args : [String: Any?],result: @escaping FlutterResult) {
        presentSystemShare(
            message: args[argMessage] as? String,
            filePaths: args[argImagePaths] as? [String] ?? [],
            result: result
        )
    }

    private func presentSystemShare(
        message: String?,
        filePaths: [String],
        result: @escaping FlutterResult
    ) {
        var data: [Any] = []
        if let message = message, !message.isEmpty {
            data.append(message)
        }
        for filePath in filePaths where FileManager.default.fileExists(atPath: filePath) {
            data.append(URL(fileURLWithPath: filePath))
        }
        guard !data.isEmpty, let presenter = UIApplication.topViewController() else {
            result(ERROR)
            return
        }

        let activityViewController = UIActivityViewController(
            activityItems: data,
            applicationActivities: nil
        )
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        presenter.present(activityViewController, animated: true) {
            result(self.SUCCESS)
        }
    }
    
    
    func copyToClipboard(args : [String: Any?],result: @escaping FlutterResult){
        let message = args[self.argMessage] as? String
        UIPasteboard.general.string = message!
        result(SUCCESS)
    }
    
    
    
    func shareToWhatsApp(args : [String: Any?],result: @escaping FlutterResult)  {
        let message = args[self.argMessage] as? String
        let whatsURL = "whatsapp://send?text="+message!
        
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.insert(charactersIn: "?&")
        let whatsAppURL  = NSURL(string: whatsURL.addingPercentEncoding(withAllowedCharacters: characterSet)!)
        if UIApplication.shared.canOpenURL(whatsAppURL! as URL)
        {
            UIApplication.shared.open(whatsAppURL! as URL)
            result(SUCCESS);
        }
        else
        {
            result(ERROR_APP_NOT_AVAILABLE);
        }
    }
    
    
    
    @discardableResult
    func shareToFacebookPost(
        args: [String: Any?],
        result: @escaping FlutterResult,
        delegate: SharingDelegate
    ) -> Bool {
        let imagePaths = args[self.argImagePaths] as? [String] ?? []
        let photos = imagePaths.compactMap { path -> SharePhoto? in
            guard let image = UIImage(contentsOfFile: path) else { return nil }
            return SharePhoto(image: image, isUserGenerated: true)
        }
        guard !photos.isEmpty, let presenter = UIApplication.topViewController() else {
            result(ERROR)
            return false
        }

        if let message = args[self.argMessage] as? String, !message.isEmpty {
            UIPasteboard.general.string = message
        }

        let content = SharePhotoContent()
        content.photos = photos
        let dialog = ShareDialog(
            viewController: presenter,
            content: content,
            delegate: delegate
        )
        facebookDialog = dialog
        dialog.mode = .native
        guard dialog.canShow else {
            facebookDialog = nil
            result(ERROR_APP_NOT_AVAILABLE)
            return false
        }
        do {
            try dialog.validate()
        } catch {
            facebookDialog = nil
            result(ERROR)
            return false
        }
        guard dialog.show() else {
            facebookDialog = nil
            result(ERROR)
            return false
        }
        return true
    }

    func releaseFacebookDialog() {
        facebookDialog = nil
    }
    
    
    func shareToTelegram(args : [String: Any?],result: @escaping FlutterResult) {
        let message = args[self.argMessage] as? String
        
        guard let telegramURL = URL(string: "https://telegram.me") else {
            result(ERROR_APP_NOT_AVAILABLE)
            return
        }
        
        guard let mess = message else {
            result(ERROR)
            return
        }
        
        if (UIApplication.shared.canOpenURL(telegramURL)) {
            let urlString = "tg://msg?text=\(mess)"
            let tgUrl = URL.init(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
            
            if UIApplication.shared.canOpenURL(tgUrl!) {
                UIApplication.shared.open(tgUrl!)
                result(SUCCESS)
            } else {
                result(ERROR_APP_NOT_AVAILABLE)
            }
        } else {
            result(ERROR_APP_NOT_AVAILABLE)
        }
    }
    


    public func shareToInstagramDirect(args : [String: Any?],result: @escaping FlutterResult){
        if #available(iOS 10, *){
            let message = args[self.argMessage] as? String
            let urlString = "instagram://sharesheet?text=\(message!)"
            if(!canOpenUrl(appName: "instagram")){
                result(ERROR_APP_NOT_AVAILABLE)
                return
            }
            if let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                result(SUCCESS)
            }else{
                result(ERROR)
            }
        }else{
            result(ERROR_FEATURE_NOT_AVAILABLE_FOR_THIS_VERSON)
        }
    }
    
    
    
    
    public func shareToMessenger(args : [String: Any?],result: @escaping FlutterResult){
        if #available(iOS 10, *){
            let message = args[self.argMessage] as? String
            let urlString = "fb-messenger://share/?link=\(message!)"
            if(!canOpenUrl(appName: "fb-messenger")){
                result(ERROR_APP_NOT_AVAILABLE)
                return
            }
            if let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                result(SUCCESS)
            }else{
                result(ERROR)
            }
        }else{
            result(ERROR_FEATURE_NOT_AVAILABLE_FOR_THIS_VERSON)
        }
    }
    
    public func shareToSms(args : [String: Any?],result: @escaping FlutterResult){
        let message = args[self.argMessage] as? String
        if #available(iOS 10, *){
            let urlString = "sms:?&body=\(message!)"
            if(!canOpenUrl(appName: "sms")){
                result(ERROR_APP_NOT_AVAILABLE)
                return
            }
            let tgUrl = URL.init(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
            UIApplication.shared.open(tgUrl!, options: [:], completionHandler: nil)
        }
        result(SUCCESS)
    }
    
    public func shareToFacebookStory(args : [String: Any?],result: @escaping FlutterResult) {
        let appId = args[self.argAppId] as? String
        let imagePath = args[self.argbackgroundImage] as? String
        let argVideoFile = args[self.argVideoFile] as? String
        let imagePathSticker = args[self.argstickerImage] as? String
        let backgroundTopColor = args[self.argBackgroundTopColor] as? String
        let backgroundBottomColor =  args[self.argBackgroundBottomColor] as? String
        let attributionURL =  args[self.argAttributionURL] as? String

    
        guard let facebookURL = URL(string: "facebook-stories://share") else {
            result(ERROR_APP_NOT_AVAILABLE)
            return
        }
        
        
        if (UIApplication.shared.canOpenURL(facebookURL)) {
            var pasteboardItems = [
                "com.facebook.sharedSticker.attributionURL": [attributionURL ?? ""],
                "com.facebook.sharedSticker.backgroundTopColor": backgroundTopColor ?? "",
                "com.facebook.sharedSticker.backgroundBottomColor": backgroundBottomColor ?? "",
                "com.facebook.sharedSticker.appID": appId as Any,
            ]
            var backgroundImage: UIImage?;
            if(!(imagePath==nil)){
                backgroundImage =  UIImage.init(contentsOfFile: imagePath!)
                if (backgroundImage != nil) {
                     pasteboardItems["com.facebook.sharedSticker.backgroundImage"] = backgroundImage
                 }
            }
            var stickerImage: UIImage?;
            if(!(imagePathSticker==nil)){
                stickerImage =  UIImage.init(contentsOfFile: imagePathSticker!)
                if (stickerImage != nil) {
                    pasteboardItems["com.facebook.sharedSticker.stickerImage"] = stickerImage
                }
            }
            var backgroundVideoData:Any?;
            if(!(argVideoFile==nil)){
                let backgroundVideoUrl = URL(fileURLWithPath: argVideoFile!)
                backgroundVideoData = try? Data(contentsOf: backgroundVideoUrl)
                if (backgroundVideoData != nil) {
                    pasteboardItems["com.facebook.sharedSticker.backgroundVideo"] = backgroundVideoData
                }
            }


                if #available(iOS 10, *){
                    let pasteboardOptions = [
                        UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60 * 5)
                    ]
                    UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
                    UIApplication.shared.open(facebookURL, options: [:])
                }
                result(self.SUCCESS)
                return
        } else {
            result(ERROR_APP_NOT_AVAILABLE)
        }
    }
    
    
    func shareToTwitter(args : [String: Any?],result: @escaping FlutterResult) {
        guard canOpenUrl(appName: "twitter") else {
            result(ERROR_APP_NOT_AVAILABLE)
            return
        }
        var components = URLComponents()
        components.scheme = "twitter"
        components.host = "post"
        components.queryItems = [
            URLQueryItem(name: "message", value: args[self.argMessage] as? String ?? "")
        ]
        guard let url = components.url else {
            result(ERROR)
            return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
            result(opened ? self.SUCCESS : self.ERROR)
        }
    }

    
    func shareToInstagramStory(args : [String: Any?],result: @escaping FlutterResult) {
        if #available(iOS 10.0, *){
            let appId = args[self.argAppId] as? String
            let imagePath = args[self.argbackgroundImage] as? String
            let argVideoFile = args[self.argVideoFile] as? String
            let imagePathSticker = args[self.argstickerImage] as? String
            let backgroundTopColor = args[self.argBackgroundTopColor] as? String
            let backgroundBottomColor =  args[self.argBackgroundBottomColor] as? String
            let attributionURL =  args[self.argAttributionURL] as? String

            guard let instagramURL = URL(string: "instagram-stories://share?source_application=\(appId!)") else {
                result(ERROR_APP_NOT_AVAILABLE)
                return
            }
            
     
            //if (UIApplication.shared.canOpenURL(instagramURL)) {
                var backgroundImage: UIImage?;
                if(!(imagePath==nil)){
                    backgroundImage =  UIImage.init(contentsOfFile: imagePath!)
                }
                var stickerImage: UIImage?;
                if(!(imagePathSticker==nil)){
                    stickerImage =  UIImage.init(contentsOfFile: imagePathSticker!)
                }
                var backgroundVideoData:Any?;
                if(!(argVideoFile==nil)){
                    let backgroundVideoUrl = URL(fileURLWithPath: argVideoFile!)
                    backgroundVideoData = try? Data(contentsOf: backgroundVideoUrl)
                }
                let pasteboardItems = [
                    [
                        "com.instagram.sharedSticker.attributionURL": attributionURL ?? "",
                        "com.instagram.sharedSticker.stickerImage": stickerImage ?? "",
                        "com.instagram.sharedSticker.backgroundVideo": backgroundVideoData ?? "",
                        "com.instagram.sharedSticker.backgroundImage": backgroundImage ?? "",
                        "com.instagram.sharedSticker.backgroundTopColor": backgroundTopColor ?? "",
                        "com.instagram.sharedSticker.backgroundBottomColor": backgroundBottomColor ?? "",
                    ]
                ]
                let pasteboardOptions = [
                    UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60 * 5)
                ]
                UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)
                UIApplication.shared.open(instagramURL, options: [:])
                result(self.SUCCESS)
            //} else {
              //  result(ERROR_APP_NOT_AVAILABLE)
           // }
        }else{
            result(ERROR_FEATURE_NOT_AVAILABLE_FOR_THIS_VERSON)
        }
        
    }
    
    
    public func shareImageToWhatsApp(args : [String: Any?],result: @escaping FlutterResult) {
      let imagePath = args[self.argImagePath] as? String

      guard let url = URL(string: imagePath!) else {
        result(FlutterError(code: "INVALID_PATH", message: "The image path is invalid", details: nil))
        return
      }
      
      guard let image = UIImage(contentsOfFile: url.path) else {
        result(FlutterError(code: "IMAGE_ERROR", message: "Could not load image", details: nil))
        return
      }
    
    
        let urlWhats = "whatsapp://app"
        if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters:CharacterSet.urlQueryAllowed) {
            if let whatsappURL = URL(string: urlString) {

                if UIApplication.shared.canOpenURL(whatsappURL as URL) {

                        if let imageData = image.jpegData(compressionQuality: 1.0) {
                            let tempFile = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents/whatsAppTmp.wai")
                            do {
                                try imageData.write(to: tempFile, options: .atomic)
                                let documentInteractionController = UIDocumentInteractionController(url: tempFile)
                                documentInteractionController.uti = "net.whatsapp.image"
                                documentInteractionController.presentOpenInMenu(from: CGRect.zero, in: UIApplication.topViewController()!.view, animated: true)

                            } catch {
                                print(error)
                            }
                        }
                    

                } else {
                   print("Cannot open whatsapp")
                }
            }
        }
    }
    
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let rootController: UIViewController?
        if let controller = controller {
            rootController = controller
        } else if #available(iOS 13.0, *) {
            rootController = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .filter { $0.activationState == .foregroundActive }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController
        } else {
            rootController = UIApplication.shared.delegate?.window??.rootViewController
        }

        if let navigationController = rootController as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = rootController as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = rootController?.presentedViewController {
            return topViewController(controller: presented)
        }
        return rootController
    }
}

class TransparentViewController: UIViewController {
    override func viewDidLoad() {
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
    }
}
