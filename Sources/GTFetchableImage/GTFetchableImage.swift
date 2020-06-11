import Foundation

public protocol GTFetchableImage {
    func localFileURL(for imageURL: String?, options: GTFetchableImageOptions?) -> URL?
    func fetchImage(from urlString: String?, options: GTFetchableImageOptions?, completion: @escaping (_ imageData: Data?) -> Void)
    func fetchBatchImages(using urlStrings: [String?],
                          options: GTFetchableImageOptions?,
                          partialFetchHandler: @escaping (_ imageData: Data?, _ index: Int) -> Void,
                          completion: @escaping () -> Void)
    func deleteImage(using imageURL: String?, options: GTFetchableImageOptions?) -> Bool
    func deleteBatchImages(using imageURLs: [String?], options: GTFetchableImageOptions?)
    func deleteBatchImages(using multipleOptions: [GTFetchableImageOptions])
    func save(image data: Data, options: GTFetchableImageOptions) -> Bool
}



extension GTFetchableImage {
    /**
     It returns the URL to an image cached locally.
     
     - Parameter imageURL: The original remote URL of the image as a `String` value.
     - Parameter options: An optional `GTFetchableImageOptions` object to pass along any options,
     such as specifying the target saving directory (documents or caches), whether fetched images
     are allowed to be cached locally, and more. See `GTFetchableImageOptions` for more information.
     Default value is `nil`.
     - Returns: Either a `URL` object to the locally cached image, or `nil` if it cannot be specified.
     */
    public func localFileURL(for imageURL: String?, options: GTFetchableImageOptions? = nil) -> URL? {
        let opt = GTFetchableImageHelper.getOptions(options)
        
        let targetDir = opt.storeInCachesDirectory ?
            GTFetchableImageHelper.cachesDirectoryURL :
            GTFetchableImageHelper.documentsDirectoryURL
        
        guard let urlString = imageURL else {
            guard let customFileName = opt.customFileName else { return nil }
            return targetDir.appendingPathComponent(customFileName)
        }
        
        guard let imageName = GTFetchableImageHelper.getImageName(from: urlString) else { return nil }
        return targetDir.appendingPathComponent(imageName)
    }
    
    
    /**
     Fetch an image from the given URL or from a local file if it's already cached.
     
     The image will not be downloaded again if it has already been downloaded and cached locally.
     In that case, it's loaded from the local file. It's fetched from the remote source if only
     it's not found locally.
     
     - Parameter urlString: The original remote URL of the image as a `String` value.
     - Parameter options: An optional `GTFetchableImageOptions` object to pass along any options.
     See `GTFetchableImageOptions` for more information. Default value is `nil`.
     - Parameter completion: The completion handler that gets called when fetching the image is finished.
     - Parameter imageData: Either the actual image data as a `Data` object, or `nil` if fetching
     the image failed.
     
     - Note: This method runs on a background thread, so make sure to update UI on the main thread
     once image fetching is finished.
     */
    public func fetchImage(from urlString: String?, options: GTFetchableImageOptions? = nil, completion: @escaping (_ imageData: Data?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let opt = GTFetchableImageHelper.getOptions(options)
            let localURL = self.localFileURL(for: urlString, options: options)

            // Determine if image exists locally first.
            if opt.allowLocalStorage,
                let localURL = localURL,
                FileManager.default.fileExists(atPath: localURL.path) {

                // Image exists locally!
                // Load it using the composed localURL.
                let loadedImageData = GTFetchableImageHelper.loadLocalImage(from: localURL)
                completion(loadedImageData)

            } else {
                // Image does not exist locally!
                // Download it.

                guard let urlString = urlString, let url = URL(string: urlString) else {
                    completion(nil)
                    return
                }

                GTFetchableImageHelper.downloadImage(from: url) { (imageData) in
                    if opt.allowLocalStorage, let localURL = localURL {
                        try? imageData?.write(to: localURL)
                    }

                    completion(imageData)
                }

            }
        }
    }
    
    
    
    /**
     It fetches multiple images based on the provided collection of remote URLs.
     
     If images are already cached, then they're loaded from the local files. If they don't
     exist locally, then they're fetched from the remote source.
     
     - Parameter urlStrings: The remote image URLs as an array of `String` values.
     - Parameter options: An optional `GTFetchableImageOptions` object to pass along any options.
     See `GTFetchableImageOptions` for more information. Default value is `nil`.
     - Parameter partialFetchHandler: A callback handler that gets called every time an image is fetched.
     Use it to report download progress if necessary and to deal with the fetched image.
     - Parameter imageData: Either the actual image data as a `Data` object, or `nil` if fetching
     the image failed.
     - Parameter index: The index of the URL in the `urlStrings` array matching to the downloaded image.
     - Parameter completion: The callback handler that gets called when fetching process is complete.
     
     - Note: This method runs asynchronously on a background thread. Use the main thread to update
     the UI if necessary.
     */
    public func fetchBatchImages(using urlStrings: [String?],
                          options: GTFetchableImageOptions? = nil,
                          partialFetchHandler: @escaping (_ imageData: Data?, _ index: Int) -> Void,
                          completion: @escaping () -> Void) {
        
        performBatchImageFetching(using: urlStrings, currentImageIndex: 0, options: options, partialFetchHandler: { (imageData, index) in
            partialFetchHandler(imageData, index)
        }) {
            completion()
        }
        
    }
    
    
    /**
     A private method assistive to `fetchBatchImages(using:options:partialFetchHandler:completion:)` method.
     
     The purpose of its existence is to be called recursively and fetch images one
     after another. The actual image fetching takes place using the `fetchImage(from:options:completion:)`
     method.
     */
    private func performBatchImageFetching(using urlStrings: [String?],
                                           currentImageIndex: Int,
                                           options: GTFetchableImageOptions?,
                                           partialFetchHandler: @escaping (_ imageData: Data?, _ index: Int) -> Void,
                                           completion: @escaping () -> Void) {

        guard currentImageIndex < urlStrings.count else {
            completion()
            return
        }
        
        
        fetchImage(from: urlStrings[currentImageIndex], options: options) { (imageData) in
            partialFetchHandler(imageData, currentImageIndex)
            
            self.performBatchImageFetching(using: urlStrings, currentImageIndex: currentImageIndex + 1, options: options, partialFetchHandler: partialFetchHandler) {
                
                completion()
            }
        }
    }
    
    
    /**
     It deletes a previously cached image using the original remote URL.
     
     - Parameter imageURL: The original remote URL of the image as a `String` value.
     - Parameter options: An optional `GTFetchableImageOptions` object to pass along any options.
     See `GTFetchableImageOptions` for more information. Default value is `nil`.
     - Returns: `true` on successful deletion, `false` in case deleting the local file
     fails or it does not exist.
     */
    public func deleteImage(using imageURL: String?, options: GTFetchableImageOptions? = nil) -> Bool {
        guard let localURL = localFileURL(for: imageURL, options: options),
            FileManager.default.fileExists(atPath: localURL.path) else { return false }
        
        do {
            try FileManager.default.removeItem(at: localURL)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    
    /**
     It deletes multiple cached images.
     
     - Parameter imageURLs: The remote image URLs of the images as an array of optional `String` values.
     - Parameter options: An optional `GTFetchableImageOptions` object to pass along any options.
     See `GTFetchableImageOptions` for more information. Default value is `nil`.
     
     - Note: This method runs asynchronously on a background thread. Use the main thread to update
     the UI if necessary.
     */
    public func deleteBatchImages(using imageURLs: [String?], options: GTFetchableImageOptions? = nil) {
        DispatchQueue.global().async {
            imageURLs.forEach { _ = self.deleteImage(using: $0, options: options) }
        }
    }
    
    
    /**
     Delete multiple images files based on custom file names.
     
     Use this method if only custom file names were used originally for storing images.
     
     - Parameter multipleOptions: An array of `GTFetchableImageOptions` objects. Each
     object must contain the custom file name of each image that should be deleted
     in the `customFileName` property.
     
     - Note: This method runs asynchronously on a background thread. Use the main thread to update
     the UI if necessary.
     */
    public func deleteBatchImages(using multipleOptions: [GTFetchableImageOptions]) {
        DispatchQueue.global().async {
            multipleOptions.forEach { _ = self.deleteImage(using: nil, options: $0) }
        }
    }
    
    
    /**
     Save provided image data locally.
     
     - Parameter data: The image data as a `Data` object.
     - Parameter options: A `GTFetchableImageOptions` object that must mandatorily contain
     the image name in the `customFileName` property.
     - Returns: `true` if writing the image data locally succeeds, `false` otherwise.
     */
    public func save(image data: Data, options: GTFetchableImageOptions) -> Bool {
        guard let url = localFileURL(for: nil, options: options) else { return false }
        do {
            try data.write(to: url)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

