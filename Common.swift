import Foundation
import UIKit
import os.log
extension FileManager {
    class func documentsDir() -> String {
        var paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as [String]
        return paths[0]
    }
    class func cachesDir() -> String {
        var paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true) as [String]
        return paths[0]
    }
}
extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}
extension UInt32 {
    public static func random(lower: UInt32 = min, upper: UInt32 = max) -> UInt32 {
        return arc4random_uniform(upper - lower) + lower
    }
}
public extension Int32 {
    public static func random(lower: Int32 = min, upper: Int32 = max) -> Int32 {
        let r = arc4random_uniform(UInt32(Int64(upper) - Int64(lower)))
        return Int32(Int64(r) + Int64(lower))
    }
}
func getSizeString(byteCount: Int64) -> String {
    let userDefaults = UserDefaults.standard
    let unit: String = userDefaults.string(forKey: UserDefaultStruct.unit)!
    if byteCount == 0 {
        if unit == "all" {
            return "0 bytes"
        }
        return "0 " + unit
    }
    let byteCountFormatter = ByteCountFormatter()
    if unit == "bytes" {
        byteCountFormatter.allowedUnits = .useBytes
    } else if unit == "KB" {
        byteCountFormatter.allowedUnits = .useKB
    } else if unit == "MB" {
        byteCountFormatter.allowedUnits = .useMB
    } else if unit == "GB" {
        byteCountFormatter.allowedUnits = .useGB
    } else {
        byteCountFormatter.allowedUnits = .useAll
    }
    byteCountFormatter.countStyle = .file
    return byteCountFormatter.string(fromByteCount: byteCount)
}
func checkAppAvailability(registeredUrl: URL) -> Bool {
    var checkResult: Bool?
    checkResult = UIApplication.shared.canOpenURL(registeredUrl)
    if checkResult != nil {
        if checkResult == true {
            return true
        }
    }
    return false
}
func openAppStore(id: Int) {
    if let url = URL(string: "itms-apps://itunes.apple.com/de/app/files/id" + String(id)),
        UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
}
func removeDir(path: String) {
    let dirUrl: URL = URL(fileURLWithPath: path, isDirectory: true)
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(at: dirUrl)
        os_log("Removed dir '%@'", log: logGeneral, type: .info, dirUrl.path)
    } catch let error {
        os_log("%@", log: logGeneral, type: .error, error.localizedDescription)
    }
}
func clearDir(path: String) {
    let fileManager = FileManager.default
    do {
        let items = try fileManager.contentsOfDirectory(atPath: path)
        for item in items {
            try fileManager.removeItem(atPath: path + "/" + item)
            os_log("Removed item '%@'", log: logGeneral, type: .info, item)
        }
    } catch let error {
        os_log("%@", log: logGeneral, type: .error, error.localizedDescription)
    }
}
func makeDirs(path: String) {
    let fileManager = FileManager.default
    do {
        try fileManager.createDirectory(atPath: path,
                                        withIntermediateDirectories: true,
                                        attributes: nil)
        os_log("Created dir '%@'", log: logGeneral, type: .debug, path)
    } catch let error {
        os_log("%@", log: logGeneral, type: .error, error.localizedDescription)
    }
}
func removeFileIfExist(path: String) {
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: path) {
        do {
            try fileManager.removeItem(atPath: path)
            os_log("Removed file '%@'", log: logGeneral, type: .debug, path)
        } catch {
            os_log("%@", log: logGeneral, type: .error, error.localizedDescription)
        }
    }
}
func trashFileIfExist(path: String) {
    let fileManager = FileManager.default
    let srcUrl: URL = URL(fileURLWithPath: path, isDirectory: false)
    let destDirUrl: URL = URL(fileURLWithPath: AppState.documentsPath + "/.Trash/", isDirectory: true)
    let destUrl = destDirUrl.appendingPathComponent(srcUrl.lastPathComponent)
    if fileManager.fileExists(atPath: srcUrl.path) {
        do {
            makeDirs(path: destDirUrl.path)
            removeFileIfExist(path: destUrl.path)
            try fileManager.copyItem(at: srcUrl, to: destUrl)
            os_log("Copied file to '%@'", log: logGeneral, type: .debug, destUrl.path)
            try fileManager.removeItem(at: srcUrl)
            os_log("Removed file '%@'", log: logGeneral, type: .debug, srcUrl.path)
        } catch {
            os_log("%@", log: logGeneral, type: .error, error.localizedDescription)
        }
    }
}
func putPlaceholderFile(path: String) {
    let fileName = ".placeholder.txt"
    var fileContent = "This (hidden) file is just a placeholder, so that iOS is forced to always display the 'Local "
    fileContent += "Storage' directory in Files. Otherwise it would be hidden as soon as there is nothing left in it. "
    fileContent += "Which makes for a bad user experience. And leads to people leaving unnecessary negative reviews."
    let fileURL = URL(fileURLWithPath: path).appendingPathComponent(fileName)
    let fileManager = FileManager.default
    do {
        let items = try fileManager.contentsOfDirectory(atPath: path)
        if ( items.contains(".Trash") && items.count == 1 ) || items.count == 0 {
            os_log("Number of (real) items 0. Creating placeholder file.", log: logGeneral, type: .error)
            try fileContent.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        if ( items.contains(".Trash") && items.count > 2 ) || ( !items.contains(".Trash") && items.count > 1 ) {
            os_log("Number of (real) items > 0. Removing placeholder file.", log: logGeneral, type: .error)
            removeFileIfExist(path: fileURL.path)
        }
    } catch let error {
        os_log("%@", log: logGeneral, type: .error, error.localizedDescription)
    }
}
func resetStats() {
    os_log("resetStats", log: logGeneral, type: .debug)
    AppState.localFilesNumber = 0
    AppState.localFoldersNumber = 0
    AppState.localSizeBytes = 0
    AppState.localSizeDiskBytes = 0
    AppState.trashFilesNumber = 0
    AppState.trashFoldersNumber = 0
    AppState.trashSizeBytes = 0
    AppState.trashSizeDiskBytes = 0
    AppState.types = [TypeInfo(name: LocalizedTypeNames.audio, color: UIColor(named: "ColorTypeAudio")!, size: 0, number: 0, paths: [], sizes: []),
                      TypeInfo(name: LocalizedTypeNames.videos, color: UIColor(named: "ColorTypeVideos")!, size: 0, number: 0, paths: [], sizes: []),
                      TypeInfo(name: LocalizedTypeNames.documents, color: UIColor(named: "ColorTypeDocuments")!, size: 0, number: 0, paths: [], sizes: []),
                      TypeInfo(name: LocalizedTypeNames.images, color: UIColor(named: "ColorTypeImages")!, size: 0, number: 0, paths: [], sizes: []),
                      TypeInfo(name: LocalizedTypeNames.code, color: UIColor(named: "ColorTypeCode")!, size: 0, number: 0, paths: [], sizes: []),
                      TypeInfo(name: LocalizedTypeNames.archives, color: UIColor(named: "ColorTypeArchives")!, size: 0, number: 0, paths: [], sizes: []),
                      TypeInfo(name: LocalizedTypeNames.other, color: UIColor(named: "ColorTypeOther")!, size: 0, number: 0, paths: [], sizes: [])]
    AppState.files.allValues = []
    AppState.files.fileInfos = []
}
func addToType(name: String, size: Int64, path: String) {
    for (n, type_info) in AppState.types.enumerated() {
        if type_info.name == name {
            let documentsPathEndIndex = path.index(AppState.documentsPath.endIndex, offsetBy: 1)
            let filePath = String(path[documentsPathEndIndex...])
            AppState.types[n].size += size
            AppState.types[n].number += 1
            AppState.types[n].paths.append(filePath)
            AppState.types[n].sizes.append(size)
            AppState.files.allValues.append(Double(size))
            AppState.files.fileInfos.append(FileInfo(name: filePath, type: type_info.name))
            break
        }
    }
}
func fakeStats() {
    let basePath: String = AppState.documentsPath + "/"
    let subfolderOne: String = "Sonya Yoncheva - The Verdi Album (2018) [16-48] (FLAC)/"
    let subfolderTwo: String = "Adaptive Layout"
    addToType(name: LocalizedTypeNames.audio, size: 1200000, path: basePath + "my_favorite_song.mp3")
    addToType(name: LocalizedTypeNames.audio, size: 23000000, path: basePath + "Auld Lang Syne.flac")
    addToType(name: LocalizedTypeNames.audio, size: 31000000, path: basePath + subfolderOne + "01 - Verdi - Il trovatore - Tacea la notte placida ... Di tale amor che dirsi.flac")
    addToType(name: LocalizedTypeNames.audio, size: 27000000, path: basePath + subfolderOne + "09 - Verdi - Nabucco - Anch'io dischiuso un giorno ... Salgo gia del trono aurato.flac")
    addToType(name: LocalizedTypeNames.videos, size: 8000000, path: basePath + "music video (lowres).m4v")
    addToType(name: LocalizedTypeNames.videos, size: 54000000, path: basePath + "Movie Trailer 2018.mkv")
    addToType(name: LocalizedTypeNames.videos, size: 500000000, path: basePath + "oldschool.avi")
    addToType(name: LocalizedTypeNames.videos, size: 40000, path: basePath + "oldschool.srt")
    addToType(name: LocalizedTypeNames.documents, size: 120000000, path: basePath + "manual.pdf")
    addToType(name: LocalizedTypeNames.documents, size: 800000, path: basePath + "The Bible.mobi")
    addToType(name: LocalizedTypeNames.documents, size: 16000000, path: basePath + subfolderOne + "digital_booklet.pdf")
    addToType(name: LocalizedTypeNames.images, size: 800000, path: basePath + subfolderOne + "folder.jpg")
    addToType(name: LocalizedTypeNames.images, size: 24000000, path: basePath + "DCIM234235.JPG")
    addToType(name: LocalizedTypeNames.images, size: 24000000, path: basePath + "DCIM234236.JPG")
    addToType(name: LocalizedTypeNames.images, size: 24000000, path: basePath + "DCIM234237.JPG")
    addToType(name: LocalizedTypeNames.images, size: 24000000, path: basePath + "DCIM234238.JPG")
    addToType(name: LocalizedTypeNames.images, size: 24000000, path: basePath + "DCIM234239.JPG")
    addToType(name: LocalizedTypeNames.code, size: 80000, path: basePath + subfolderOne + "index.html")
    addToType(name: LocalizedTypeNames.code, size: 35000000, path: basePath + subfolderOne + "data.xml")
    addToType(name: LocalizedTypeNames.archives, size: 1200000, path: basePath + subfolderTwo + "AdaptiveLayout-01-Materials.zip")
    addToType(name: LocalizedTypeNames.archives, size: 20000000, path: basePath + subfolderTwo + "AdaptiveLayout-02-Materials.zip")
    addToType(name: LocalizedTypeNames.archives, size: 18000000, path: basePath + subfolderTwo + "AdaptiveLayout-03-Materials.zip")
    addToType(name: LocalizedTypeNames.archives, size: 14000000, path: basePath + subfolderTwo + "AdaptiveLayout-04-Materials.zip")
    addToType(name: LocalizedTypeNames.archives, size: 23000000, path: basePath + subfolderTwo + "AdaptiveLayout-05-Materials.zip")
    addToType(name: LocalizedTypeNames.archives, size: 17000000, path: basePath + subfolderTwo + "AdaptiveLayout-06-Materials.zip")
    addToType(name: LocalizedTypeNames.archives, size: 9000000, path: basePath + subfolderTwo + "AdaptiveLayout-07-Materials.zip")
    addToType(name: LocalizedTypeNames.other, size: 100000000, path: basePath + subfolderTwo + "some_unrecognoized.file")
    AppState.localFilesNumber = 27
    AppState.localFoldersNumber = 2
    AppState.localSizeBytes = 1137000000
    AppState.localSizeDiskBytes = 1150000000
    AppState.trashFilesNumber = 4
    AppState.trashSizeBytes = 500000
    AppState.trashSizeDiskBytes = 555000
    AppState.updateInProgress = false
    NotificationCenter.default.post(name: .updateFinished, object: nil, userInfo: nil)
}
func getStats() {
    os_log("getStats", log: logGeneral, type: .debug)
    let userDefaults = UserDefaults.standard
    let sendUpdateItemNotification: Bool = userDefaults.bool(forKey: UserDefaultStruct.animateUpdateDuringRefresh)
    AppState.updateInProgress = true
    resetStats()
    NotificationCenter.default.post(name: .updatePending, object: nil, userInfo: nil)
    if AppState.demoContent {
        fakeStats()
        return
    }
    DispatchQueue.global(qos: .userInitiated).async {
        let fileManager = FileManager.default
        guard let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: AppState.documentsPath) else {
            os_log("Directory not found '%@'", log: logGeneral, type: .error, AppState.documentsPath)
            return
        }
        while let element = enumerator.nextObject() as? String {
            var elementURL: URL = URL(fileURLWithPath: AppState.documentsPath)
            elementURL.appendPathComponent(element)
            var elementIsTrashed: Bool
            if element.starts(with: ".Trash") {
                elementIsTrashed = true
            } else {
                elementIsTrashed = false
            }
            if element == ".placeholder.txt" {
                continue
            }
            var fileSize : Int64
            do {
                let attr = try fileManager.attributesOfItem(atPath: elementURL.path)
                fileSize = attr[FileAttributeKey.size] as! Int64
            } catch {
                fileSize = 0
                os_log("%@", log: logGeneral, type: .error, error.localizedDescription)
            }
            if let fileType: String = elementURL.typeIdentifier {
                if UtiLookup.audio.contains(fileType) {
                    addToType(name: LocalizedTypeNames.audio, size: fileSize, path: elementURL.path)
                } else if UtiLookup.videos.contains(fileType) {
                    addToType(name: LocalizedTypeNames.videos, size: fileSize, path: elementURL.path)
                } else if UtiLookup.documents.contains(fileType) {
                    addToType(name: LocalizedTypeNames.documents, size: fileSize, path: elementURL.path)
                } else if UtiLookup.images.contains(fileType) {
                    addToType(name: LocalizedTypeNames.images, size: fileSize, path: elementURL.path)
                } else if UtiLookup.code.contains(fileType) {
                    addToType(name: LocalizedTypeNames.code, size: fileSize, path: elementURL.path)
                } else if UtiLookup.archives.contains(fileType) {
                    addToType(name: LocalizedTypeNames.archives, size: fileSize, path: elementURL.path)
                } else if UtiLookup.other.contains(fileType) {
                    addToType(name: LocalizedTypeNames.other, size: fileSize, path: elementURL.path)
                } else {
                    if fileType.starts(with: "dyn.") {
                        let fileExtension = elementURL.pathExtension
                        if FileExtensionLookup.audio.contains(fileExtension) {
                            addToType(name: LocalizedTypeNames.audio, size: fileSize, path: elementURL.path)
                        } else if FileExtensionLookup.videos.contains(fileExtension) {
                            addToType(name: LocalizedTypeNames.videos, size: fileSize, path: elementURL.path)
                        } else if FileExtensionLookup.documents.contains(fileExtension) {
                            addToType(name: LocalizedTypeNames.documents, size: fileSize, path: elementURL.path)
                        } else if FileExtensionLookup.images.contains(fileExtension) {
                            addToType(name: LocalizedTypeNames.images, size: fileSize, path: elementURL.path)
                        } else if FileExtensionLookup.code.contains(fileExtension) {
                            addToType(name: LocalizedTypeNames.code, size: fileSize, path: elementURL.path)
                        } else if FileExtensionLookup.archives.contains(fileExtension) {
                            addToType(name: LocalizedTypeNames.archives, size: fileSize, path: elementURL.path)
                        } else {
                            addToType(name: LocalizedTypeNames.other, size: fileSize, path: elementURL.path)
                        }
                    } else {
                        os_log("Type identifier UTI available %@ but uncategorized for '%@'. Treating as 'Other'",
                               log: logGeneral, type: .info, fileType, elementURL.lastPathComponent)
                        addToType(name: LocalizedTypeNames.other, size: fileSize, path: elementURL.path)
                    }
                }
            } else {
                os_log("Unable to get type identifier for '%@'", log: logGeneral, type: .error, elementURL.path)
            }
            if let values = try? elementURL.resourceValues(forKeys: [.isDirectoryKey]) {
                if values.isDirectory! {
                    if elementIsTrashed {
                        if element != ".Trash" {
                            AppState.trashFoldersNumber += 1
                        }
                        AppState.trashSizeDiskBytes += fileSize
                    } else {
                        AppState.localFoldersNumber += 1
                        AppState.localSizeDiskBytes += fileSize
                    }
                } else {
                    if element != ".placeholder.txt" {
                        if elementIsTrashed {
                            AppState.trashFilesNumber += 1
                            AppState.trashSizeBytes += fileSize
                            AppState.trashSizeDiskBytes += fileSize
                        } else {
                            AppState.localFilesNumber += 1
                            AppState.localSizeBytes += fileSize
                            AppState.localSizeDiskBytes += fileSize
                        }
                    }
                }
            }
            if sendUpdateItemNotification {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .updateItemAdded, object: nil, userInfo: nil)
                }
            }
        }
        DispatchQueue.main.async {
            AppState.updateInProgress = false
            NotificationCenter.default.post(name: .updateFinished, object: nil, userInfo: nil)
        }
    }
}
func getFreeSpace() -> Int64? {
    let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
    guard
        let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectory),
        let freeSize = systemAttributes[.systemFreeSize] as? NSNumber
        else { return nil }
    return freeSize.int64Value
}
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
