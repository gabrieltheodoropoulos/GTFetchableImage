import Foundation

/**
 A custom type with properties that describe options which
 can be provided when fetching remote or loading local images.
 */
public struct GTFetchableImageOptions {
    /// Indicates whether images should be stored (and read from) the Caches directory.
    /// Default value is `true`.
    var storeInCachesDirectory: Bool = true
    
    /// When `true` then caching locally a remote images is allowed, otherwise it's not.
    /// Default value is `true`.
    var allowLocalStorage: Bool = true
    
    /// Provide custom name only to images stored by the app using the `save(image:options:)`
    /// locally and no remote URL exists. Otherwise the image's remote URL is used when caching
    /// images locally as well.
    var customFileName: String?
}


/**
 A custom type that implements certain assistive functionalities
 used by the default implementation of the `GTFetchableImage` methods.
 */
struct GTFetchableImageHelper {
    /// The URL to documents directory of the app.
    static var documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    /// The URL to caches directory of the app.
    static var cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    
    
    /**
     The purpose of this method is to return a `GTFetchableImageOptions` object.
     
     If the provided `options` argument is not `nil` then it's unwrapped and returned. Otherwise,
     a new instance of the `GTFetchableImageOptions` is created and returned instead.
     */
    static func getOptions(_ options: GTFetchableImageOptions?) -> GTFetchableImageOptions {
        return options != nil ? options! : GTFetchableImageOptions()
    }
    
    
    /**
     It creates and returns a tweaked Base64 encoded string of the original
     remote URL of the image. It's used as the file name when image is stored locally.
     */
    static func getImageName(from urlString: String) -> String? {
        guard var base64String = urlString.data(using: .utf8)?.base64EncodedString() else { return nil }
        base64String = base64String.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        
        guard base64String.count < 50 else {
            return String(base64String.dropFirst(base64String.count - 50))
        }
        
        return base64String
    }
    
    /**
     It performs the actual image download based on the given URL.
     
     - Parameter url: The remote URL to download the image from.
     - Parameter completion: The completion handler that gets called upon finish fetching.
     - Parameter imageData: Either the actual image data as a `Data` object, or `nil` if fetching
     the image failed.
     */
    static func downloadImage(from url: URL, completion: @escaping (_ imageData: Data?) -> Void) {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: sessionConfiguration)
        let task = session.dataTask(with: url) { (data, response, error) in
            completion(data)
        }
        task.resume()
    }
    
    
    /**
     It loads a previously cached image using the original remote URL.
     
     - Parameter url: The image's remote URL as a `String` value.
     - Returns: A `Data` object if loading the cached image succeeds, or `nil`
     if it fails.
     */
    static func loadLocalImage(from url: URL) -> Data? {
        do {
            let imageData = try Data(contentsOf: url)
            return imageData
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

