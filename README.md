# GTFetchableImage

![Language](https://img.shields.io/badge/Language-Swift-orange)
![License](https://img.shields.io/badge/License-MIT-brightgreen)
![Version](https://img.shields.io/badge/Version-1.0.2-blue)

#### Fetch, cache and handle remote and local images fast and reliably in Swift based applications.

## What is GTFetchableImage?

GTFetchableImage is a **Swift protocol** that makes it super easy to **fetch and cache remote images** consistently, as well as to *deal with local images only* with no effort at all.

Main features are:

* It allows both single and batch image fetching.
* No need for custom file names when caching locally; remote URL is all that needed.
* Fast image loading when they are already cached.  
* Fetching progress when getting multiple images.
* Capability to set options in order to specify whether fetched images are allowed to be stored locally, the target directory of the app (documents or caches) and custom names for the local files.
* Deleting locally cached files at once.
* Save new images locally straight from an app.

GTFetchableImage is a plug-and-play protocol; just adopt it, and start using it right away!

## Public API

The following methods are available to any custom type that adopts the GTFetchableImage protocol:

```swift
fetchImage(from:options:completion:)
// Fetch an image from a remote URL or from a local file if it's already cached.

fetchBatchImages(using:options:partialFetchHandler:completion:)
// Fetch multiple images based on the provided collection of remote URLs.

localFileURL(for:options:)
// Get the URL to local files when images are cached locally. 

deleteImage(using:options:)
// Delete a cached image using the original remote URL.

deleteBatchImages(using:options:)
// Delete multiple cached images using their original remote URLs.

deleteBatchImages(using:)
// Delete multiple images files based on custom file names.

save(image data:options:)
// Save provided image data locally.
```

Use Quick Help in Xcode to get details and information about each method.

## Integrating GTFetchableImage

To integrate `GTFetchableImage` into your projects follow the next steps:

1. Copy the repository's URL to GitHub.
2. Open your project in Xcode.
3. Go to menu **File > Swift Packages > Add Package Dependency...**.
4. Paste the URL, select the package when it appears and click Next.
5. In the *Rules* leave the default option selected (*Up to Next Major*) and click Next.
6. Select the *GTFetchableImage* package and select the *Target* to add to; click Finish.
7. In Xcode, select your project in the Project navigator and go to *General* tab.
8. Add GTFetchableImage framework under *Frameworks, Libraries, and Embedded Content* section.

Don't forget to import it anywhere you need to use it:

```swift
import GTFetchableImage
```

Finally, adopt it:

```swift
class ViewController: UIViewController, GTFetchableImage {
    ...
}
```

## Remarks

* Most of the provided methods work asynchronously in the background. Use the main thread to update the UI when necessary.
* Find my [detailed tutorial](https://gtiapps.com/?p=5295) on how to implement GTFetchableImage from scratch.  

## Version

Current up-to-date version is 1.0.2.

## License

GTFetchableImage is licensed under the MIT license.

