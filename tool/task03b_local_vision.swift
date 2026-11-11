import Foundation
import Vision
import AppKit
let root=URL(fileURLWithPath:CommandLine.arguments[1],isDirectory:true)
let out=root.appendingPathComponent("ocr",isDirectory:true)
try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
for file in try FileManager.default.contentsOfDirectory(at:root.appendingPathComponent("assets"),includingPropertiesForKeys:nil).filter({$0.pathExtension=="png"}).sorted(by:{$0.path<$1.path}) {
 let dest=out.appendingPathComponent(file.deletingPathExtension().lastPathComponent+".json")
 if FileManager.default.fileExists(atPath:dest.path){continue}
 let req=VNRecognizeTextRequest();req.recognitionLevel = .accurate;req.recognitionLanguages=["ko-KR","en-US"];req.usesLanguageCorrection=false
 try VNImageRequestHandler(url:file,options:[:]).perform([req])
 let rows=(req.results ?? []).map { o -> [String:Any] in let b=o.boundingBox;return ["text":o.topCandidates(1).first?.string ?? "","x":b.minX,"y":b.minY,"w":b.width,"h":b.height] }
 try JSONSerialization.data(withJSONObject:rows,options:[.prettyPrinted,.sortedKeys]).write(to:dest)
 print(file.lastPathComponent)
}
